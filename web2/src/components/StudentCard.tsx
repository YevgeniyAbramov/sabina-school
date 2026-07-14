import {
  CalendarDays,
  Check,
  MoreHorizontal,
  Pencil,
  Trash2,
  UserX,
} from 'lucide-react'
import type { Student } from '@/types'
import { cn, formatNumber, studentFullName } from '@/lib/utils'
import { copy } from '@/lib/copy'
import { Button } from '@/components/ui/button'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu'

interface StudentCardProps {
  student: Student
  onComplete: (id: number) => void
  onMissed: (id: number) => void
  onSchedule: (id: number) => void
  onEdit: (id: number) => void
  onDelete: (id: number) => void
}

export function StudentCard({
  student,
  onComplete,
  onMissed,
  onSchedule,
  onEdit,
  onDelete,
}: StudentCardProps) {
  const completed = student.total_lessons - student.remaining_lessons
  const progress =
    student.total_lessons > 0
      ? Math.min(100, Math.round((completed / student.total_lessons) * 100))
      : 0
  const lowRemaining = student.remaining_lessons <= 1

  return (
    <article className="animate-fade-up flex flex-col rounded-2xl border border-border bg-card p-3.5 shadow-[0_1px_2px_rgba(28,31,42,0.04)] sm:p-5">
      {/* Header */}
      <div className="flex items-start gap-2">
        <div className="min-w-0 flex-1">
          <div className="flex items-start justify-between gap-2">
            <h3 className="min-w-0 flex-1 text-[15px] font-semibold leading-snug tracking-tight text-foreground">
              {studentFullName(student)}
            </h3>
            <DropdownMenu>
              <DropdownMenuTrigger asChild>
                <Button
                  type="button"
                  variant="ghost"
                  size="icon"
                  className="-mr-1 -mt-1 size-8 shrink-0 text-muted-foreground"
                  aria-label="Ещё"
                >
                  <MoreHorizontal size={18} />
                </Button>
              </DropdownMenuTrigger>
              <DropdownMenuContent align="end" className="w-44">
                <DropdownMenuItem onClick={() => onEdit(student.id)}>
                  <Pencil size={14} /> Изменить
                </DropdownMenuItem>
                <DropdownMenuItem onClick={() => onSchedule(student.id)}>
                  <CalendarDays size={14} /> Расписание
                </DropdownMenuItem>
                <DropdownMenuSeparator />
                <DropdownMenuItem
                  className="text-destructive focus:text-destructive"
                  onClick={() => onDelete(student.id)}
                >
                  <Trash2 size={14} /> Удалить
                </DropdownMenuItem>
              </DropdownMenuContent>
            </DropdownMenu>
          </div>

          <div className="mt-1.5 flex flex-wrap items-center gap-1.5">
            <span
              className={cn(
                'rounded-md px-1.5 py-0.5 text-[11px] font-medium',
                student.is_paid ? 'chip-ok' : 'chip-bad',
              )}
            >
              {student.is_paid ? copy.paid : copy.unpaid}
            </span>
            {student.missed_classes > 0 && (
              <span className="rounded-md bg-muted px-1.5 py-0.5 text-[11px] font-medium text-muted-foreground">
                Пропусков: {student.missed_classes}
              </span>
            )}
            {lowRemaining && student.remaining_lessons === 1 && (
              <span className="chip-warn rounded-md px-1.5 py-0.5 text-[11px] font-medium">
                {copy.endingSoon}
              </span>
            )}
            {student.remaining_lessons <= 0 && (
              <span className="rounded-md bg-muted px-1.5 py-0.5 text-[11px] font-medium text-muted-foreground">
                {copy.finished}
              </span>
            )}
          </div>
        </div>
      </div>

      {/* Compact stats */}
      <div className="mt-3.5 grid grid-cols-3 overflow-hidden rounded-xl bg-muted/70">
        <Metric label="Прошли" value={`${completed}/${student.total_lessons}`} />
        <Metric
          label="Осталось"
          value={String(student.remaining_lessons)}
          tone={lowRemaining ? 'bad' : 'default'}
          border
        />
        <Metric
          label="Сумма"
          value={`${formatNumber(student.paid_amount)} ₸`}
          border
        />
      </div>

      {/* Progress */}
      <div className="mt-3">
        <div className="h-1 overflow-hidden rounded-full bg-muted">
          <div
            className="h-full rounded-full bg-primary/80 transition-[width]"
            style={{ width: `${progress}%` }}
          />
        </div>
      </div>

      {/* Actions */}
      <div className="mt-3.5 grid grid-cols-2 gap-2">
        <Button
          type="button"
          disabled={student.remaining_lessons <= 0}
          onClick={() => onComplete(student.id)}
          className="h-11 rounded-xl text-[13px] font-semibold"
        >
          <Check size={16} /> Провести
        </Button>
        <Button
          type="button"
          variant="secondary"
          onClick={() => onMissed(student.id)}
          className="h-11 rounded-xl text-[13px] font-semibold"
        >
          <UserX size={16} /> Пропуск
        </Button>
      </div>
    </article>
  )
}

function Metric({
  label,
  value,
  tone = 'default',
  border = false,
}: {
  label: string
  value: string
  tone?: 'default' | 'bad'
  border?: boolean
}) {
  return (
    <div
      className={cn(
        'px-2.5 py-2.5 text-center',
        border && 'border-l border-border/80',
      )}
    >
      <p className="text-[10px] font-medium text-muted-foreground">{label}</p>
      <p
        className={cn(
          'mt-0.5 truncate text-[13px] font-semibold tabular-nums sm:text-sm',
          tone === 'bad' ? 'text-destructive' : 'text-foreground',
        )}
      >
        {value}
      </p>
    </div>
  )
}
