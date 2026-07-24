package handler

import (
	"sckool/service"
)

type Handlers struct {
	Student         *StudentHandler
	Auth            *AuthHandler
	MonthlySummary  *MonthlySummaryHandler
	StudentSchedule *StudentScheduleHandler
	Activity        *ActivityHandler
	StudentMaterial *StudentMaterialHandler
	StudentPiece    *StudentPieceHandler
}

func NewHandlers(services *service.Services) *Handlers {
	return &Handlers{
		Student:         NewStudentHandler(services.Student),
		Auth:            NewAuthHandler(services.Auth),
		MonthlySummary:  NewMonthlySummaryHandler(services.MonthlySummary),
		StudentSchedule: NewStudentScheduleHandler(services.StudentSchedule),
		Activity:        NewActivityHandler(services.Activity),
		StudentMaterial: NewStudentMaterialHandler(services.StudentMaterial),
		StudentPiece:    NewStudentPieceHandler(services.StudentPiece),
	}
}
