package service

import (
	"context"
	"sckool/db"
	"sckool/models"
	"time"
)

func AddPaymentToMonthlySummary(ctx context.Context, teacherID, amount int) error {
	now := time.Now()
	year := now.Year()
	month := int(now.Month())

	return db.AddToMonthlySummary(ctx, teacherID, year, month, amount)
}

func AddPaymentToMonthlySummaryByDate(ctx context.Context, teacherID, amount int, date time.Time) error {
	year := date.Year()
	month := int(date.Month())

	return db.AddToMonthlySummary(ctx, teacherID, year, month, amount)
}

func GetMonthlySummary(ctx context.Context, teacherID, year, month int) (*models.MonthlySummary, error) {
	result, err := db.GetMonthlySummary(ctx, teacherID, year, month)
	if err != nil {
		return result, err
	}

	return result, nil

}
