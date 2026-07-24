-- Журнал действий преподавателя (уроки, пропуски, оплаты, продления)
CREATE TABLE IF NOT EXISTS auth.student_activity (
    id          BIGSERIAL PRIMARY KEY,
    teacher_id  INTEGER NOT NULL,
    student_id  INTEGER,
    kind        VARCHAR(32) NOT NULL,
    title       TEXT NOT NULL,
    detail      TEXT NOT NULL DEFAULT '',
    amount      INTEGER,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_student_activity_teacher_created
    ON auth.student_activity (teacher_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_student_activity_teacher_kind
    ON auth.student_activity (teacher_id, kind, created_at DESC);
