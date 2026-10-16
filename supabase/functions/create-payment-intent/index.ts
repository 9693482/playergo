import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

interface RequestBody {
  amount?: number;
  currency?: string;
  reservation_id?: string | null;
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  const json = (body: unknown, status = 200) =>
    new Response(JSON.stringify(body), {
      status,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });

  try {
    const stripeSecret = Deno.env.get('STRIPE_SECRET_KEY');
    if (!stripeSecret) {
      return json(
        { error: 'Stripe no está configurado (falta STRIPE_SECRET_KEY)' },
        500,
      );
    }

    const authHeader = req.headers.get('Authorization') ?? '';
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
      { auth: { autoRefreshToken: false, persistSession: false } },
    );

    const {
      data: { user },
      error: userError,
    } = await supabase.auth.getUser(authHeader.replace('Bearer ', ''));

    if (userError || !user) {
      return json({ error: 'No autorizado' }, 401);
    }

    const body: RequestBody = await req.json().catch(() => ({}));
    const currency = (body.currency ?? 'usd').toLowerCase();
    const reservationId = body.reservation_id ?? null;

    let amount = Number(body.amount);

    if (reservationId) {
      const { data: reservation, error: reservationError } = await supabase
        .from('reservations')
        .select('total_price, player_id, team_id, players(user_id), teams(user_id)')
        .eq('id', reservationId)
        .maybeSingle();

      if (reservationError || !reservation) {
        return json({ error: 'Reserva no encontrada' }, 404);
      }

      const ownerIds = [
        (reservation as any).players?.user_id,
        (reservation as any).teams?.user_id,
      ].filter(Boolean);

      if (!ownerIds.includes(user.id)) {
        return json({ error: 'No autorizado sobre esta reserva' }, 403);
      }

      amount = Math.round(Number(reservation.total_price) * 100);
    }

    if (!Number.isInteger(amount) || amount <= 0) {
      return json({ error: 'Monto inválido' }, 400);
    }
    if (amount < 50) {
      return json({ error: 'El monto mínimo es 0.50' }, 400);
    }

    const metadata: Record<string, string> = { user_id: user.id };
    if (reservationId) metadata.reservation_id = reservationId;

    const params = new URLSearchParams();
    params.append('amount', String(amount));
    params.append('currency', currency);
    params.append('automatic_payment_methods[enabled]', 'true');
    for (const [key, value] of Object.entries(metadata)) {
      params.append(`metadata[${key}]`, value);
    }

    const stripeResponse = await fetch('https://api.stripe.com/v1/payment_intents', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${stripeSecret}`,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: params.toString(),
    });

    const intent = await stripeResponse.json();

    if (!stripeResponse.ok) {
      return json(
        { error: intent?.error?.message ?? 'Error al crear el pago en Stripe' },
        502,
      );
    }

    return json({
      id: intent.id,
      client_secret: intent.client_secret,
      amount: intent.amount,
      currency: intent.currency,
      status: intent.status,
    });
  } catch (e) {
    return json({ error: e instanceof Error ? e.message : String(e) }, 500);
  }
});
