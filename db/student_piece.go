package db

import (
	"context"
	"sckool/models"
)

type StudentPieceRepository interface {
	EnsureSchema(ctx context.Context) error
	ListByStudent(ctx context.Context, studentID, teacherID int) ([]models.StudentPiece, error)
	GetByID(ctx context.Context, id, studentID, teacherID int) (*models.StudentPiece, error)
	Create(ctx context.Context, p models.StudentPiece) (*models.StudentPiece, error)
	Update(ctx context.Context, id, studentID, teacherID int, title, composer string, readiness int, status models.PieceStatus) (*models.StudentPiece, error)
	Delete(ctx context.Context, id, studentID, teacherID int) error

	ListNotes(ctx context.Context, pieceID, studentID, teacherID int) ([]models.StudentPieceNote, error)
	CreateNote(ctx context.Context, n models.StudentPieceNote) (*models.StudentPieceNote, error)
	DeleteNote(ctx context.Context, noteID, pieceID, studentID, teacherID int) error

	ListMaterialsByPiece(ctx context.Context, pieceID, studentID, teacherID int) ([]models.StudentMaterial, error)
}

type StudentPieceRepo struct {
	db *Database
}

func NewStudentPieceRepo(db *Database) *StudentPieceRepo {
	return &StudentPieceRepo{db: db}
}

func (r *StudentPieceRepo) EnsureSchema(ctx context.Context) error {
	_, err := r.db.conn.ExecContext(ctx, `
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
	`)
	return err
}

const studentPieceColumns = `id, teacher_id, student_id, title, composer, readiness, status, created_at, updated_at`

func (r *StudentPieceRepo) ListByStudent(ctx context.Context, studentID, teacherID int) ([]models.StudentPiece, error) {
	var rows []models.StudentPiece
	err := r.db.conn.SelectContext(ctx, &rows, `
		SELECT p.id, p.teacher_id, p.student_id, p.title, p.composer, p.readiness, p.status,
		       p.created_at, p.updated_at,
		       COALESCE((SELECT COUNT(*) FROM auth.student_piece_note n WHERE n.piece_id = p.id), 0) AS notes_count,
		       COALESCE((SELECT COUNT(*) FROM auth.student_material m WHERE m.piece_id = p.id), 0) AS materials_count
		FROM auth.student_piece p
		WHERE p.student_id = $1 AND p.teacher_id = $2
		ORDER BY p.updated_at DESC, p.id DESC
	`, studentID, teacherID)
	if err != nil {
		return nil, err
	}
	if rows == nil {
		rows = []models.StudentPiece{}
	}
	return rows, nil
}

func (r *StudentPieceRepo) GetByID(ctx context.Context, id, studentID, teacherID int) (*models.StudentPiece, error) {
	var result models.StudentPiece
	err := r.db.conn.GetContext(ctx, &result, `
		SELECT `+studentPieceColumns+`
		FROM auth.student_piece
		WHERE id = $1 AND student_id = $2 AND teacher_id = $3
	`, id, studentID, teacherID)
	return &result, err
}

func (r *StudentPieceRepo) Create(ctx context.Context, p models.StudentPiece) (*models.StudentPiece, error) {
	var result models.StudentPiece
	err := r.db.conn.QueryRowxContext(ctx, `
		INSERT INTO auth.student_piece (teacher_id, student_id, title, composer, readiness, status, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, NOW(), NOW())
		RETURNING `+studentPieceColumns, p.TeacherID, p.StudentID, p.Title, p.Composer, p.Readiness, p.Status,
	).StructScan(&result)
	return &result, err
}

func (r *StudentPieceRepo) Update(ctx context.Context, id, studentID, teacherID int, title, composer string, readiness int, status models.PieceStatus) (*models.StudentPiece, error) {
	var result models.StudentPiece
	err := r.db.conn.QueryRowxContext(ctx, `
		UPDATE auth.student_piece
		SET title = $1, composer = $2, readiness = $3, status = $4, updated_at = NOW()
		WHERE id = $5 AND student_id = $6 AND teacher_id = $7
		RETURNING `+studentPieceColumns, title, composer, readiness, status, id, studentID, teacherID,
	).StructScan(&result)
	return &result, err
}

func (r *StudentPieceRepo) Delete(ctx context.Context, id, studentID, teacherID int) error {
	_, err := r.db.conn.ExecContext(ctx, `
		DELETE FROM auth.student_piece WHERE id = $1 AND student_id = $2 AND teacher_id = $3
	`, id, studentID, teacherID)
	return err
}

const pieceNoteColumns = `id, piece_id, teacher_id, student_id, body, created_at`

func (r *StudentPieceRepo) ListNotes(ctx context.Context, pieceID, studentID, teacherID int) ([]models.StudentPieceNote, error) {
	var rows []models.StudentPieceNote
	err := r.db.conn.SelectContext(ctx, &rows, `
		SELECT `+pieceNoteColumns+`
		FROM auth.student_piece_note
		WHERE piece_id = $1 AND student_id = $2 AND teacher_id = $3
		ORDER BY created_at DESC, id DESC
	`, pieceID, studentID, teacherID)
	if err != nil {
		return nil, err
	}
	if rows == nil {
		rows = []models.StudentPieceNote{}
	}
	return rows, nil
}

func (r *StudentPieceRepo) CreateNote(ctx context.Context, n models.StudentPieceNote) (*models.StudentPieceNote, error) {
	var result models.StudentPieceNote
	err := r.db.conn.QueryRowxContext(ctx, `
		INSERT INTO auth.student_piece_note (piece_id, teacher_id, student_id, body, created_at)
		VALUES ($1, $2, $3, $4, NOW())
		RETURNING `+pieceNoteColumns, n.PieceID, n.TeacherID, n.StudentID, n.Body,
	).StructScan(&result)
	if err == nil {
		_, _ = r.db.conn.ExecContext(ctx, `
			UPDATE auth.student_piece SET updated_at = NOW()
			WHERE id = $1 AND student_id = $2 AND teacher_id = $3
		`, n.PieceID, n.StudentID, n.TeacherID)
	}
	return &result, err
}

func (r *StudentPieceRepo) DeleteNote(ctx context.Context, noteID, pieceID, studentID, teacherID int) error {
	_, err := r.db.conn.ExecContext(ctx, `
		DELETE FROM auth.student_piece_note
		WHERE id = $1 AND piece_id = $2 AND student_id = $3 AND teacher_id = $4
	`, noteID, pieceID, studentID, teacherID)
	return err
}

const studentMaterialColumnsWithPiece = `id, teacher_id, student_id, piece_id, kind, title, url, file_name, note, created_at, updated_at`

func (r *StudentPieceRepo) ListMaterialsByPiece(ctx context.Context, pieceID, studentID, teacherID int) ([]models.StudentMaterial, error) {
	var rows []models.StudentMaterial
	err := r.db.conn.SelectContext(ctx, &rows, `
		SELECT `+studentMaterialColumnsWithPiece+`
		FROM auth.student_material
		WHERE piece_id = $1 AND student_id = $2 AND teacher_id = $3
		ORDER BY created_at ASC, id ASC
	`, pieceID, studentID, teacherID)
	if err != nil {
		return nil, err
	}
	if rows == nil {
		rows = []models.StudentMaterial{}
	}
	return rows, nil
}
