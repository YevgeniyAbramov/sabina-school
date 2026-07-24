package models

import "time"

type MaterialKind string

const (
	MaterialKindLink MaterialKind = "link"
	MaterialKindFile MaterialKind = "file"
)

// StudentMaterial is one entry under a repertoire piece: a link (e.g. YouTube)
// or an uploaded file (sheet music scan/PDF).
type StudentMaterial struct {
	ID        int          `json:"id" db:"id"`
	TeacherID int          `json:"teacher_id" db:"teacher_id"`
	StudentID int          `json:"student_id" db:"student_id"`
	PieceID   *int         `json:"piece_id" db:"piece_id"`
	Kind      MaterialKind `json:"kind" db:"kind"`
	Title     string       `json:"title" db:"title"`
	URL       string       `json:"url" db:"url"`
	FileName  *string      `json:"file_name" db:"file_name"`
	Note      string       `json:"note" db:"note"`
	CreatedAt time.Time    `json:"created_at" db:"created_at"`
	UpdatedAt time.Time    `json:"updated_at" db:"updated_at"`
}

type MaterialLinkInput struct {
	Title   string `json:"title"`
	URL     string `json:"url"`
	Note    string `json:"note"`
	PieceID *int   `json:"piece_id"`
}

type MaterialUpdateInput struct {
	Title string `json:"title"`
	Note  string `json:"note"`
}
