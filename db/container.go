package db

type Repositories struct {
	Student         StudentRepository
	Teacher         TeacherRepository
	MonthlySummary  MonthlySummaryRepository
	StudentSchedule StudentScheduleRepository
	Activity        ActivityRepository
	StudentMaterial StudentMaterialRepository
	StudentPiece    StudentPieceRepository
	DiaryShare      DiaryShareRepository
}

func NewRepositories(db *Database) *Repositories {
	return &Repositories{
		Student:         NewStudentRepository(db),
		Teacher:         NewTeacherRepo(db),
		MonthlySummary:  NewMonthlySummaryRepo(db),
		StudentSchedule: NewStudentScheduleRepo(db),
		Activity:        NewActivityRepo(db),
		StudentMaterial: NewStudentMaterialRepo(db),
		StudentPiece:    NewStudentPieceRepo(db),
		DiaryShare:      NewDiaryShareRepo(db),
	}
}
