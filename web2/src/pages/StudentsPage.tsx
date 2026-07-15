import { useCallback, useEffect, useMemo, useState } from "react";
import { Navigate, useNavigate, useSearchParams } from "react-router-dom";
import {
  BarChart3,
  CalendarRange,
  History,
  LogOut,
  Plus,
  Search,
  Users,
  UserRound,
  X,
} from "lucide-react";
import { studentsApi } from "@/api";
import { AuthError } from "@/api/client";
import { useAuth } from "@/context/AuthContext";
import { useToast } from "@/context/ToastContext";
import { AppShell, NavItem } from "@/components/AppShell";
import { StudentCard } from "@/components/StudentCard";
import { AddStudentModal } from "@/components/AddStudentModal";
import { EditStudentModal } from "@/components/EditStudentModal";
import { DeleteConfirmModal } from "@/components/DeleteConfirmModal";
import { CompleteLessonModal } from "@/components/CompleteLessonModal";
import { MarkMissedModal } from "@/components/MarkMissedModal";
import { RenewLessonsModal } from "@/components/RenewLessonsModal";
import { StudentScheduleModal } from "@/components/StudentScheduleModal";
import { TeacherScheduleModal } from "@/components/TeacherScheduleModal";
import { SummaryModal } from "@/components/SummaryModal";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { cn, pluralStudents, studentFullName } from "@/lib/utils";
import { copy } from "@/lib/copy";
import type { Student, StudentFilter, StudentInput } from "@/types";

type Section = "students" | "schedule" | "summary";

export function StudentsPage() {
  const { isAuthenticated, teacherName, logout } = useAuth();
  const { show } = useToast();
  const navigate = useNavigate();
  const [searchParams, setSearchParams] = useSearchParams();

  const [students, setStudents] = useState<Student[]>([]);
  const [filter, setFilter] = useState<StudentFilter>("all");
  const [query, setQuery] = useState("");
  const [loading, setLoading] = useState(true);
  const [section, setSection] = useState<Section>("students");

  const [addOpen, setAddOpen] = useState(false);
  const [editStudent, setEditStudent] = useState<Student | null>(null);
  const [deleteId, setDeleteId] = useState<number | null>(null);
  const [completeId, setCompleteId] = useState<number | null>(null);
  const [missedId, setMissedId] = useState<number | null>(null);
  const [renewId, setRenewId] = useState<number | null>(null);
  const [scheduleStudent, setScheduleStudent] = useState<Student | null>(null);
  const [teacherScheduleOpen, setTeacherScheduleOpen] = useState(false);
  const [summaryOpen, setSummaryOpen] = useState(false);

  const handleUnauthorized = useCallback(() => {
    logout();
    navigate("/login", { replace: true });
  }, [logout, navigate]);

  const loadStudents = useCallback(async () => {
    try {
      const data = await studentsApi.list();
      if (!data.status) {
        show("Не удалось загрузить учеников", "danger");
        return;
      }
      setStudents(data.data || []);
    } catch (e) {
      if (e instanceof AuthError) handleUnauthorized();
      else show("Нет связи с сервером", "danger");
    } finally {
      setLoading(false);
    }
  }, [handleUnauthorized, show]);

  useEffect(() => {
    if (isAuthenticated) void loadStudents();
  }, [isAuthenticated, loadStudents]);

  useEffect(() => {
    const open = searchParams.get("open");
    if (!open) return;
    if (open === "schedule") setTeacherScheduleOpen(true);
    if (open === "summary") setSummaryOpen(true);
    if (open === "new") setAddOpen(true);
    setSearchParams({}, { replace: true });
  }, [searchParams, setSearchParams]);

  const filtered = useMemo(() => {
    let result = [...students];
    if (filter === "paid") result = result.filter((s) => s.is_paid);
    else if (filter === "unpaid") result = result.filter((s) => !s.is_paid);
    else if (filter === "endingSoon")
      result = result.filter((s) => s.remaining_lessons === 1);
    else if (filter === "finished")
      result = result.filter((s) => s.remaining_lessons <= 0);

    const q = query.trim().toLowerCase();
    if (q) {
      result = result.filter((s) => {
        const haystack = [s.last_name, s.first_name, s.middle_name]
          .filter(Boolean)
          .join(" ")
          .toLowerCase();
        return haystack.includes(q);
      });
    }

    result.sort(
      (a, b) =>
        new Date(b.created_at).getTime() - new Date(a.created_at).getTime(),
    );
    return result;
  }, [students, filter, query]);

  const unpaidCount = useMemo(
    () => students.filter((s) => !s.is_paid).length,
    [students],
  );

  // Только «скоро кончится»: ровно 1 урок (0 = уже закончился, не сюда)
  const endingSoonCount = useMemo(
    () => students.filter((s) => s.remaining_lessons === 1).length,
    [students],
  );

  const finishedCount = useMemo(
    () => students.filter((s) => s.remaining_lessons <= 0).length,
    [students],
  );

  const completeStudent = useMemo(
    () => students.find((s) => s.id === completeId) ?? null,
    [students, completeId],
  );

  const missedStudent = useMemo(
    () => students.find((s) => s.id === missedId) ?? null,
    [students, missedId],
  );

  const renewStudent = useMemo(
    () => students.find((s) => s.id === renewId) ?? null,
    [students, renewId],
  );

  function toggleFilter(next: StudentFilter) {
    setFilter((prev) => (prev === next ? "all" : next));
  }

  const tabsValue: "all" | "paid" | "unpaid" =
    filter === "paid" || filter === "unpaid" ? filter : "all";

  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }

  async function handleAdd(student: StudentInput) {
    try {
      const data = await studentsApi.create(student);
      if (data.status) {
        await loadStudents();
        return;
      }
      show(data.message || "Не удалось добавить", "danger");
    } catch (e) {
      if (e instanceof AuthError) handleUnauthorized();
      else show("Не удалось добавить ученика", "danger");
    }
    throw new Error("add-failed");
  }

  async function handleEdit(id: number, student: StudentInput) {
    try {
      const data = await studentsApi.update(id, student);
      if (data.status) {
        await loadStudents();
        return;
      }
      show(data.message || "Не удалось сохранить", "danger");
    } catch (e) {
      if (e instanceof AuthError) handleUnauthorized();
      else show("Не удалось обновить данные", "danger");
    }
    throw new Error("edit-failed");
  }

  async function handleDelete() {
    if (deleteId == null) return;
    try {
      const data = await studentsApi.remove(deleteId);
      if (data.status) await loadStudents();
      else show(data.message || "Не удалось удалить", "danger");
    } catch (e) {
      if (e instanceof AuthError) handleUnauthorized();
      else show("Не удалось удалить ученика", "danger");
    }
  }

  async function handleComplete() {
    if (completeId == null) return;
    try {
      const data = await studentsApi.completeLesson(completeId);
      if (data.status) await loadStudents();
      else show(data.message || "Ошибка", "danger");
    } catch (e) {
      if (e instanceof AuthError) handleUnauthorized();
      else show("Не удалось отметить урок", "danger");
    }
  }

  async function handleMissed() {
    if (missedId == null) return;
    try {
      const data = await studentsApi.markMissed(missedId);
      if (data.status) await loadStudents();
      else show(data.message || "Ошибка", "danger");
    } catch (e) {
      if (e instanceof AuthError) handleUnauthorized();
      else show("Не удалось отметить пропуск", "danger");
    }
  }

  async function handleRenew(payload: {
    lessons: number;
    paymentAmount: number;
  }) {
    if (!renewStudent) return;
    const s = renewStudent;
    // Новый цикл: 0 пройдено из N, сумма = оплата за этот период
    const next: StudentInput = {
      first_name: s.first_name,
      last_name: s.last_name || "",
      middle_name: s.middle_name || "",
      total_lessons: payload.lessons,
      remaining_lessons: payload.lessons,
      paid_amount: payload.paymentAmount,
      missed_classes: s.missed_classes,
      is_paid: true,
    };
    try {
      const data = await studentsApi.update(s.id, next);
      if (data.status) {
        await loadStudents();
        show(`Готово: 0 из ${payload.lessons}`, "success");
        return;
      }
      show(data.message || "Не удалось продлить", "danger");
    } catch (e) {
      if (e instanceof AuthError) handleUnauthorized();
      else show("Не удалось продлить уроки", "danger");
    }
    throw new Error("renew-failed");
  }

  async function openEdit(id: number) {
    try {
      const data = await studentsApi.get(id);
      if (!data.status || !data.data) {
        show("Ученик не найден", "danger");
        return;
      }
      setEditStudent(data.data);
    } catch (e) {
      if (e instanceof AuthError) handleUnauthorized();
      else show("Не удалось загрузить данные", "danger");
    }
  }

  function openSection(next: Section) {
    setSection(next);
    if (next === "schedule") setTeacherScheduleOpen(true);
    if (next === "summary") setSummaryOpen(true);
    if (next === "students") {
      setTeacherScheduleOpen(false);
      setSummaryOpen(false);
    }
  }

  const brand = (
    <div className="flex items-center gap-2">
      <div className="flex size-8 items-center justify-center rounded-lg bg-primary text-primary-foreground lg:size-9 lg:rounded-xl">
        <svg
          viewBox="0 0 24 24"
          className="h-3.5 w-3.5 fill-current lg:h-4 lg:w-4"
          aria-hidden
        >
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
  );

  const sideNav = (
    <>
      <NavItem
        active={section === "students" && !teacherScheduleOpen && !summaryOpen}
        icon={<Users size={18} />}
        label="Ученики"
        onClick={() => openSection("students")}
      />
      <NavItem
        icon={<History size={18} />}
        label="История"
        onClick={() => navigate("/history")}
      />
      <NavItem
        active={teacherScheduleOpen}
        icon={<CalendarRange size={18} />}
        label="Расписание"
        onClick={() => openSection("schedule")}
      />
      <NavItem
        active={summaryOpen}
        icon={<BarChart3 size={18} />}
        label="Итоги"
        onClick={() => openSection("summary")}
      />
    </>
  );

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
            {teacherName || "Профиль"}
          </span>
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end" className="w-52">
        <DropdownMenuLabel className="font-normal">
          <p className="text-sm font-semibold">
            {teacherName || "Преподаватель"}
          </p>
          <p className="text-xs text-muted-foreground">CON ANIMA</p>
        </DropdownMenuLabel>
        <DropdownMenuSeparator />
        <DropdownMenuItem
          className="text-destructive focus:text-destructive"
          onClick={() => {
            logout();
            navigate("/login");
          }}
        >
          <LogOut size={16} />
          Выйти
        </DropdownMenuItem>
      </DropdownMenuContent>
    </DropdownMenu>
  );

  return (
    <AppShell
      brand={brand}
      nav={sideNav}
      topRight={profileMenu}
      mobileCols={5}
      sidebarFooter={
        <p className="px-1 text-[11px] leading-relaxed text-muted-foreground">
          {teacherName
            ? `${teacherName}, хорошей смены`
            : "Кабинет преподавателя"}
        </p>
      }
      mobileNav={
        <>
          <NavItem
            variant="bottom"
            active={
              section === "students" && !teacherScheduleOpen && !summaryOpen
            }
            icon={<Users size={18} />}
            label="Ученики"
            onClick={() => openSection("students")}
          />
          <NavItem
            variant="bottom"
            icon={<History size={18} />}
            label="История"
            onClick={() => navigate("/history")}
          />
          <NavItem
            variant="bottom"
            active={teacherScheduleOpen}
            icon={<CalendarRange size={18} />}
            label="Неделя"
            onClick={() => openSection("schedule")}
          />
          <NavItem
            variant="bottom"
            active={summaryOpen}
            icon={<BarChart3 size={18} />}
            label="Итоги"
            onClick={() => openSection("summary")}
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
                {query.trim() || filter !== "all"
                  ? `${filtered.length} из ${students.length}`
                  : `${students.length} ${pluralStudents(students.length)}`}
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
              <div className="flex gap-2 overflow-x-auto pb-0.5 sm:flex-wrap [-ms-overflow-style:none] [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
                {unpaidCount > 0 && (
                  <AlertChip
                    value={unpaidCount}
                    label={copy.unpaid}
                    tone="bad"
                    active={filter === "unpaid"}
                    onClick={() => toggleFilter("unpaid")}
                  />
                )}
                {endingSoonCount > 0 && (
                  <AlertChip
                    value={endingSoonCount}
                    label={copy.endingSoon}
                    tone="warn"
                    active={filter === "endingSoon"}
                    onClick={() => toggleFilter("endingSoon")}
                  />
                )}
                {finishedCount > 0 && (
                  <AlertChip
                    value={finishedCount}
                    label={copy.finished}
                    tone="muted"
                    active={filter === "finished"}
                    onClick={() => toggleFilter("finished")}
                  />
                )}
              </div>
            )}

          {!loading && students.length > 0 && (
            <div className="relative">
              <Search
                size={16}
                className="pointer-events-none absolute top-1/2 left-3 -translate-y-1/2 text-muted-foreground"
                aria-hidden
              />
              <Input
                type="text"
                value={query}
                onChange={(e) => setQuery(e.target.value)}
                placeholder={copy.searchPlaceholder}
                aria-label={copy.searchPlaceholder}
                autoComplete="off"
                className="h-11 rounded-xl border-border bg-card pr-10 pl-9 text-sm shadow-sm"
              />
              {query && (
                <button
                  type="button"
                  onClick={() => setQuery("")}
                  className="absolute top-1/2 right-2.5 flex size-7 -translate-y-1/2 items-center justify-center rounded-lg text-muted-foreground transition hover:bg-muted hover:text-foreground"
                  aria-label={copy.searchClear}
                >
                  <X size={14} />
                </button>
              )}
            </div>
          )}

          <Tabs
            value={tabsValue}
            onValueChange={(v) => setFilter(v as StudentFilter)}
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
              <div key={i} className="h-44 animate-pulse rounded-2xl bg-card" />
            ))}
          </div>
        ) : filtered.length === 0 ? (
          <div className="rounded-2xl border border-dashed border-border bg-card px-5 py-12 text-center sm:px-6 sm:py-16">
            <p className="text-base font-semibold text-foreground sm:text-lg">
              {students.length === 0
                ? "Пока никого нет"
                : query.trim()
                  ? copy.searchEmpty
                  : copy.filterEmpty}
            </p>
            <p className="mx-auto mt-2 max-w-sm text-sm text-muted-foreground">
              {students.length === 0
                ? "Добавьте первого ученика — всё остальное подтянется"
                : query.trim()
                  ? copy.searchEmptyHint
                  : copy.filterEmptyHint}
            </p>
            <Button
              type="button"
              onClick={() => {
                if (students.length === 0) {
                  setAddOpen(true);
                  return;
                }
                if (query.trim()) {
                  setQuery("");
                  return;
                }
                setFilter("all");
              }}
              className="mt-5 h-11 rounded-xl font-semibold"
            >
              {students.length === 0 ? (
                <>
                  <Plus size={16} /> Добавить ученика
                </>
              ) : query.trim() ? (
                copy.searchClear
              ) : (
                copy.filterShowAll
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
                  onRenew={setRenewId}
                  onSchedule={(id) => {
                    const s = students.find((x) => x.id === id) || null;
                    setScheduleStudent(s);
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
          completeStudent ? studentFullName(completeStudent) : "ученика"
        }
        onClose={() => setCompleteId(null)}
        onConfirm={handleComplete}
      />
      <MarkMissedModal
        open={missedId != null}
        studentName={missedStudent ? studentFullName(missedStudent) : "ученика"}
        onClose={() => setMissedId(null)}
        onConfirm={handleMissed}
      />
      <RenewLessonsModal
        open={renewId != null}
        student={renewStudent}
        onClose={() => setRenewId(null)}
        onConfirm={handleRenew}
      />
      <StudentScheduleModal
        open={Boolean(scheduleStudent)}
        studentId={scheduleStudent?.id ?? null}
        studentName={
          scheduleStudent ? studentFullName(scheduleStudent) : "Ученик"
        }
        onClose={() => setScheduleStudent(null)}
        onUnauthorized={handleUnauthorized}
      />
      <TeacherScheduleModal
        open={teacherScheduleOpen}
        students={students}
        onClose={() => {
          setTeacherScheduleOpen(false);
          setSection("students");
        }}
        onUnauthorized={handleUnauthorized}
        onComplete={setCompleteId}
        onMissed={setMissedId}
      />
      <SummaryModal
        open={summaryOpen}
        students={students}
        onClose={() => {
          setSummaryOpen(false);
          setSection("students");
        }}
        onUnauthorized={handleUnauthorized}
      />
    </AppShell>
  );
}

function AlertChip({
  label,
  value,
  tone,
  active,
  onClick,
}: {
  label: string;
  value: number;
  tone: "bad" | "warn" | "muted";
  active?: boolean;
  onClick?: () => void;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      aria-pressed={Boolean(active)}
      className={cn(
        "flex min-w-[5.5rem] flex-1 flex-col items-start gap-0.5 rounded-xl border px-2.5 py-2 text-left transition sm:min-w-[6.25rem] sm:flex-none",
        "active:scale-[0.98] focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-ring/40",
        tone === "bad" &&
          (active
            ? "border-destructive/30 bg-destructive text-white shadow-sm"
            : "border-[color-mix(in_srgb,var(--destructive)_14%,transparent)] bg-[color-mix(in_srgb,var(--danger-soft)_80%,white)] text-destructive hover:bg-[color-mix(in_srgb,var(--danger-soft)_95%,white)]"),
        tone === "warn" &&
          (active
            ? "border-[color-mix(in_srgb,var(--warning)_30%,transparent)] bg-[var(--warning)] text-white shadow-sm"
            : "border-[color-mix(in_srgb,var(--warning)_14%,transparent)] bg-[color-mix(in_srgb,var(--warning-soft)_80%,white)] text-[var(--warning)] hover:bg-[color-mix(in_srgb,var(--warning-soft)_95%,white)]"),
        tone === "muted" &&
          (active
            ? "border-foreground/20 bg-foreground text-background shadow-sm"
            : "border-border bg-card text-muted-foreground hover:bg-muted/60 hover:text-foreground"),
      )}
    >
      <span
        className={cn(
          "text-[1.1rem] font-semibold tabular-nums leading-none tracking-tight sm:text-[1.2rem]",
          !active && tone === "muted" && "text-foreground",
        )}
      >
        {value}
      </span>
      <span
        className={cn(
          "text-[10px] font-medium leading-tight sm:text-[11px]",
          active ? "text-white/85" : "text-current opacity-80",
        )}
      >
        {label}
      </span>
    </button>
  );
}
