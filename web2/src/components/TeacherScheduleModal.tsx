import { useCallback, useEffect, useState } from 'react'
import { ChevronDown, Download } from 'lucide-react'
import { Modal } from '@/components/Modal'
import { TodayAgenda } from '@/components/TodayAgenda'
import { Button } from '@/components/ui/button'
import { scheduleApi } from '@/api'
import { AuthError } from '@/api/client'
import { cn, DAY_NAMES, formatTime } from '@/lib/utils'
import { exportWeekScheduleImage } from '@/lib/scheduleImage'
import type { ScheduleSlot, Student } from '@/types'

interface Props {
  open: boolean
  students: Student[]
  onClose: () => void
  onUnauthorized: () => void
  onComplete: (studentId: number) => void
  onMissed: (studentId: number) => void
}

interface DayGroup {
  day: number
  slots: ScheduleSlot[]
}

type Tab = 'today' | 'week'

export function TeacherScheduleModal({
  open,
  students,
  onClose,
  onUnauthorized,
  onComplete,
  onMissed,
}: Props) {
  const [tab, setTab] = useState<Tab>('today')
  const [agendaLabel, setAgendaLabel] = useState('Сегодня')
  const [days, setDays] = useState<DayGroup[]>([])
  const [loading, setLoading] = useState(false)
  const [expanded, setExpanded] = useState<number | null>(null)
  const [error, setError] = useState(false)

  const handleAgendaLabel = useCallback((label: string) => {
    setAgendaLabel(label)
  }, [])

  useEffect(() => {
    if (!open) return
    setTab('today')
    setAgendaLabel('Сегодня')
    setExpanded(null)
  }, [open])

  useEffect(() => {
    if (!open || tab !== 'week') return
    setLoading(true)
    setError(false)

    Promise.all(
      Array.from({ length: 7 }, (_, day) =>
        scheduleApi.getByDay(day).then((data) => ({
          day,
          slots: data.status && data.data ? data.data : [],
        })),
      ),
    )
      .then((result) => setDays(result))
      .catch((e) => {
        if (e instanceof AuthError) onUnauthorized()
        else setError(true)
      })
      .finally(() => setLoading(false))
  }, [open, tab, onUnauthorized])

  const dayOrder = [1, 2, 3, 4, 5, 6, 0]
  const ordered = dayOrder.map(
    (d) => days.find((x) => x.day === d) ?? { day: d, slots: [] },
  )
  const hasAny = ordered.some((d) => d.slots.length > 0)

  function studentName(id: number) {
    const s = students.find((st) => st.id === id)
    return s ? `${s.first_name} ${s.last_name || ''}`.trim() : `#${id}`
  }

  return (
    <Modal open={open} onClose={onClose} title="Неделя" size="lg">
      <div className="mb-4 grid grid-cols-2 gap-1 rounded-xl bg-muted p-1">
        <button
          type="button"
          onClick={() => setTab('today')}
          className={cn(
            'h-10 rounded-lg text-sm font-semibold transition',
            tab === 'today'
              ? 'bg-card text-foreground shadow-sm'
              : 'text-muted-foreground hover:text-foreground',
          )}
        >
          {agendaLabel}
        </button>
        <button
          type="button"
          onClick={() => setTab('week')}
          className={cn(
            'h-10 rounded-lg text-sm font-semibold transition',
            tab === 'week'
              ? 'bg-card text-foreground shadow-sm'
              : 'text-muted-foreground hover:text-foreground',
          )}
        >
          Вся неделя
        </button>
      </div>

      {tab === 'today' ? (
        <TodayAgenda
          students={students}
          active={open && tab === 'today'}
          onLabelChange={handleAgendaLabel}
          onComplete={onComplete}
          onMissed={onMissed}
          onUnauthorized={onUnauthorized}
        />
      ) : loading ? (
        <p className="py-8 text-center text-sm text-muted-foreground">
          Загрузка…
        </p>
      ) : error ? (
        <p className="py-8 text-center text-sm text-destructive">
          Не удалось загрузить
        </p>
      ) : !hasAny ? (
        <p className="rounded-xl border border-dashed border-border px-4 py-12 text-center text-sm leading-relaxed text-muted-foreground">
          Пока пусто.
          <br />
          Слоты задаются в карточке ученика → Расписание.
        </p>
      ) : (
        <div>
          <div className="mb-3 flex items-center justify-between gap-3">
            <p className="text-sm text-muted-foreground">
              Нажмите на день, чтобы раскрыть список
            </p>
            <Button
              type="button"
              variant="outline"
              size="sm"
              onClick={() => exportWeekScheduleImage(days, students)}
              className="gap-1.5"
            >
              <Download size={15} /> Скачать картинку
            </Button>
          </div>
          <div className="space-y-2">
          {ordered.map(({ day, slots }) => {
            const count = slots.length
            const sorted = [...slots].sort((a, b) =>
              (a.time_slot || '').localeCompare(b.time_slot || ''),
            )
            const isOpen = expanded === day
            return (
              <div
                key={day}
                className={cn(
                  'overflow-hidden rounded-xl border bg-card',
                  count === 0 && 'border-border',
                  count > 0 && count <= 3 && 'border-primary/25',
                  count > 3 && 'border-warning/40',
                )}
              >
                <button
                  type="button"
                  onClick={() => setExpanded(isOpen ? null : day)}
                  className="flex min-h-12 w-full items-center justify-between gap-3 px-4 py-3 text-left transition-colors hover:bg-muted/40 focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-ring/50"
                >
                  <span className="font-medium text-foreground">
                    {DAY_NAMES[day]}
                  </span>
                  <span className="flex items-center gap-2">
                    <span
                      className={cn(
                        'inline-flex min-w-7 items-center justify-center rounded-md px-2 py-0.5 text-xs font-semibold',
                        count === 0 && 'bg-muted text-muted-foreground',
                        count > 0 && count <= 3 && 'chip-ok',
                        count > 3 && 'chip-warn',
                      )}
                    >
                      {count}
                    </span>
                    <ChevronDown
                      size={16}
                      className={cn(
                        'text-muted-foreground transition-transform',
                        isOpen && 'rotate-180',
                      )}
                    />
                  </span>
                </button>
                {isOpen && (
                  <div className="animate-fade-in border-t border-border px-4 py-3">
                    {count === 0 ? (
                      <p className="text-sm text-muted-foreground">
                        На этот день записей нет
                      </p>
                    ) : (
                      <ul className="space-y-2">
                        {sorted.map((s, i) => (
                          <li
                            key={`${s.id ?? i}-${s.time_slot}`}
                            className="flex items-center gap-3 text-sm"
                          >
                            <span className="rounded-lg bg-primary/10 px-2 py-1 font-mono text-xs font-semibold tabular-nums text-primary">
                              {formatTime(s.time_slot)}
                            </span>
                            <span>{studentName(s.student_id)}</span>
                          </li>
                        ))}
                      </ul>
                    )}
                  </div>
                )}
              </div>
            )
          })}
          </div>
        </div>
      )}
    </Modal>
  )
}
