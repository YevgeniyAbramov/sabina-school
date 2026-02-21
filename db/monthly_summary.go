package db

import (
	"context"
	"sckool/models"
)

type MonthlySummaryRepository interface {
	AddToMonthlySummary(ctx context.Context, teacherID, year, month, amount int) error
	GetMonthlySummary(ctx context.Context, teacherID, year, month int) (*models.MonthlySummary, error)
	GetMonthlySummaries(ctx context.Context, teacherID, year int) ([]models.MonthlySummary, error)
}

type MonthlySummaryRepo struct {
	db *Database
}

func NewMonthlySummaryRepo(db *Database) *MonthlySummaryRepo {
	return &MonthlySummaryRepo{db: db}
}

func (r *MonthlySummaryRepo) AddToMonthlySummary(ctx context.Context, teacherID, year, month, amount int) error {

	query := `
		INSERT INTO auth.monthly_summary (teacher_id, year, month, total_amount, created_at, updated_at)
		VALUES ($1, $2, $3, $4, NOW(), NOW())
		ON CONFLICT (teacher_id, year, month)
		DO UPDATE SET 
			total_amount = auth.monthly_summary.total_amount + EXCLUDED.total_amount,
			updated_at = NOW()
	`
	_, err := r.db.conn.ExecContext(ctx, query, teacherID, year, month, amount)
	if err != nil {
		return err
	}

	return nil
}

func (r *MonthlySummaryRepo) GetMonthlySummary(ctx context.Context, teacherID, year, month int) (*models.MonthlySummary, error) {
	var result models.MonthlySummary

	query := `
		SELECT * FROM auth.monthly_summary
		WHERE teacher_id = $1
		AND year = $2
		AND month = $3
	`

	err := r.db.conn.GetContext(ctx, &result, query, teacherID, year, month)
	if err != nil {
		return nil, err
	}

	return &result, nil
}

func (r *MonthlySummaryRepo) GetMonthlySummaries(ctx context.Context, teacherID, year int) ([]models.MonthlySummary, error) {
	var result []models.MonthlySummary
	query := `
		SELECT * FROM auth.monthly_summary
		WHERE teacher_id = $1
		AND year = $2
		ORDER BY month ASC
	`

	err := r.db.conn.SelectContext(ctx, &result, query, teacherID, year)
	if err != nil {
		return nil, err
	}

	return result, nil
}
