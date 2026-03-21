package service

import (
	"sckool/db"
)

type Services struct {
	Student         *StudentService
	Auth            *AuthService
	MonthlySummary  *MonthlySummaryService
	StudentSchedule *StudentScheduleService
}

func NewServices(repos *db.Repositories) *Services {
	// Сначала создаем MonthlySummaryService
	// потому что StudentService зависит от него
	monthlySummaryService := NewMonthlySummaryService(repos.MonthlySummary)

	return &Services{
		Student:         NewStudentService(repos.Student, monthlySummaryService),
		Auth:            NewAuthService(repos.Teacher),
		MonthlySummary:  monthlySummaryService,
		StudentSchedule: NewStudentScheduleService(repos.StudentSchedule, repos.Student),
	}
}
