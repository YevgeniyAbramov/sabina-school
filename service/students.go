package service

import (
	"context"
	"errors"
	"sckool/db"
	"sckool/logger"
	"sckool/models"
)

type StudentService struct {
	repo                  db.StudentRepository
	monthlySummaryService *MonthlySummaryService
}

func NewStudentService(repo db.StudentRepository, monthlySummaryService *MonthlySummaryService) *StudentService {
	return &StudentService{
		repo:                  repo,
		monthlySummaryService: monthlySummaryService,
	}
}

func (s *StudentService) CreateStudent(ctx context.Context, student models.Student) (*models.Student, error) {
	result, err := s.repo.CreateStudent(ctx, student)
	if err != nil {
		return nil, err
	}

	if student.IsPaid && student.PaidAmount > 0 {
		go s.monthlySummaryService.AddPaymentToMonthlySummary(ctx, student.TeacherID, student.PaidAmount)
	}

	go logger.Log("create_student", student.TeacherID, &result.Id, "success", "Студент создан")
	return result, nil
}

func (s *StudentService) GetStudent(ctx context.Context, teacherID int, isPaid *bool) ([]models.Student, error) {
	result, err := s.repo.GetStudent(ctx, teacherID, isPaid)
	if err != nil {
		return nil, err
	}

	return result, err
}

func (s *StudentService) GetStudentForId(ctx context.Context, id int, teacherID int) (*models.Student, error) {
	result, err := s.repo.GetStudentForId(ctx, id, teacherID)
	if err != nil {
		return nil, err
	}

	return result, err
}

func (s *StudentService) DeleteStudent(ctx context.Context, id int, teacherID int) error {
	err := s.repo.DeleteStudent(ctx, id, teacherID)
	if err != nil {
		return err
	}

	go logger.Log("delete_student", teacherID, &id, "success", "Студент удален")
	return nil
}

func (s *StudentService) UpdateStudent(ctx context.Context, id int, teacherID int, student models.Student) (*models.Student, error) {

	oldStudent, err := s.repo.GetStudentForId(ctx, id, teacherID)
	if err != nil {
		return nil, err
	}
	result, err := s.repo.UpdateStudent(ctx, id, teacherID, student)
	if err != nil {
		return nil, err
	}

	if student.IsPaid && student.PaidAmount > oldStudent.PaidAmount {
		diff := student.PaidAmount - oldStudent.PaidAmount
		go s.monthlySummaryService.AddPaymentToMonthlySummaryByDate(ctx, teacherID, diff, result.UpdatedAt)
	}

	go logger.Log("update_student", teacherID, &id, "success", "Студент обновлен")
	return result, nil
}

func (s *StudentService) CompleteLesson(ctx context.Context, id int, teacherID int) error {
	resp, err := s.repo.GetStudentForId(ctx, id, teacherID)
	if err != nil {
		return err
	}

	if resp.RemainingLessons == 0 {
		return errors.New("количество уроков истекло")
	}

	newRemaining := resp.RemainingLessons - 1
	if newRemaining < 0 {
		newRemaining = 0
	}

	newPaidAmount := resp.PaidAmount
	if newRemaining == 0 {
		newPaidAmount = 0
	} else if resp.RemainingLessons > 0 {
		lessonPrice := resp.PaidAmount / resp.RemainingLessons
		newPaidAmount = resp.PaidAmount - lessonPrice
	}

	newIsPaid := resp.IsPaid
	if newRemaining == 0 {
		newIsPaid = false
	}

	err = s.repo.CompleteLesson(ctx, newRemaining, id, newPaidAmount, teacherID, newIsPaid)
	if err != nil {
		return err
	}

	go logger.Log("complete_lesson", teacherID, &id, "success", "Урок завершен")
	return nil
}

func (s *StudentService) MarkMissed(ctx context.Context, id int, teacherID int) error {
	student, err := s.repo.GetStudentForId(ctx, id, teacherID)
	if err != nil {
		return err
	}

	newMissedCount := student.MissedClasses + 1

	err = s.repo.MarkMissed(ctx, id, newMissedCount, teacherID)
	if err != nil {
		return err
	}

	go logger.Log("mark_missed", teacherID, &id, "success", "Пропуск отмечен")
	return nil
}
