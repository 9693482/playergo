-- ============================================
-- FASE 9: Chat/Mensajería
-- ============================================

-- Conversaciones (uno a uno entre player y team)
CREATE TABLE IF NOT EXISTS public.chats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    player_id UUID NOT NULL REFERENCES public.players(id) ON DELETE CASCADE,
    team_id UUID NOT NULL REFERENCES public.teams(id) ON DELETE CASCADE,
    last_message TEXT,
    last_message_at TIMESTAMPTZ,
    unread_count_player INTEGER DEFAULT 0,
    unread_count_team INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(player_id, team_id)
);

ALTER TABLE public.chats ENABLE ROW LEVEL SECURITY;

CREATE INDEX idx_chats_player ON public.chats(player_id);
CREATE INDEX idx_chats_team ON public.chats(team_id);

-- Mensajes
CREATE TABLE IF NOT EXISTS public.messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chat_id UUID NOT NULL REFERENCES public.chats(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL,
    sender_role TEXT NOT NULL CHECK (sender_role IN ('player', 'team')),
    content TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

CREATE INDEX idx_messages_chat ON public.messages(chat_id);
CREATE INDEX idx_messages_created ON public.messages(created_at DESC);

-- RLS: cada parte ve sus propios chats
CREATE POLICY "players_view_own_chats"
    ON public.chats FOR SELECT
    USING (
        player_id IN (
            SELECT id FROM public.players WHERE profile_id = auth.uid()
        )
    );

CREATE POLICY "teams_view_own_chats"
    ON public.chats FOR SELECT
    USING (
        team_id IN (
            SELECT id FROM public.teams WHERE profile_id = auth.uid()
        )
    );

-- RLS: crear chat (solo equipos pueden iniciar)
CREATE POLICY "teams_create_chat"
    ON public.chats FOR INSERT
    WITH CHECK (
        team_id IN (
            SELECT id FROM public.teams WHERE profile_id = auth.uid()
        )
    );

-- RLS: mensajes - ver si eres parte del chat
CREATE POLICY "users_view_chat_messages"
    ON public.messages FOR SELECT
    USING (
        chat_id IN (
            SELECT id FROM public.chats
            WHERE player_id IN (SELECT id FROM public.players WHERE profile_id = auth.uid())
               OR team_id IN (SELECT id FROM public.teams WHERE profile_id = auth.uid())
        )
    );

-- RLS: enviar mensajes si eres parte del chat
CREATE POLICY "users_send_messages"
    ON public.messages FOR INSERT
    WITH CHECK (
        chat_id IN (
            SELECT id FROM public.chats
            WHERE player_id IN (SELECT id FROM public.players WHERE profile_id = auth.uid())
               OR team_id IN (SELECT id FROM public.teams WHERE profile_id = auth.uid())
        )
    );

-- RLS: marcar como leído
CREATE POLICY "users_update_own_messages"
    ON public.messages FOR UPDATE
    USING (
        chat_id IN (
            SELECT id FROM public.chats
            WHERE player_id IN (SELECT id FROM public.players WHERE profile_id = auth.uid())
               OR team_id IN (SELECT id FROM public.teams WHERE profile_id = auth.uid())
        )
    );

-- Trigger para actualizar last_message y updated_at
CREATE OR REPLACE FUNCTION public.handle_new_message()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.chats
    SET
        last_message = NEW.content,
        last_message_at = NEW.created_at,
        updated_at = NEW.created_at,
        unread_count_player = CASE
            WHEN NEW.sender_role = 'team' THEN unread_count_player + 1
            ELSE unread_count_player
        END,
        unread_count_team = CASE
            WHEN NEW.sender_role = 'player' THEN unread_count_team + 1
            ELSE unread_count_team
        END
    WHERE id = NEW.chat_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_new_message
    AFTER INSERT ON public.messages
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_message();
