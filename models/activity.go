package models

import "time"

// Activity kinds for teacher journal
const (
	ActivityLesson  = "lesson"
	ActivityMissed  = "missed"
	ActivityPayment = "payment"
	ActivityRenew   = "renew"
	ActivityStudent = "student"
)

type Activity struct {
	ID         int64     `json:"id" db:"id"`
	TeacherID  int       `json:"teacher_id" db:"teacher_id"`
	StudentID  *int      `json:"student_id,omitempty" db:"student_id"`
	Kind       string    `json:"kind" db:"kind"`
	Title      string    `json:"title" db:"title"`
	Detail     string    `json:"detail" db:"detail"`
	Amount     *int      `json:"amount,omitempty" db:"amount"`
	CreatedAt  time.Time `json:"created_at" db:"created_at"`
}
