-- «Программа» ученика: ноты (файлы) и ссылки (YouTube и т.п.), хранятся раздельно по типу
CREATE TABLE IF NOT EXISTS auth.student_material (
    id          BIGSERIAL PRIMARY KEY,
    teacher_id  INTEGER NOT NULL,
    student_id  INTEGER NOT NULL,
    kind        VARCHAR(16) NOT NULL, -- 'link' | 'file'
    title       TEXT NOT NULL,
    url         TEXT NOT NULL DEFAULT '',
    file_name   TEXT,
    note        TEXT NOT NULL DEFAULT '',
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_student_material_student
    ON auth.student_material (student_id, created_at);

CREATE INDEX IF NOT EXISTS idx_student_material_teacher
    ON auth.student_material (teacher_id);
