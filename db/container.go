package db

type Repositories struct {
	Student        StudentRepository
	Teacher        TeacherRepository
	MonthlySummary MonthlySummaryRepository
}

func NewRepositories(db *Database) *Repositories {
	return &Repositories{
		Student:        NewStudentRepository(db),
		Teacher:        NewTeacherRepo(db),
		MonthlySummary: NewMonthlySummaryRepo(db),
	}
}
