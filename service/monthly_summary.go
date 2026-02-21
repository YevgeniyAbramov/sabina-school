package service

import (
	"context"
	"sckool/db"
	"sckool/models"
	"time"
)

type MonthlySummaryService struct {
	repo db.MonthlySummaryRepository
}

func NewMonthlySummaryService(repo db.MonthlySummaryRepository) *MonthlySummaryService {
	return &MonthlySummaryService{repo: repo}
}

func (s *MonthlySummaryService) AddPaymentToMonthlySummary(ctx context.Context, teacherID, amount int) error {
	now := time.Now()
	year := now.Year()
	month := int(now.Month())

	return s.repo.AddToMonthlySummary(ctx, teacherID, year, month, amount)
}

func (s *MonthlySummaryService) AddPaymentToMonthlySummaryByDate(ctx context.Context, teacherID, amount int, date time.Time) error {
	year := date.Year()
	month := int(date.Month())

	return s.repo.AddToMonthlySummary(ctx, teacherID, year, month, amount)
}

func (s *MonthlySummaryService) GetMonthlySummary(ctx context.Context, teacherID, year, month int) (*models.MonthlySummary, error) {
	result, err := s.repo.GetMonthlySummary(ctx, teacherID, year, month)
	if err != nil {
		return result, err
	}

	return result, nil

}
