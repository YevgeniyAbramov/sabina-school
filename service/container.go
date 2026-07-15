package service

import (
	"sckool/db"
)

type Services struct {
	Student         *StudentService
	Auth            *AuthService
	MonthlySummary  *MonthlySummaryService
	StudentSchedule *StudentScheduleService
	Activity        *ActivityService
}

func NewServices(repos *db.Repositories) *Services {
	monthlySummaryService := NewMonthlySummaryService(repos.MonthlySummary)
	activityService := NewActivityService(repos.Activity)

	return &Services{
		Student:         NewStudentService(repos.Student, monthlySummaryService, activityService),
		Auth:            NewAuthService(repos.Teacher),
		MonthlySummary:  monthlySummaryService,
		StudentSchedule: NewStudentScheduleService(repos.StudentSchedule, repos.Student),
		Activity:        activityService,
	}
}
