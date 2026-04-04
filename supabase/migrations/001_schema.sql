-- ClassTwin Full Schema — Supabase PostgreSQL
-- Run this in the Supabase SQL Editor

-- ═══════════════════════════════════════════════════════════
-- 1. SESSIONS TABLE
-- ═══════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS sessions (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  join_code       TEXT NOT NULL UNIQUE,
  topic           TEXT,
  total_rounds    INT NOT NULL DEFAULT 1,
  current_round   INT NOT NULL DEFAULT 0,
  status          TEXT NOT NULL DEFAULT 'waiting'
                    CHECK (status IN ('waiting', 'active', 'ended')),
  created_by      UUID,                            -- teacher user id
  -- Streaming columns (addendum)
  is_streaming      BOOLEAN NOT NULL DEFAULT FALSE,
  livekit_room_name TEXT,
  stream_started_at TIMESTAMPTZ,
  chat_enabled      BOOLEAN NOT NULL DEFAULT TRUE,
  hand_raise_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ═══════════════════════════════════════════════════════════
-- 2. SESSION STUDENTS TABLE
-- ═══════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS session_students (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id    UUID NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
  student_name  TEXT NOT NULL,
  device_id     TEXT,
  -- Mode column (addendum)
  mode          TEXT NOT NULL DEFAULT 'in_room'
                  CHECK (mode IN ('in_room', 'remote')),
  joined_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ═══════════════════════════════════════════════════════════
-- 3. QUESTIONS TABLE
-- ═══════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS questions (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id    UUID NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
  round_number  INT NOT NULL,
  question_text TEXT NOT NULL,
  options       JSONB,
  correct_option TEXT,
  time_limit_seconds INT NOT NULL DEFAULT 30,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ═══════════════════════════════════════════════════════════
-- 4. STUDENT RESPONSES TABLE
-- ═══════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS student_responses (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  question_id   UUID NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
  student_id    UUID NOT NULL REFERENCES session_students(id) ON DELETE CASCADE,
  session_id    UUID NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
  response      TEXT NOT NULL,
  detail_text   TEXT,
  responded_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (question_id, student_id)
);

-- ═══════════════════════════════════════════════════════════
-- 5. CHAT MESSAGES TABLE (NEW — addendum)
-- ═══════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS chat_messages (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id    UUID NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
  student_id    UUID NOT NULL REFERENCES session_students(id) ON DELETE CASCADE,
  student_name  TEXT NOT NULL,
  message_text  TEXT NOT NULL,
  is_anonymous  BOOLEAN NOT NULL DEFAULT FALSE,
  sent_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ═══════════════════════════════════════════════════════════
-- 6. HAND RAISES TABLE (NEW — addendum)
-- ═══════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS hand_raises (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id    UUID NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
  student_id    UUID NOT NULL REFERENCES session_students(id) ON DELETE CASCADE,
  round_number  INT NOT NULL,
  raised_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  lowered_at    TIMESTAMPTZ,
  UNIQUE (session_id, student_id, round_number)
);

-- ═══════════════════════════════════════════════════════════
-- 7. RLS POLICIES
-- ═══════════════════════════════════════════════════════════
ALTER TABLE sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE session_students ENABLE ROW LEVEL SECURITY;
ALTER TABLE questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_responses ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE hand_raises ENABLE ROW LEVEL SECURITY;

-- Sessions: public read (students need to find by join code)
CREATE POLICY "Anyone can read sessions"
  ON sessions FOR SELECT USING (true);

-- Session students: insert / read
CREATE POLICY "Students can join sessions"
  ON session_students FOR INSERT WITH CHECK (true);

CREATE POLICY "Students can read session members"
  ON session_students FOR SELECT USING (true);

-- Questions: read only
CREATE POLICY "Students can read questions"
  ON questions FOR SELECT USING (true);

-- Responses: insert + read own
CREATE POLICY "Students can submit responses"
  ON student_responses FOR INSERT WITH CHECK (true);

CREATE POLICY "Students can read responses"
  ON student_responses FOR SELECT USING (true);

-- Chat
CREATE POLICY "Students can send chat messages"
  ON chat_messages FOR INSERT WITH CHECK (true);

CREATE POLICY "Students can read session chat"
  ON chat_messages FOR SELECT USING (true);

-- Hand raises
CREATE POLICY "Students can raise hand"
  ON hand_raises FOR INSERT WITH CHECK (true);

CREATE POLICY "Students can lower hand"
  ON hand_raises FOR UPDATE USING (true);

CREATE POLICY "Anyone can read hand raises"
  ON hand_raises FOR SELECT USING (true);

-- ═══════════════════════════════════════════════════════════
-- 8. REALTIME PUBLICATION
-- ═══════════════════════════════════════════════════════════
ALTER PUBLICATION supabase_realtime ADD TABLE sessions;
ALTER PUBLICATION supabase_realtime ADD TABLE session_students;
ALTER PUBLICATION supabase_realtime ADD TABLE questions;
ALTER PUBLICATION supabase_realtime ADD TABLE student_responses;
ALTER PUBLICATION supabase_realtime ADD TABLE chat_messages;
ALTER PUBLICATION supabase_realtime ADD TABLE hand_raises;
