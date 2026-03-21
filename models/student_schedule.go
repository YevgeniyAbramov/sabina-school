package models

import "time"

type ScheduleSlot struct {
	ID        int       `json:"id" db:"id"`
	StudentID int       `json:"student_id" db:"student_id"`
	TeacherID int       `json:"teacher_id" db:"teacher_id"`
	DayOfWeek int       `json:"day_of_week" db:"day_of_week"`
	TimeSlot  string    `json:"time_slot" db:"time_slot"`
	CreatedAt time.Time `json:"created_at" db:"created_at"`
	UpdatedAt time.Time `json:"updated_at" db:"updated_at"`
}

type ScheduleSlotInput struct {
	DayOfWeek int    `json:"day_of_week"`
	TimeSlot  string `json:"time_slot"`
}

type ScheduleReplaceRequest struct {
	Slots []ScheduleSlotInput `json:"slots"`
}
