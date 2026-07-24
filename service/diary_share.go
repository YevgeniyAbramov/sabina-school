package service

import (
	"context"
	"crypto/rand"
	"encoding/base64"
	"errors"
	"fmt"
	"os"
	"strings"
	"time"

	"sckool/db"
	"sckool/models"
)

type DiaryShareService struct {
	shareRepo    db.DiaryShareRepository
	studentRepo  db.StudentRepository
	pieceRepo    db.StudentPieceRepository
}

func NewDiaryShareService(
	shareRepo db.DiaryShareRepository,
	studentRepo db.StudentRepository,
	pieceRepo db.StudentPieceRepository,
) *DiaryShareService {
	return &DiaryShareService{
		shareRepo:   shareRepo,
		studentRepo: studentRepo,
		pieceRepo:   pieceRepo,
	}
}

func (s *DiaryShareService) Create(
	ctx context.Context,
	studentID, teacherID int,
	daysValid int,
	publicBaseURL string,
) (*models.DiaryShareCreateResult, error) {
	if _, err := s.studentRepo.GetStudentForId(ctx, studentID, teacherID); err != nil {
		return nil, errors.New("ученик не найден")
	}
	if daysValid <= 0 {
		daysValid = 30
	}
	if daysValid > 90 {
		daysValid = 90
	}

	token, err := randomShareToken()
	if err != nil {
		return nil, errors.New("не удалось создать ссылку")
	}

	link, err := s.shareRepo.Create(ctx, models.DiaryShareLink{
		TeacherID: teacherID,
		StudentID: studentID,
		Token:     token,
		ExpiresAt: time.Now().Add(time.Duration(daysValid) * 24 * time.Hour),
	})
	if err != nil {
		return nil, err
	}

	base := strings.TrimRight(publicBaseURL, "/")
	if base == "" {
		base = strings.TrimRight(os.Getenv("PUBLIC_WEB_URL"), "/")
	}
	url := fmt.Sprintf("%s/share/diary/%s", base, link.Token)

	return &models.DiaryShareCreateResult{
		Token:     link.Token,
		URL:       url,
		ExpiresAt: link.ExpiresAt,
	}, nil
}

func (s *DiaryShareService) ViewByToken(ctx context.Context, token string, fileBaseURL string) (*models.PublicDiaryView, error) {
	token = strings.TrimSpace(token)
	if token == "" {
		return nil, errors.New("ссылка недействительна")
	}

	link, err := s.shareRepo.GetValidByToken(ctx, token, time.Now())
	if err != nil {
		return nil, errors.New("ссылка недействительна или истекла")
	}

	student, err := s.studentRepo.GetStudentForId(ctx, link.StudentID, link.TeacherID)
	if err != nil {
		return nil, errors.New("ученик не найден")
	}

	pieces, err := s.pieceRepo.ListByStudent(ctx, link.StudentID, link.TeacherID)
	if err != nil {
		return nil, err
	}

	completed := student.TotalLessons - student.RemainingLessons
	if completed < 0 {
		completed = 0
	}

	view := &models.PublicDiaryView{
		StudentName:      strings.TrimSpace(student.FirstName + " " + student.LastName),
		CompletedLessons: completed,
		TotalLessons:     student.TotalLessons,
		RemainingLessons: student.RemainingLessons,
		MissedClasses:    student.MissedClasses,
		PaidAmount:       student.PaidAmount,
		IsPaid:           student.IsPaid,
		ExpiresAt:        link.ExpiresAt,
		Pieces:           make([]models.PublicDiaryPiece, 0, len(pieces)),
	}

	for _, p := range pieces {
		materials, err := s.pieceRepo.ListMaterialsByPiece(ctx, p.ID, link.StudentID, link.TeacherID)
		if err != nil {
			return nil, err
		}
		pubMats := make([]models.PublicDiaryMaterial, 0, len(materials))
		for _, m := range materials {
			url := absoluteMaterialURL(m.URL, fileBaseURL)
			pubMats = append(pubMats, models.PublicDiaryMaterial{
				Kind:  m.Kind,
				Title: m.Title,
				URL:   url,
				Note:  m.Note,
			})
		}
		view.Pieces = append(view.Pieces, models.PublicDiaryPiece{
			Title:     p.Title,
			Composer:  p.Composer,
			Readiness: p.Readiness,
			Status:    p.Status,
			Materials: pubMats,
		})
	}

	return view, nil
}

func absoluteMaterialURL(raw, fileBaseURL string) string {
	raw = strings.TrimSpace(raw)
	if raw == "" {
		return ""
	}
	if strings.HasPrefix(raw, "http://") || strings.HasPrefix(raw, "https://") {
		return raw
	}
	base := strings.TrimRight(fileBaseURL, "/")
	if base == "" {
		return raw
	}
	if strings.HasPrefix(raw, "/") {
		return base + raw
	}
	return base + "/" + raw
}

func randomShareToken() (string, error) {
	buf := make([]byte, 24)
	if _, err := rand.Read(buf); err != nil {
		return "", err
	}
	return base64.RawURLEncoding.EncodeToString(buf), nil
}
