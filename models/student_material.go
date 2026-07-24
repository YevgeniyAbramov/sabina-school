package models

import "time"

type MaterialKind string

const (
	MaterialKindLink MaterialKind = "link"
	MaterialKindFile MaterialKind = "file"
)

// StudentMaterial is one entry in a student's "program": either a link (e.g. a
// YouTube recording) or an uploaded file (e.g. sheet music scan/PDF). Kept as a
// single table with a `kind` discriminator so the list stays chronologically
// ordered, but each kind carries only the fields relevant to it.
type StudentMaterial struct {
	ID        int          `json:"id" db:"id"`
	TeacherID int          `json:"teacher_id" db:"teacher_id"`
	StudentID int          `json:"student_id" db:"student_id"`
	Kind      MaterialKind `json:"kind" db:"kind"`
	Title     string       `json:"title" db:"title"`
	URL       string       `json:"url" db:"url"`
	FileName  *string      `json:"file_name" db:"file_name"`
	Note      string       `json:"note" db:"note"`
	CreatedAt time.Time    `json:"created_at" db:"created_at"`
	UpdatedAt time.Time    `json:"updated_at" db:"updated_at"`
}

type MaterialLinkInput struct {
	Title string `json:"title"`
	URL   string `json:"url"`
	Note  string `json:"note"`
}

type MaterialUpdateInput struct {
	Title string `json:"title"`
	Note  string `json:"note"`
}
