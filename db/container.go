package db

type Repositories struct {
	Student         StudentRepository
	Teacher         TeacherRepository
	MonthlySummary  MonthlySummaryRepository
	StudentSchedule StudentScheduleRepository
}

func NewRepositories(db *Database) *Repositories {
	return &Repositories{
		Student:         NewStudentRepository(db),
		Teacher:         NewTeacherRepo(db),
		MonthlySummary:  NewMonthlySummaryRepo(db),
		StudentSchedule: NewStudentScheduleRepo(db),
	}
}
