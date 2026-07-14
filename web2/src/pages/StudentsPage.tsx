import { useCallback, useEffect, useMemo, useState } from 'react'
import { Navigate, useNavigate } from 'react-router-dom'
import {
  BarChart3,
  CalendarRange,
  LogOut,
  Plus,
  Users,
  UserRound,
} from 'lucide-react'
import { studentsApi } from '@/api'
import { AuthError } from '@/api/client'
import { useAuth } from '@/context/AuthContext'
import { useToast } from '@/context/ToastContext'
import { AppShell, NavItem } from '@/components/AppShell'
import { StudentCard } from '@/components/StudentCard'
import { AddStudentModal } from '@/components/AddStudentModal'
import { EditStudentModal } from '@/components/EditStudentModal'
import { DeleteConfirmModal } from '@/components/DeleteConfirmModal'
import { CompleteLessonModal } from '@/components/CompleteLessonModal'
import { MarkMissedModal } from '@/components/MarkMissedModal'
import { StudentScheduleModal } from '@/components/StudentScheduleModal'
import { TeacherScheduleModal } from '@/components/TeacherScheduleModal'
import { SummaryModal } from '@/components/SummaryModal'
import { Button } from '@/components/ui/button'
import { Tabs, TabsList, TabsTrigger } from '@/components/ui/tabs'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu'
import { cn, pluralStudents, studentFullName } from '@/lib/utils'
import { copy } from '@/lib/copy'
import type { PaymentFilter, Student, StudentInput } from '@/types'

type Section = 'students' | 'schedule' | 'summary'

export function StudentsPage() {
  const { isAuthenticated, teacherName, logout } = useAuth()
  const { show } = useToast()
  const navigate = useNavigate()

  const [students, setStudents] = useState<Student[]>([])
  const [filter, setFilter] = useState<PaymentFilter>('all')
  const [loading, setLoading] = useState(true)
  const [section, setSection] = useState<Section>('students')

  const [addOpen, setAddOpen] = useState(false)
  const [editStudent, setEditStudent] = useState<Student | null>(null)
  const [deleteId, setDeleteId] = useState<number | null>(null)
  const [completeId, setCompleteId] = useState<number | null>(null)
  const [missedId, setMissedId] = useState<number | null>(null)
  const [scheduleStudent, setScheduleStudent] = useState<Student | null>(null)
  const [teacherScheduleOpen, setTeacherScheduleOpen] = useState(false)
  const [summaryOpen, setSummaryOpen] = useState(false)

  const handleUnauthorized = useCallback(() => {
    logout()
    navigate('/login', { replace: true })
  }, [logout, navigate])

  const loadStudents = useCallback(async () => {
    try {
      const data = await studentsApi.list()
      if (!data.status) {
        show('Не удалось загрузить учеников', 'danger')
        return
      }
      setStudents(data.data || [])
    } catch (e) {
      if (e instanceof AuthError) handleUnauthorized()
      else show('Нет связи с сервером', 'danger')
    } finally {
      setLoading(false)
    }
  }, [handleUnauthorized, show])

  useEffect(() => {
    if (isAuthenticated) void loadStudents()
  }, [isAuthenticated, loadStudents])

  const filtered = useMemo(() => {
    let result = [...students]
    if (filter === 'paid') result = result.filter((s) => s.is_paid)
    else if (filter === 'unpaid') result = result.filter((s) => !s.is_paid)
    result.sort(
      (a, b) =>
        new Date(b.created_at).getTime() - new Date(a.created_at).getTime(),
    )
    return result
  }, [students, filter])

  const unpaidCount = useMemo(
    () => students.filter((s) => !s.is_paid).length,
    [students],
  )

  const completeStudent = useMemo(
    () => students.find((s) => s.id === completeId) ?? null,
    [students, completeId],
  )

  const missedStudent = useMemo(
    () => students.find((s) => s.id === missedId) ?? null,
    [students, missedId],
  )

  if (!isAuthenticated) {
    return <Navigate to="/login" replace />
  }

  async function handleAdd(student: StudentInput) {
    try {
      const data = await studentsApi.create(student)
      if (data.status) {
        await loadStudents()
        return
      }
      show(data.message || 'Не удалось добавить', 'danger')
    } catch (e) {
      if (e instanceof AuthError) handleUnauthorized()
      else show('Не удалось добавить ученика', 'danger')
    }
    throw new Error('add-failed')
  }

  async function handleEdit(id: number, student: StudentInput) {
    try {
      const data = await studentsApi.update(id, student)
      if (data.status) {
        await loadStudents()
        return
      }
      show(data.message || 'Не удалось сохранить', 'danger')
    } catch (e) {
      if (e instanceof AuthError) handleUnauthorized()
      else show('Не удалось обновить данные', 'danger')
    }
    throw new Error('edit-failed')
  }

  async function handleDelete() {
    if (deleteId == null) return
    try {
      const data = await studentsApi.remove(deleteId)
      if (data.status) await loadStudents()
      else show(data.message || 'Не удалось удалить', 'danger')
    } catch (e) {
      if (e instanceof AuthError) handleUnauthorized()
      else show('Не удалось удалить ученика', 'danger')
    }
  }

  async function handleComplete() {
    if (completeId == null) return
    try {
      const data = await studentsApi.completeLesson(completeId)
      if (data.status) await loadStudents()
      else show(data.message || 'Ошибка', 'danger')
    } catch (e) {
      if (e instanceof AuthError) handleUnauthorized()
      else show('Не удалось отметить урок', 'danger')
    }
  }

  async function handleMissed() {
    if (missedId == null) return
    try {
      const data = await studentsApi.markMissed(missedId)
      if (data.status) await loadStudents()
      else show(data.message || 'Ошибка', 'danger')
    } catch (e) {
      if (e instanceof AuthError) handleUnauthorized()
      else show('Не удалось отметить пропуск', 'danger')
    }
  }

  async function openEdit(id: number) {
    try {
      const data = await studentsApi.get(id)
      if (!data.status || !data.data) {
        show('Ученик не найден', 'danger')
        return
      }
      setEditStudent(data.data)
    } catch (e) {
      if (e instanceof AuthError) handleUnauthorized()
      else show('Не удалось загрузить данные', 'danger')
    }
  }

  function openSection(next: Section) {
    setSection(next)
    if (next === 'schedule') setTeacherScheduleOpen(true)
    if (next === 'summary') setSummaryOpen(true)
    if (next === 'students') {
      setTeacherScheduleOpen(false)
      setSummaryOpen(false)
    }
  }

  const brand = (
    <div className="flex items-center gap-2">
      <div className="flex size-8 items-center justify-center rounded-lg bg-primary text-primary-foreground lg:size-9 lg:rounded-xl">
        <svg viewBox="0 0 24 24" className="h-3.5 w-3.5 fill-current lg:h-4 lg:w-4" aria-hidden>
          <path d="M12 3v10.55A4 4 0 1 0 14 17V7h4V3h-6z" />
        </svg>
      </div>
      <div className="min-w-0">
        <p className="font-display text-lg leading-none tracking-tight italic lg:text-xl">
          CON ANIMA
        </p>
        <p className="mt-1 hidden text-[11px] text-muted-foreground lg:block">
          Кабинет
        </p>
      </div>
    </div>
  )

  const sideNav = (
    <>
      <NavItem
        active={section === 'students' && !teacherScheduleOpen && !summaryOpen}
        icon={<Users size={18} />}
        label="Ученики"
        onClick={() => openSection('students')}
      />
      <NavItem
        active={teacherScheduleOpen}
        icon={<CalendarRange size={18} />}
        label="Расписание"
        onClick={() => openSection('schedule')}
      />
      <NavItem
        active={summaryOpen}
        icon={<BarChart3 size={18} />}
        label="Итоги"
        onClick={() => openSection('summary')}
      />
    </>
  )

  const profileMenu = (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button
          type="button"
          variant="ghost"
          className="h-9 gap-2 rounded-xl px-2"
        >
          <span className="flex size-8 items-center justify-center rounded-full bg-accent text-accent-foreground">
            <UserRound size={15} />
          </span>
          <span className="hidden max-w-28 truncate text-sm font-medium md:inline">
            {teacherName || 'Профиль'}
          </span>
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end" className="w-52">
        <DropdownMenuLabel className="font-normal">
          <p className="text-sm font-semibold">
            {teacherName || 'Преподаватель'}
          </p>
          <p className="text-xs text-muted-foreground">CON ANIMA</p>
        </DropdownMenuLabel>
        <DropdownMenuSeparator />
        <DropdownMenuItem
          className="text-destructive focus:text-destructive"
          onClick={() => {
            logout()
            navigate('/login')
          }}
        >
          <LogOut size={16} />
          Выйти
        </DropdownMenuItem>
      </DropdownMenuContent>
    </DropdownMenu>
  )

  // Только «скоро кончится»: ровно 1 урок (0 = уже закончился, не сюда)
  const endingSoonCount = useMemo(
    () => students.filter((s) => s.remaining_lessons === 1).length,
    [students],
  )

  const finishedCount = useMemo(
    () => students.filter((s) => s.remaining_lessons <= 0).length,
    [students],
  )

  return (
    <AppShell
      brand={brand}
      nav={sideNav}
      topRight={profileMenu}
      sidebarFooter={
        <p className="px-1 text-[11px] leading-relaxed text-muted-foreground">
          {teacherName
            ? `${teacherName}, хорошей смены`
            : 'Кабинет преподавателя'}
        </p>
      }
      mobileNav={
        <>
          <NavItem
            variant="bottom"
            active={
              section === 'students' && !teacherScheduleOpen && !summaryOpen
            }
            icon={<Users size={18} />}
            label="Ученики"
            onClick={() => openSection('students')}
          />
          <NavItem
            variant="bottom"
            active={teacherScheduleOpen}
            icon={<CalendarRange size={18} />}
            label="Неделя"
            onClick={() => openSection('schedule')}
          />
          <NavItem
            variant="bottom"
            active={summaryOpen}
            icon={<BarChart3 size={18} />}
            label="Итоги"
            onClick={() => openSection('summary')}
          />
          <NavItem
            variant="bottom"
            icon={<Plus size={20} strokeWidth={2.5} />}
            label="Новый"
            emphasis
            onClick={() => setAddOpen(true)}
          />
        </>
      }
    >
      <div className="mx-auto max-w-5xl">
        <div className="mb-4 space-y-3 sm:mb-6 sm:space-y-4">
          <div className="flex items-end justify-between gap-3">
            <div className="min-w-0">
              <h1 className="font-sans text-xl font-semibold tracking-tight text-foreground sm:text-3xl">
                Ученики
              </h1>
              <p className="mt-0.5 text-sm text-muted-foreground">
                {students.length} {pluralStudents(students.length)}
              </p>
            </div>
            <Button
              type="button"
              onClick={() => setAddOpen(true)}
              className="hidden h-10 gap-1.5 rounded-xl px-3.5 text-[13px] font-semibold shadow-sm sm:inline-flex"
            >
              <Plus size={15} strokeWidth={2.5} />
              Добавить
            </Button>
          </div>

          {!loading &&
            students.length > 0 &&
            (unpaidCount > 0 || endingSoonCount > 0 || finishedCount > 0) && (
              <div className="grid grid-cols-3 gap-2 sm:hidden">
                <AlertCell
                  label={copy.unpaid}
                  value={unpaidCount}
                  tone="bad"
                  onClick={() => setFilter('unpaid')}
                />
                <AlertCell
                  label={copy.endingSoon}
                  value={endingSoonCount}
                  tone="warn"
                />
                <AlertCell
                  label={copy.finished}
                  value={finishedCount}
                  tone="muted"
                />
              </div>
            )}

          {!loading && students.length > 0 && (
            <div className="hidden flex-wrap items-center gap-2 sm:flex">
              {unpaidCount > 0 && (
                <button
                  type="button"
                  onClick={() => setFilter('unpaid')}
                  className="rounded-full bg-destructive/10 px-2.5 py-0.5 text-xs font-medium text-destructive transition hover:bg-destructive/15"
                >
                  {unpaidCount} {copy.unpaid.toLowerCase()}
                </button>
              )}
              {endingSoonCount > 0 && (
                <span className="rounded-full bg-[color-mix(in_srgb,var(--warning)_12%,transparent)] px-2.5 py-0.5 text-xs font-medium text-[var(--warning)]">
                  {copy.endingSoonChip(endingSoonCount)}
                </span>
              )}
              {finishedCount > 0 && (
                <span className="rounded-full bg-muted px-2.5 py-0.5 text-xs font-medium text-muted-foreground">
                  {copy.finishedChip(finishedCount)}
                </span>
              )}
            </div>
          )}

          <Tabs
            value={filter}
            onValueChange={(v) => setFilter(v as PaymentFilter)}
            className="w-full"
          >
            <TabsList className="h-10 w-full rounded-xl bg-card p-1 shadow-sm ring-1 ring-border sm:w-auto">
              <TabsTrigger
                value="all"
                className="flex-1 rounded-lg px-2 text-[13px] sm:flex-none sm:px-3"
              >
                {copy.filterAll}
              </TabsTrigger>
              <TabsTrigger
                value="paid"
                className="flex-1 rounded-lg px-2 text-[13px] sm:flex-none sm:px-3"
              >
                {copy.filterPaid}
              </TabsTrigger>
              <TabsTrigger
                value="unpaid"
                className="flex-1 rounded-lg px-2 text-[13px] sm:flex-none sm:px-3"
              >
                {copy.filterUnpaid}
              </TabsTrigger>
            </TabsList>
          </Tabs>
        </div>

        {loading ? (
          <div className="grid gap-2.5 sm:grid-cols-2 sm:gap-3.5 xl:grid-cols-3">
            {[1, 2, 3, 4].map((i) => (
              <div
                key={i}
                className="h-44 animate-pulse rounded-2xl bg-card"
              />
            ))}
          </div>
        ) : filtered.length === 0 ? (
          <div className="rounded-2xl border border-dashed border-border bg-card px-5 py-12 text-center sm:px-6 sm:py-16">
            <p className="text-base font-semibold text-foreground sm:text-lg">
              {students.length === 0
                ? 'Пока никого нет'
                : 'По этому фильтру пусто'}
            </p>
            <p className="mx-auto mt-2 max-w-sm text-sm text-muted-foreground">
              {students.length === 0
                ? 'Добавьте первого ученика — всё остальное подтянется'
                : 'Сбросьте фильтр или добавьте нового'}
            </p>
            <Button
              type="button"
              onClick={() =>
                students.length === 0 ? setAddOpen(true) : setFilter('all')
              }
              className="mt-5 h-11 rounded-xl font-semibold"
            >
              {students.length === 0 ? (
                <>
                  <Plus size={16} /> Добавить ученика
                </>
              ) : (
                'Показать всех'
              )}
            </Button>
          </div>
        ) : (
          <div className="grid gap-2.5 sm:grid-cols-2 sm:gap-3.5 xl:grid-cols-3">
            {filtered.map((student, i) => (
              <div
                key={student.id}
                style={{ animationDelay: `${Math.min(i, 8) * 35}ms` }}
              >
                <StudentCard
                  student={student}
                  onComplete={setCompleteId}
                  onMissed={setMissedId}
                  onSchedule={(id) => {
                    const s = students.find((x) => x.id === id) || null
                    setScheduleStudent(s)
                  }}
                  onEdit={openEdit}
                  onDelete={setDeleteId}
                />
              </div>
            ))}
          </div>
        )}
      </div>

      <AddStudentModal
        open={addOpen}
        onClose={() => setAddOpen(false)}
        onSubmit={handleAdd}
      />
      <EditStudentModal
        open={Boolean(editStudent)}
        student={editStudent}
        onClose={() => setEditStudent(null)}
        onSubmit={handleEdit}
      />
      <DeleteConfirmModal
        open={deleteId != null}
        onClose={() => setDeleteId(null)}
        onConfirm={handleDelete}
      />
      <CompleteLessonModal
        open={completeId != null}
        studentName={
          completeStudent ? studentFullName(completeStudent) : 'ученика'
        }
        onClose={() => setCompleteId(null)}
        onConfirm={handleComplete}
      />
      <MarkMissedModal
        open={missedId != null}
        studentName={
          missedStudent ? studentFullName(missedStudent) : 'ученика'
        }
        onClose={() => setMissedId(null)}
        onConfirm={handleMissed}
      />
      <StudentScheduleModal
        open={Boolean(scheduleStudent)}
        studentId={scheduleStudent?.id ?? null}
        studentName={
          scheduleStudent ? studentFullName(scheduleStudent) : 'Ученик'
        }
        onClose={() => setScheduleStudent(null)}
        onUnauthorized={handleUnauthorized}
      />
      <TeacherScheduleModal
        open={teacherScheduleOpen}
        students={students}
        onClose={() => {
          setTeacherScheduleOpen(false)
          setSection('students')
        }}
        onUnauthorized={handleUnauthorized}
      />
      <SummaryModal
        open={summaryOpen}
        students={students}
        onClose={() => {
          setSummaryOpen(false)
          setSection('students')
        }}
        onUnauthorized={handleUnauthorized}
      />
    </AppShell>
  )
}

function AlertCell({
  label,
  value,
  tone,
  onClick,
}: {
  label: string
  value: number
  tone: 'bad' | 'warn' | 'muted'
  onClick?: () => void
}) {
  const Comp = onClick ? 'button' : 'div'
  return (
    <Comp
      type={onClick ? 'button' : undefined}
      onClick={onClick}
      className={cn(
        'rounded-xl border border-border bg-card px-2 py-2.5 text-left',
        onClick && 'transition active:scale-[0.98]',
      )}
    >
      <p
        className={cn(
          'mt-1 line-clamp-2 text-[10px] font-medium leading-tight text-muted-foreground',
        )}
      >
        {label}
      </p>
      <p
        className={cn(
          'mt-1 text-lg font-semibold tabular-nums leading-none',
          tone === 'bad' && 'text-destructive',
          tone === 'warn' && 'text-[var(--warning)]',
          tone === 'muted' && 'text-foreground',
        )}
      >
        {value}
      </p>
    </Comp>
  )
}
