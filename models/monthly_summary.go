package models

import "time"

type MonthlySummary struct {
	Id          int       `json:"id" db:"id"`
	TeacherID   int       `json:"teacher_id" db:"teacher_id"`
	Year        int       `json:"year" db:"year"`
	Month       int       `json:"month" db:"month"`
	TotalAmount int       `json:"total_amount" db:"total_amount"`
	CreatedAt   time.Time `json:"created_at" db:"created_at"`
	UpdatedAt   time.Time `json:"updated_at" db:"updated_at"`
}
