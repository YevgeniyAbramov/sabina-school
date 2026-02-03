package db

import (
	"context"
	"sckool/models"
)

func AddToMonthlySummary(ctx context.Context, teacherID, year, month, amount int) error {
	db := GetDB()

	query := `
		INSERT INTO auth.monthly_summary (teacher_id, year, month, total_amount, created_at, updated_at)
		VALUES ($1, $2, $3, $4, NOW(), NOW())
		ON CONFLICT (teacher_id, year, month)
		DO UPDATE SET 
			total_amount = auth.monthly_summary.total_amount + EXCLUDED.total_amount,
			updated_at = NOW()
	`
	_, err := db.ExecContext(ctx, query, teacherID, year, month, amount)
	if err != nil {
		return err
	}

	return nil
}

func GetMonthlySummary(ctx context.Context, teacherID, year, month int) (*models.MonthlySummary, error) {
	db := GetDB()
	var result models.MonthlySummary

	query := `
		SELECT * FROM auth.monthly_summary
		WHERE teacher_id = $1
		AND year = $2
		AND month = $3
	`

	err := db.GetContext(ctx, &result, query, teacherID, year, month)
	if err != nil {
		return nil, err
	}

	return &result, nil
}

func GetMonthlySummaries(ctx context.Context, teacherID, year int) ([]models.MonthlySummary, error) {
	db := GetDB()

	var result []models.MonthlySummary
	query := `
		SELECT * FROM auth.monthly_summary
		WHERE teacher_id = $1
		AND year = $2
		ORDER BY month ASC
	`

	err := db.SelectContext(ctx, &result, query, teacherID, year)
	if err != nil {
		return nil, err
	}

	return result, nil
}
