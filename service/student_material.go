package service

import (
	"errors"
	"strings"

	"context"
	"sckool/db"
	"sckool/models"
)

const maxMaterialFileSize = 20 * 1024 * 1024 // 20MB — сканы нот/PDF

var allowedMaterialFileExt = map[string]bool{
	".pdf":  true,
	".png":  true,
	".jpg":  true,
	".jpeg": true,
	".heic": true,
}

type StudentMaterialService struct {
	materialRepo db.StudentMaterialRepository
	studentRepo  db.StudentRepository
}

func NewStudentMaterialService(materialRepo db.StudentMaterialRepository, studentRepo db.StudentRepository) *StudentMaterialService {
	return &StudentMaterialService{materialRepo: materialRepo, studentRepo: studentRepo}
}

func (s *StudentMaterialService) ensureStudent(ctx context.Context, studentID, teacherID int) error {
	if _, err := s.studentRepo.GetStudentForId(ctx, studentID, teacherID); err != nil {
		return errors.New("ученик не найден")
	}
	return nil
}

func (s *StudentMaterialService) ListByStudent(ctx context.Context, studentID, teacherID int) ([]models.StudentMaterial, error) {
	if err := s.ensureStudent(ctx, studentID, teacherID); err != nil {
		return nil, err
	}
	return s.materialRepo.ListByStudent(ctx, studentID, teacherID)
}

func (s *StudentMaterialService) CreateLink(ctx context.Context, studentID, teacherID int, input models.MaterialLinkInput) (*models.StudentMaterial, error) {
	if err := s.ensureStudent(ctx, studentID, teacherID); err != nil {
		return nil, err
	}

	title := strings.TrimSpace(input.Title)
	url := strings.TrimSpace(input.URL)
	if title == "" {
		return nil, errors.New("название обязательно")
	}
	if url == "" {
		return nil, errors.New("ссылка обязательна")
	}
	if !strings.HasPrefix(url, "http://") && !strings.HasPrefix(url, "https://") {
		return nil, errors.New("ссылка должна начинаться с http:// или https://")
	}

	return s.materialRepo.Create(ctx, models.StudentMaterial{
		TeacherID: teacherID,
		StudentID: studentID,
		Kind:      models.MaterialKindLink,
		Title:     title,
		URL:       url,
		Note:      strings.TrimSpace(input.Note),
	})
}

// CreateFile expects the file to already be saved to disk by the handler (which
// owns the fiber-specific multipart parsing); this keeps the service focused on
// validation + persistence.
func (s *StudentMaterialService) CreateFile(ctx context.Context, studentID, teacherID int, title, note, fileURL, fileName string) (*models.StudentMaterial, error) {
	if err := s.ensureStudent(ctx, studentID, teacherID); err != nil {
		return nil, err
	}

	title = strings.TrimSpace(title)
	if title == "" {
		title = fileName
	}
	if fileURL == "" {
		return nil, errors.New("файл обязателен")
	}

	return s.materialRepo.Create(ctx, models.StudentMaterial{
		TeacherID: teacherID,
		StudentID: studentID,
		Kind:      models.MaterialKindFile,
		Title:     title,
		URL:       fileURL,
		FileName:  &fileName,
		Note:      strings.TrimSpace(note),
	})
}

func (s *StudentMaterialService) Update(ctx context.Context, id, studentID, teacherID int, input models.MaterialUpdateInput) (*models.StudentMaterial, error) {
	if err := s.ensureStudent(ctx, studentID, teacherID); err != nil {
		return nil, err
	}
	title := strings.TrimSpace(input.Title)
	if title == "" {
		return nil, errors.New("название обязательно")
	}
	return s.materialRepo.Update(ctx, id, studentID, teacherID, title, strings.TrimSpace(input.Note))
}

// Delete returns the deleted row so the caller (handler) can clean up the file on disk.
func (s *StudentMaterialService) Delete(ctx context.Context, id, studentID, teacherID int) (*models.StudentMaterial, error) {
	if err := s.ensureStudent(ctx, studentID, teacherID); err != nil {
		return nil, err
	}
	material, err := s.materialRepo.GetByID(ctx, id, studentID, teacherID)
	if err != nil {
		return nil, errors.New("материал не найден")
	}
	if err := s.materialRepo.Delete(ctx, id, studentID, teacherID); err != nil {
		return nil, err
	}
	return material, nil
}

func IsAllowedMaterialFileExt(ext string) bool {
	return allowedMaterialFileExt[strings.ToLower(ext)]
}

func MaxMaterialFileSize() int64 {
	return maxMaterialFileSize
}
