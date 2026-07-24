package service

import (
	"context"
	"errors"
	"strings"

	"sckool/db"
	"sckool/models"
)

type StudentPieceService struct {
	pieceRepo    db.StudentPieceRepository
	studentRepo  db.StudentRepository
	materialRepo db.StudentMaterialRepository
}

func NewStudentPieceService(
	pieceRepo db.StudentPieceRepository,
	studentRepo db.StudentRepository,
	materialRepo db.StudentMaterialRepository,
) *StudentPieceService {
	return &StudentPieceService{
		pieceRepo:    pieceRepo,
		studentRepo:  studentRepo,
		materialRepo: materialRepo,
	}
}

func (s *StudentPieceService) ensureStudent(ctx context.Context, studentID, teacherID int) error {
	if _, err := s.studentRepo.GetStudentForId(ctx, studentID, teacherID); err != nil {
		return errors.New("ученик не найден")
	}
	return nil
}

func (s *StudentPieceService) List(ctx context.Context, studentID, teacherID int) ([]models.StudentPiece, error) {
	if err := s.ensureStudent(ctx, studentID, teacherID); err != nil {
		return nil, err
	}
	return s.pieceRepo.ListByStudent(ctx, studentID, teacherID)
}

func (s *StudentPieceService) GetDetail(ctx context.Context, pieceID, studentID, teacherID int) (*models.PieceDetail, error) {
	if err := s.ensureStudent(ctx, studentID, teacherID); err != nil {
		return nil, err
	}
	piece, err := s.pieceRepo.GetByID(ctx, pieceID, studentID, teacherID)
	if err != nil {
		return nil, errors.New("произведение не найдено")
	}
	materials, err := s.pieceRepo.ListMaterialsByPiece(ctx, pieceID, studentID, teacherID)
	if err != nil {
		return nil, err
	}
	notes, err := s.pieceRepo.ListNotes(ctx, pieceID, studentID, teacherID)
	if err != nil {
		return nil, err
	}
	return &models.PieceDetail{
		StudentPiece: *piece,
		Materials:    materials,
		Notes:        notes,
	}, nil
}

func (s *StudentPieceService) Create(ctx context.Context, studentID, teacherID int, input models.PieceInput) (*models.StudentPiece, error) {
	if err := s.ensureStudent(ctx, studentID, teacherID); err != nil {
		return nil, err
	}
	title := strings.TrimSpace(input.Title)
	if title == "" {
		return nil, errors.New("название обязательно")
	}
	readiness := 0
	if input.Readiness != nil {
		readiness = clampReadiness(*input.Readiness)
	}
	status := normalizePieceStatus(input.Status)
	return s.pieceRepo.Create(ctx, models.StudentPiece{
		TeacherID: teacherID,
		StudentID: studentID,
		Title:     title,
		Composer:  strings.TrimSpace(input.Composer),
		Readiness: readiness,
		Status:    status,
	})
}

func (s *StudentPieceService) Update(ctx context.Context, pieceID, studentID, teacherID int, input models.PieceInput) (*models.StudentPiece, error) {
	if err := s.ensureStudent(ctx, studentID, teacherID); err != nil {
		return nil, err
	}
	if _, err := s.pieceRepo.GetByID(ctx, pieceID, studentID, teacherID); err != nil {
		return nil, errors.New("произведение не найдено")
	}
	title := strings.TrimSpace(input.Title)
	if title == "" {
		return nil, errors.New("название обязательно")
	}
	readiness := 0
	if input.Readiness != nil {
		readiness = clampReadiness(*input.Readiness)
	}
	status := normalizePieceStatus(input.Status)
	return s.pieceRepo.Update(ctx, pieceID, studentID, teacherID, title, strings.TrimSpace(input.Composer), readiness, status)
}

func (s *StudentPieceService) Delete(ctx context.Context, pieceID, studentID, teacherID int) error {
	if err := s.ensureStudent(ctx, studentID, teacherID); err != nil {
		return err
	}
	if _, err := s.pieceRepo.GetByID(ctx, pieceID, studentID, teacherID); err != nil {
		return errors.New("произведение не найдено")
	}
	return s.pieceRepo.Delete(ctx, pieceID, studentID, teacherID)
}

func (s *StudentPieceService) AddNote(ctx context.Context, pieceID, studentID, teacherID int, input models.PieceNoteInput) (*models.StudentPieceNote, error) {
	if err := s.ensureStudent(ctx, studentID, teacherID); err != nil {
		return nil, err
	}
	if _, err := s.pieceRepo.GetByID(ctx, pieceID, studentID, teacherID); err != nil {
		return nil, errors.New("произведение не найдено")
	}
	body := strings.TrimSpace(input.Body)
	if body == "" {
		return nil, errors.New("текст заметки обязателен")
	}
	return s.pieceRepo.CreateNote(ctx, models.StudentPieceNote{
		PieceID:   pieceID,
		TeacherID: teacherID,
		StudentID: studentID,
		Body:      body,
	})
}

func (s *StudentPieceService) DeleteNote(ctx context.Context, noteID, pieceID, studentID, teacherID int) error {
	if err := s.ensureStudent(ctx, studentID, teacherID); err != nil {
		return err
	}
	return s.pieceRepo.DeleteNote(ctx, noteID, pieceID, studentID, teacherID)
}

func clampReadiness(v int) int {
	if v < 0 {
		return 0
	}
	if v > 100 {
		return 100
	}
	return v
}

func normalizePieceStatus(s models.PieceStatus) models.PieceStatus {
	switch s {
	case models.PieceStatusLearning, models.PieceStatusPolished, models.PieceStatusPaused, models.PieceStatusLearned:
		return s
	default:
		return models.PieceStatusLearning
	}
}
