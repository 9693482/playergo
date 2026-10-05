-- ============================================================================
-- fix_chats_rls.sql
-- Crea funciones SECURITY DEFINER para obtener el player_id y team_id
-- del usuario actual, evitando subqueries repetitivas en cada política.
-- Las políticas de chats usan auth.uid() directamente contra las tablas
-- players/teams, pero esto puede fallar si los registros Player/Team
-- no existen aún (usuario no completó onboarding).
-- ============================================================================

-- Función para obtener el player_id del usuario actual
CREATE OR REPLACE FUNCTION public.auth_player_id()
RETURNS UUID
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT id FROM public.players WHERE user_id = auth.uid() LIMIT 1;
$$;

-- Función para obtener el team_id del usuario actual
CREATE OR REPLACE FUNCTION public.auth_team_id()
RETURNS UUID
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT id FROM public.teams WHERE user_id = auth.uid() LIMIT 1;
$$;

-- Reconstruir políticas de chats usando las funciones SECURITY DEFINER
DROP POLICY IF EXISTS "players_view_own_chats" ON public.chats;
CREATE POLICY "players_view_own_chats"
    ON public.chats FOR SELECT
    USING (
        player_id = public.auth_player_id()
    );

DROP POLICY IF EXISTS "teams_view_own_chats" ON public.chats;
CREATE POLICY "teams_view_own_chats"
    ON public.chats FOR SELECT
    USING (
        team_id = public.auth_team_id()
    );

DROP POLICY IF EXISTS "users_create_chat" ON public.chats;
CREATE POLICY "users_create_chat"
    ON public.chats FOR INSERT
    WITH CHECK (
        player_id = public.auth_player_id()
        OR
        team_id = public.auth_team_id()
    );

-- Reconstruir políticas de mensajes
DROP POLICY IF EXISTS "users_view_chat_messages" ON public.messages;
CREATE POLICY "users_view_chat_messages"
    ON public.messages FOR SELECT
    USING (
        chat_id IN (
            SELECT id FROM public.chats
            WHERE player_id = public.auth_player_id()
               OR team_id = public.auth_team_id()
        )
    );

DROP POLICY IF EXISTS "users_send_messages" ON public.messages;
CREATE POLICY "users_send_messages"
    ON public.messages FOR INSERT
    WITH CHECK (
        chat_id IN (
            SELECT id FROM public.chats
            WHERE player_id = public.auth_player_id()
               OR team_id = public.auth_team_id()
        )
    );

DROP POLICY IF EXISTS "users_update_own_messages" ON public.messages;
CREATE POLICY "users_update_own_messages"
    ON public.messages FOR UPDATE
    USING (
        chat_id IN (
            SELECT id FROM public.chats
            WHERE player_id = public.auth_player_id()
               OR team_id = public.auth_team_id()
        )
    );
