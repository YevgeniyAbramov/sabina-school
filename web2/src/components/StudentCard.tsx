import {
  CalendarDays,
  Check,
  MoreHorizontal,
  Pencil,
  Plus,
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
  onRenew: (id: number) => void
  onEdit: (id: number) => void
  onDelete: (id: number) => void
}

export function StudentCard({
  student,
  onComplete,
  onMissed,
  onSchedule,
  onRenew,
  onEdit,
  onDelete,
}: StudentCardProps) {
  const completed = student.total_lessons - student.remaining_lessons
  const progress =
    student.total_lessons > 0
      ? Math.min(100, Math.round((completed / student.total_lessons) * 100))
      : 0
  const lowRemaining = student.remaining_lessons <= 1

  // Soft status accent: green → amber → rose by progress
  const statusTone =
    student.total_lessons === 0
      ? null
      : progress >= 90
        ? 'danger'
        : progress >= 65
          ? 'warn'
          : 'ok'

  const accent =
    statusTone === 'danger'
      ? {
          bar: 'var(--destructive)',
          glow: 'color-mix(in srgb, var(--destructive) 18%, transparent)',
          wash: 'color-mix(in srgb, var(--danger-soft) 55%, transparent)',
        }
      : statusTone === 'warn'
        ? {
            bar: 'var(--warning)',
            glow: 'color-mix(in srgb, var(--warning) 16%, transparent)',
            wash: 'color-mix(in srgb, var(--warning-soft) 55%, transparent)',
          }
        : statusTone === 'ok'
          ? {
              bar: 'var(--success)',
              glow: 'color-mix(in srgb, var(--success) 14%, transparent)',
              wash: 'color-mix(in srgb, var(--success-soft) 50%, transparent)',
            }
          : null

  return (
    <article
      className={cn(
        'animate-fade-up relative flex flex-col overflow-hidden rounded-2xl border border-border bg-card p-3.5 sm:p-5',
        'transition-[box-shadow,border-color] duration-500',
        'shadow-[0_1px_2px_rgba(28,31,42,0.04)]',
      )}
      style={
        accent
          ? {
              boxShadow: `0 1px 2px rgba(28,31,42,0.04), 0 0 0 1px color-mix(in srgb, ${accent.bar} 10%, transparent), 0 8px 24px -12px ${accent.glow}`,
            }
          : undefined
      }
    >
      {accent && (
        <>
          {/* Soft left wash */}
          <div
            aria-hidden
            className="pointer-events-none absolute inset-y-0 left-0 w-16 opacity-80"
            style={{
              background: `linear-gradient(90deg, ${accent.wash} 0%, transparent 100%)`,
            }}
          />
          {/* Accent rail */}
          <div
            aria-hidden
            className="pointer-events-none absolute inset-y-3 left-0 w-[3px] rounded-full"
            style={{
              background: `linear-gradient(180deg, color-mix(in srgb, ${accent.bar} 35%, white) 0%, ${accent.bar} 45%, color-mix(in srgb, ${accent.bar} 55%, transparent) 100%)`,
              boxShadow: `0 0 12px ${accent.glow}`,
            }}
          />
        </>
      )}

      <div className="relative flex items-start gap-2">
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
                <DropdownMenuItem onClick={() => onRenew(student.id)}>
                  <Plus size={14} /> Продлить
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
            <span className={cn('chip', student.is_paid ? 'chip-ok' : 'chip-bad')}>
              {student.is_paid ? copy.paid : copy.unpaid}
            </span>
            {student.missed_classes > 0 && (
              <span className="chip chip-soft">
                Пропусков: {student.missed_classes}
              </span>
            )}
            {lowRemaining && student.remaining_lessons === 1 && (
              <span className="chip chip-warn">{copy.endingSoon}</span>
            )}
            {student.remaining_lessons <= 0 && (
              <span className="chip chip-soft">{copy.finished}</span>
            )}
          </div>
        </div>
      </div>

      <div className="relative mt-3.5 grid grid-cols-3 overflow-hidden rounded-xl bg-muted/70">
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

      <div className="relative mt-3">
        <div className="h-1 overflow-hidden rounded-full bg-muted">
          <div
            className="h-full rounded-full bg-primary/80 transition-[width]"
            style={{ width: `${progress}%` }}
          />
        </div>
      </div>

      <div className="relative mt-3.5 grid grid-cols-2 gap-2">
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
