-- Repertoire pieces (произведения) for student diary.
CREATE TABLE IF NOT EXISTS auth.student_piece (
    id          BIGSERIAL PRIMARY KEY,
    teacher_id  INTEGER NOT NULL,
    student_id  INTEGER NOT NULL,
    title       TEXT NOT NULL,
    composer    TEXT NOT NULL DEFAULT '',
    readiness   INTEGER NOT NULL DEFAULT 0,
    status      VARCHAR(16) NOT NULL DEFAULT 'learning',
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT student_piece_readiness_chk CHECK (readiness >= 0 AND readiness <= 100)
);

CREATE INDEX IF NOT EXISTS idx_student_piece_student
    ON auth.student_piece (student_id, updated_at DESC);

CREATE INDEX IF NOT EXISTS idx_student_piece_teacher
    ON auth.student_piece (teacher_id);

CREATE TABLE IF NOT EXISTS auth.student_piece_note (
    id          BIGSERIAL PRIMARY KEY,
    piece_id    BIGINT NOT NULL REFERENCES auth.student_piece(id) ON DELETE CASCADE,
    teacher_id  INTEGER NOT NULL,
    student_id  INTEGER NOT NULL,
    body        TEXT NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_student_piece_note_piece
    ON auth.student_piece_note (piece_id, created_at DESC);

ALTER TABLE auth.student_material
    ADD COLUMN IF NOT EXISTS piece_id BIGINT REFERENCES auth.student_piece(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_student_material_piece
    ON auth.student_material (piece_id);
