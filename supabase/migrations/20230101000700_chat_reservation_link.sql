-- FASE 27: Chat vinculado a reserva
-- Add reservation_id to chats table

ALTER TABLE chats ADD COLUMN IF NOT EXISTS reservation_id UUID REFERENCES reservations(id) ON DELETE SET NULL;

-- Allow chat only between participants of the same reservation
CREATE OR REPLACE FUNCTION check_chat_reservation()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.reservation_id IS NOT NULL THEN
    IF NOT EXISTS (
      SELECT 1 FROM reservations r
      WHERE r.id = NEW.reservation_id
      AND r.player_id = NEW.player_id
      AND r.team_id = NEW.team_id
    ) THEN
      RAISE EXCEPTION 'Chat must be between reservation participants';
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_chat_reservation_check
  BEFORE INSERT OR UPDATE ON chats
  FOR EACH ROW
  EXECUTE FUNCTION check_chat_reservation();

-- Index for faster lookups
CREATE INDEX IF NOT EXISTS idx_chats_reservation_id ON chats(reservation_id);
