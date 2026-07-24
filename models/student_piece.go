package models

import "time"

type PieceStatus string

const (
	PieceStatusLearning PieceStatus = "learning"
	PieceStatusPolished PieceStatus = "polished"
	PieceStatusPaused   PieceStatus = "paused"
	PieceStatusLearned  PieceStatus = "learned"
)

// StudentPiece is one repertoire work the student is learning
// (e.g. "ХТК, прелюдия и фуга ре минор"). Materials and lesson notes hang off it.
type StudentPiece struct {
	ID         int         `json:"id" db:"id"`
	TeacherID  int         `json:"teacher_id" db:"teacher_id"`
	StudentID  int         `json:"student_id" db:"student_id"`
	Title      string      `json:"title" db:"title"`
	Composer   string      `json:"composer" db:"composer"`
	Readiness  int         `json:"readiness" db:"readiness"` // 0…100, set by teacher
	Status     PieceStatus `json:"status" db:"status"`
	CreatedAt  time.Time   `json:"created_at" db:"created_at"`
	UpdatedAt  time.Time   `json:"updated_at" db:"updated_at"`
	// List/detail enrichment (not always filled by every query)
	NotesCount     int `json:"notes_count,omitempty" db:"notes_count"`
	MaterialsCount int `json:"materials_count,omitempty" db:"materials_count"`
}

type StudentPieceNote struct {
	ID        int       `json:"id" db:"id"`
	PieceID   int       `json:"piece_id" db:"piece_id"`
	TeacherID int       `json:"teacher_id" db:"teacher_id"`
	StudentID int       `json:"student_id" db:"student_id"`
	Body      string    `json:"body" db:"body"`
	CreatedAt time.Time `json:"created_at" db:"created_at"`
}

type PieceInput struct {
	Title     string      `json:"title"`
	Composer  string      `json:"composer"`
	Readiness *int        `json:"readiness,omitempty"`
	Status    PieceStatus `json:"status"`
}

type PieceNoteInput struct {
	Body string `json:"body"`
}

// PieceDetail bundles a piece with its materials and lesson notes.
type PieceDetail struct {
	StudentPiece
	Materials []StudentMaterial  `json:"materials"`
	Notes     []StudentPieceNote `json:"notes"`
}
