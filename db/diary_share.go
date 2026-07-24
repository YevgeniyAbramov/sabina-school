package db

import (
	"context"
	"sckool/models"
	"time"
)

type DiaryShareRepository interface {
	EnsureSchema(ctx context.Context) error
	Create(ctx context.Context, link models.DiaryShareLink) (*models.DiaryShareLink, error)
	GetValidByToken(ctx context.Context, token string, now time.Time) (*models.DiaryShareLink, error)
}

type DiaryShareRepo struct {
	db *Database
}

func NewDiaryShareRepo(db *Database) *DiaryShareRepo {
	return &DiaryShareRepo{db: db}
}

func (r *DiaryShareRepo) EnsureSchema(ctx context.Context) error {
	_, err := r.db.conn.ExecContext(ctx, `
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
	`)
	return err
}

const diaryShareColumns = `id, teacher_id, student_id, token, expires_at, revoked_at, created_at`

func (r *DiaryShareRepo) Create(ctx context.Context, link models.DiaryShareLink) (*models.DiaryShareLink, error) {
	var result models.DiaryShareLink
	err := r.db.conn.QueryRowxContext(ctx, `
		INSERT INTO auth.diary_share_link (teacher_id, student_id, token, expires_at, created_at)
		VALUES ($1, $2, $3, $4, NOW())
		RETURNING `+diaryShareColumns, link.TeacherID, link.StudentID, link.Token, link.ExpiresAt,
	).StructScan(&result)
	return &result, err
}

func (r *DiaryShareRepo) GetValidByToken(ctx context.Context, token string, now time.Time) (*models.DiaryShareLink, error) {
	var result models.DiaryShareLink
	err := r.db.conn.GetContext(ctx, &result, `
		SELECT `+diaryShareColumns+`
		FROM auth.diary_share_link
		WHERE token = $1
		  AND revoked_at IS NULL
		  AND expires_at > $2
	`, token, now)
	return &result, err
}
