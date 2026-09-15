-- ============================================
-- FASE 10: Notificaciones Push
-- ============================================

-- Agregar campo FCM token
ALTER TABLE public.notifications ADD COLUMN IF NOT EXISTS fcm_token TEXT;

-- Tabla para almacenar tokens FCM de cada usuario
CREATE TABLE IF NOT EXISTS public.fcm_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    token TEXT NOT NULL,
    platform TEXT NOT NULL DEFAULT 'web',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, token)
);

ALTER TABLE public.fcm_tokens ENABLE ROW LEVEL SECURITY;

CREATE INDEX idx_fcm_tokens_user ON public.fcm_tokens(user_id);
CREATE INDEX idx_fcm_tokens_token ON public.fcm_tokens(token);

-- RLS: ver tokens propios
CREATE POLICY "users_view_own_tokens"
    ON public.fcm_tokens FOR SELECT
    USING (user_id = auth.uid());

-- RLS: insertar tokens propios
CREATE POLICY "users_insert_own_tokens"
    ON public.fcm_tokens FOR INSERT
    WITH CHECK (user_id = auth.uid());

-- RLS: actualizar tokens propios
CREATE POLICY "users_update_own_tokens"
    ON public.fcm_tokens FOR UPDATE
    USING (user_id = auth.uid());

-- RLS: borrar tokens propios
CREATE POLICY "users_delete_own_tokens"
    ON public.fcm_tokens FOR DELETE
    USING (user_id = auth.uid());
