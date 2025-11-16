package models

import "time"

type Student struct {
	Id               int        `json:"id" db:"id"`                               // Уникальный идентификатор студента
	TeacherID        int        `json:"teacher_id" db:"teacher_id"`               // ID преподавателя
	FirstName        string     `json:"first_name" db:"first_name"`               // Имя студента
	LastName         string     `json:"last_name" db:"last_name"`                 // Фамилия студента
	MiddleName       *string    `json:"middle_name" db:"middle_name"`             //Отчество
	TotalLessons     int        `json:"total_lessons" db:"total_lessons"`         // Общее количество уроков, купленных студентом
	RemainingLessons int        `json:"remaining_lessons" db:"remaining_lessons"` // Оставшееся количество уроков
	PaidAmount       int        `json:"paid_amount" db:"paid_amount"`             // Сумма оплаты за уроки
	MissedClasses    int        `json:"missed_classes" db:"missed_classes"`       // Количество пропущенных уроков
	IsPaid           bool       `json:"is_paid" db:"is_paid"`                     // Флаг, показывающий, оплачены ли уроки
	CreatedAt        time.Time  `json:"created_at" db:"created_at"`               // Дата и время создания записи
	UpdatedAt        time.Time  `json:"updated_at" db:"updated_at"`               // Дата и время последнего обновления записи
	DeletedAt        *time.Time `json:"deleted_at" db:"deleted_at"`               // Дата и время логического удаления (soft delete)
}
