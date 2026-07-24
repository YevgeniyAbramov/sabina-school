package db

import (
	"context"
	"sckool/models"
)

type StudentMaterialRepository interface {
	EnsureSchema(ctx context.Context) error
	ListByStudent(ctx context.Context, studentID, teacherID int) ([]models.StudentMaterial, error)
	Create(ctx context.Context, m models.StudentMaterial) (*models.StudentMaterial, error)
	Update(ctx context.Context, id, studentID, teacherID int, title, note string) (*models.StudentMaterial, error)
	GetByID(ctx context.Context, id, studentID, teacherID int) (*models.StudentMaterial, error)
	Delete(ctx context.Context, id, studentID, teacherID int) error
}

type StudentMaterialRepo struct {
	db *Database
}

func NewStudentMaterialRepo(db *Database) *StudentMaterialRepo {
	return &StudentMaterialRepo{db: db}
}

func (r *StudentMaterialRepo) EnsureSchema(ctx context.Context) error {
	_, err := r.db.conn.ExecContext(ctx, `
		CREATE TABLE IF NOT EXISTS auth.student_material (
			id          BIGSERIAL PRIMARY KEY,
			teacher_id  INTEGER NOT NULL,
			student_id  INTEGER NOT NULL,
			kind        VARCHAR(16) NOT NULL,
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
	`)
	return err
}

const studentMaterialColumns = `id, teacher_id, student_id, kind, title, url, file_name, note, created_at, updated_at`

func (r *StudentMaterialRepo) ListByStudent(ctx context.Context, studentID, teacherID int) ([]models.StudentMaterial, error) {
	var rows []models.StudentMaterial
	err := r.db.conn.SelectContext(ctx, &rows, `
		SELECT `+studentMaterialColumns+`
		FROM auth.student_material
		WHERE student_id = $1 AND teacher_id = $2
		ORDER BY created_at ASC, id ASC
	`, studentID, teacherID)
	if err != nil {
		return nil, err
	}
	if rows == nil {
		rows = []models.StudentMaterial{}
	}
	return rows, nil
}

func (r *StudentMaterialRepo) Create(ctx context.Context, m models.StudentMaterial) (*models.StudentMaterial, error) {
	var result models.StudentMaterial
	err := r.db.conn.QueryRowxContext(ctx, `
		INSERT INTO auth.student_material (teacher_id, student_id, kind, title, url, file_name, note, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, NOW(), NOW())
		RETURNING `+studentMaterialColumns, m.TeacherID, m.StudentID, m.Kind, m.Title, m.URL, m.FileName, m.Note,
	).StructScan(&result)
	return &result, err
}

func (r *StudentMaterialRepo) Update(ctx context.Context, id, studentID, teacherID int, title, note string) (*models.StudentMaterial, error) {
	var result models.StudentMaterial
	err := r.db.conn.QueryRowxContext(ctx, `
		UPDATE auth.student_material
		SET title = $1, note = $2, updated_at = NOW()
		WHERE id = $3 AND student_id = $4 AND teacher_id = $5
		RETURNING `+studentMaterialColumns, title, note, id, studentID, teacherID,
	).StructScan(&result)
	return &result, err
}

func (r *StudentMaterialRepo) GetByID(ctx context.Context, id, studentID, teacherID int) (*models.StudentMaterial, error) {
	var result models.StudentMaterial
	err := r.db.conn.GetContext(ctx, &result, `
		SELECT `+studentMaterialColumns+`
		FROM auth.student_material
		WHERE id = $1 AND student_id = $2 AND teacher_id = $3
	`, id, studentID, teacherID)
	return &result, err
}

func (r *StudentMaterialRepo) Delete(ctx context.Context, id, studentID, teacherID int) error {
	_, err := r.db.conn.ExecContext(ctx, `
		DELETE FROM auth.student_material WHERE id = $1 AND student_id = $2 AND teacher_id = $3
	`, id, studentID, teacherID)
	return err
}
