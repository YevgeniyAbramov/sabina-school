package models

import "time"

// DiaryShareLink lets a parent open a read-only diary page without login.
type DiaryShareLink struct {
	ID        int        `json:"id" db:"id"`
	TeacherID int        `json:"teacher_id" db:"teacher_id"`
	StudentID int        `json:"student_id" db:"student_id"`
	Token     string     `json:"token" db:"token"`
	ExpiresAt time.Time  `json:"expires_at" db:"expires_at"`
	RevokedAt *time.Time `json:"revoked_at,omitempty" db:"revoked_at"`
	CreatedAt time.Time  `json:"created_at" db:"created_at"`
}

type DiaryShareCreateResult struct {
	Token     string    `json:"token"`
	URL       string    `json:"url"`
	ExpiresAt time.Time `json:"expires_at"`
}

// PublicDiaryView is what parents see — no lesson notes.
type PublicDiaryView struct {
	StudentName string             `json:"student_name"`
	ExpiresAt   time.Time          `json:"expires_at"`
	Pieces      []PublicDiaryPiece `json:"pieces"`
}

type PublicDiaryPiece struct {
	Title     string                `json:"title"`
	Composer  string                `json:"composer"`
	Readiness int                   `json:"readiness"`
	Status    PieceStatus           `json:"status"`
	Materials []PublicDiaryMaterial `json:"materials"`
}

type PublicDiaryMaterial struct {
	Kind  MaterialKind `json:"kind"`
	Title string       `json:"title"`
	URL   string       `json:"url"`
	Note  string       `json:"note,omitempty"`
}
