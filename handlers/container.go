package handler

import (
	"sckool/service"
)

type Handlers struct {
	Student        *StudentHandler
	Auth           *AuthHandler
	MonthlySummary *MonthlySummaryHandler
}

func NewHandlers(services *service.Services) *Handlers {
	return &Handlers{
		Student:        NewStudentHandler(services.Student),
		Auth:           NewAuthHandler(services.Auth),
		MonthlySummary: NewMonthlySummaryHandler(services.MonthlySummary),
	}
}
