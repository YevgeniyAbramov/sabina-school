import { useCallback, useEffect, useMemo, useState } from 'react'
import { Check, UserX } from 'lucide-react'
import { scheduleApi } from '@/api'
import { AuthError } from '@/api/client'
import { Button } from '@/components/ui/button'
import {
  cn,
  DAY_SHORT,
  formatTime,
  normalizeTimeSlot,
  studentFullName,
} from '@/lib/utils'
import type { ScheduleSlot, Student } from '@/types'

interface Props {
  students: Student[]
  /** Загружать только когда экран/вкладка активна */
  active?: boolean
  /** Подпись вкладки: «Сегодня» или день недели */
  onLabelChange?: (label: string) => void
  onComplete: (studentId: number) => void
  onMissed: (studentId: number) => void
  onUnauthorized: () => void
}

interface AgendaDay {
  day: number
  isToday: boolean
  slots: ScheduleSlot[]
}

function nowMinutes() {
  const n = new Date()
  return n.getHours() * 60 + n.getMinutes()
}

function timeToMinutes(slot: string) {
  const [h, m] = normalizeTimeSlot(slot).split(':').map(Number)
  return (h || 0) * 60 + (m || 0)
}

export function TodayAgenda({
  students,
  active = true,
  onLabelChange,
  onComplete,
  onMissed,
  onUnauthorized,
}: Props) {
  const [agenda, setAgenda] = useState<AgendaDay | null>(null)
  const [loading, setLoading] = useState(true)

  const load = useCallback(async () => {
    const today = new Date().getDay()
    try {
      for (let offset = 0; offset < 7; offset++) {
        const day = (today + offset) % 7
        const data = await scheduleApi.getByDay(day)
        const slots =
          data.status && data.data
            ? [...data.data].sort((a, b) =>
                normalizeTimeSlot(a.time_slot).localeCompare(
                  normalizeTimeSlot(b.time_slot),
                ),
              )
            : []
        if (slots.length > 0) {
          const next = { day, isToday: offset === 0, slots }
          setAgenda(next)
          onLabelChange?.(offset === 0 ? 'Сегодня' : DAY_SHORT[day])
          return
        }
      }
      setAgenda(null)
      onLabelChange?.('Сегодня')
    } catch (e) {
      if (e instanceof AuthError) onUnauthorized()
      setAgenda(null)
      onLabelChange?.('Сегодня')
    } finally {
      setLoading(false)
    }
  }, [onUnauthorized, onLabelChange])

  useEffect(() => {
    if (!active) return
    setLoading(true)
    void load()
  }, [active, load])

  const studentById = useMemo(() => {
    const map = new Map<number, Student>()
    for (const s of students) map.set(s.id, s)
    return map
  }, [students])

  if (loading) {
    return (
      <p className="py-10 text-center text-sm text-muted-foreground">
        Загрузка…
      </p>
    )
  }

  if (!agenda) {
    return (
      <p className="rounded-xl border border-dashed border-border px-4 py-12 text-center text-sm leading-relaxed text-muted-foreground">
        На этой неделе слотов нет.
        <br />
        Добавьте время в карточке ученика.
      </p>
    )
  }

  const now = agenda.isToday ? nowMinutes() : null

  return (
    <ul className="overflow-hidden rounded-xl border border-border">
      {agenda.slots.map((slot, idx) => {
        const student = studentById.get(slot.student_id)
        const name = student
          ? studentFullName(student)
          : `Ученик #${slot.student_id}`
        const minutes = timeToMinutes(slot.time_slot)
        const past = now != null && minutes < now - 20
        const soon =
          now != null && !past && minutes <= now + 45 && minutes >= now - 20
        const canComplete = student ? student.remaining_lessons > 0 : false

        return (
          <li
            key={`${slot.id ?? idx}-${slot.student_id}-${slot.time_slot}`}
            className={cn(
              'flex items-center gap-3 bg-card px-3.5 py-3',
              idx > 0 && 'border-t border-border',
            )}
          >
            <div className="w-12 shrink-0">
              <p
                className={cn(
                  'text-sm font-semibold tabular-nums',
                  past && 'text-muted-foreground',
                  soon && 'text-primary',
                  !past && !soon && 'text-foreground',
                )}
              >
                {formatTime(slot.time_slot)}
              </p>
            </div>

            <div className="min-w-0 flex-1">
              <p className="truncate text-sm font-semibold text-foreground">
                {name}
              </p>
              {student && student.remaining_lessons <= 1 && (
                <p className="mt-0.5 text-xs text-muted-foreground">
                  {student.remaining_lessons <= 0
                    ? 'Уроки закончились'
                    : 'Остался 1 урок'}
                </p>
              )}
            </div>

            {student && (
              <div className="flex shrink-0 gap-1.5">
                <Button
                  type="button"
                  size="icon"
                  disabled={!canComplete}
                  aria-label="Урок проведён"
                  onClick={() => onComplete(student.id)}
                  className="size-9 rounded-xl shadow-sm"
                >
                  <Check size={16} strokeWidth={2.5} />
                </Button>
                <Button
                  type="button"
                  size="icon"
                  variant="outline"
                  aria-label="Пропуск"
                  onClick={() => onMissed(student.id)}
                  className="size-9 rounded-xl border-border bg-background shadow-sm hover:bg-muted"
                >
                  <UserX size={16} strokeWidth={2.25} />
                </Button>
              </div>
            )}
          </li>
        )
      })}
    </ul>
  )
}
