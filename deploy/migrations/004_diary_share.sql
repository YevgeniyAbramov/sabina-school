-- Public diary share links for parents (read-only browser page).
CREATE TABLE IF NOT EXISTS auth.diary_share_link (
    id          BIGSERIAL PRIMARY KEY,
    teacher_id  INTEGER NOT NULL,
    student_id  INTEGER NOT NULL,
    token       TEXT NOT NULL UNIQUE,
    expires_at  TIMESTAMPTZ NOT NULL,
    revoked_at  TIMESTAMPTZ,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_diary_share_student
    ON auth.diary_share_link (student_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_diary_share_token
    ON auth.diary_share_link (token);
