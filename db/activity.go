package db

import (
	"context"
	"sckool/models"
)

type ActivityRepository interface {
	EnsureSchema(ctx context.Context) error
	Create(ctx context.Context, a models.Activity) error
	ListByTeacher(ctx context.Context, teacherID int, kind string, limit int) ([]models.Activity, error)
}

type ActivityRepo struct {
	db *Database
}

func NewActivityRepo(db *Database) *ActivityRepo {
	return &ActivityRepo{db: db}
}

func (r *ActivityRepo) EnsureSchema(ctx context.Context) error {
	_, err := r.db.conn.ExecContext(ctx, `
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
	`)
	return err
}

func (r *ActivityRepo) Create(ctx context.Context, a models.Activity) error {
	_, err := r.db.conn.ExecContext(ctx, `
		INSERT INTO auth.student_activity (teacher_id, student_id, kind, title, detail, amount, created_at)
		VALUES ($1, $2, $3, $4, $5, $6, NOW())
	`, a.TeacherID, a.StudentID, a.Kind, a.Title, a.Detail, a.Amount)
	return err
}

func (r *ActivityRepo) ListByTeacher(ctx context.Context, teacherID int, kind string, limit int) ([]models.Activity, error) {
	if limit <= 0 || limit > 200 {
		limit = 80
	}

	var (
		rows []models.Activity
		err  error
	)

	if kind == "" || kind == "all" {
		err = r.db.conn.SelectContext(ctx, &rows, `
			SELECT id, teacher_id, student_id, kind, title, detail, amount, created_at
			FROM auth.student_activity
			WHERE teacher_id = $1
			ORDER BY created_at DESC, id DESC
			LIMIT $2
		`, teacherID, limit)
	} else {
		err = r.db.conn.SelectContext(ctx, &rows, `
			SELECT id, teacher_id, student_id, kind, title, detail, amount, created_at
			FROM auth.student_activity
			WHERE teacher_id = $1 AND kind = $2
			ORDER BY created_at DESC, id DESC
			LIMIT $3
		`, teacherID, kind, limit)
	}

	if err != nil {
		return nil, err
	}
	if rows == nil {
		rows = []models.Activity{}
	}
	return rows, nil
}
