package service

import (
	"context"
	"errors"
	"sckool/db"
	"sckool/models"
)

type StudentScheduleService struct {
	scheduleRepo db.StudentScheduleRepository
	studentRepo  db.StudentRepository
}

func NewStudentScheduleService(scheduleRepo db.StudentScheduleRepository, studentRepo db.StudentRepository) *StudentScheduleService {
	return &StudentScheduleService{
		scheduleRepo: scheduleRepo,
		studentRepo:  studentRepo,
	}
}

func (s *StudentScheduleService) GetByStudentID(ctx context.Context, studentID, teacherID int) ([]models.ScheduleSlot, error) {
	if _, err := s.studentRepo.GetStudentForId(ctx, studentID, teacherID); err != nil {
		return nil, errors.New("ученик не найден")
	}
	return s.scheduleRepo.GetByStudentID(ctx, studentID, teacherID)
}

func (s *StudentScheduleService) GetByTeacherAndDay(ctx context.Context, teacherID, dayOfWeek int) ([]models.ScheduleSlot, error) {
	if dayOfWeek < 0 || dayOfWeek > 6 {
		return nil, errors.New("day_of_week должен быть от 0 до 6")
	}
	return s.scheduleRepo.GetByTeacherAndDay(ctx, teacherID, dayOfWeek)
}

func (s *StudentScheduleService) ReplaceForStudent(ctx context.Context, studentID, teacherID int, slots []models.ScheduleSlotInput) ([]models.ScheduleSlot, error) {
	if _, err := s.studentRepo.GetStudentForId(ctx, studentID, teacherID); err != nil {
		return nil, errors.New("ученик не найден")
	}
	for i := range slots {
		if slots[i].DayOfWeek < 0 || slots[i].DayOfWeek > 6 {
			return nil, errors.New("day_of_week должен быть от 0 до 6")
		}
		if slots[i].TimeSlot == "" {
			return nil, errors.New("time_slot обязателен")
		}
	}
	return s.scheduleRepo.ReplaceForStudent(ctx, studentID, teacherID, slots)
}
