import { useEffect, useMemo, useState } from 'react'
import { Plus, Trash2 } from 'lucide-react'
import { Modal } from '@/components/Modal'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { scheduleApi } from '@/api'
import { useToast } from '@/context/ToastContext'
import { AuthError } from '@/api/client'
import {
  cn,
  DAY_NAMES,
  DAY_SHORT,
  formatTime,
  normalizeTimeSlot,
} from '@/lib/utils'
import type { ScheduleSlotInput } from '@/types'

const WEEK_DAYS = [1, 2, 3, 4, 5, 6, 0] as const

interface Props {
  open: boolean
  studentId: number | null
  studentName: string
  onClose: () => void
  onUnauthorized: () => void
}

function dayOrder(d: number) {
  return d === 0 ? 7 : d
}

export function StudentScheduleModal({
  open,
  studentId,
  studentName,
  onClose,
  onUnauthorized,
}: Props) {
  const { show } = useToast()
  const [slots, setSlots] = useState<ScheduleSlotInput[]>([])
  const [loading, setLoading] = useState(false)
  const [saving, setSaving] = useState(false)
  const [selectedDay, setSelectedDay] = useState<number>(1)
  const [time, setTime] = useState('10:00')
  const [justAddedKey, setJustAddedKey] = useState<string | null>(null)

  useEffect(() => {
    if (!open || !studentId) return
    setSelectedDay(1)
    setTime('10:00')
    setLoading(true)
    scheduleApi
      .getByStudent(studentId)
      .then((data) => {
        if (data.status && data.data) {
          setSlots(
            data.data.map((s) => ({
              day_of_week: s.day_of_week,
              time_slot: normalizeTimeSlot(s.time_slot),
            })),
          )
        } else {
          setSlots([])
        }
      })
      .catch((e) => {
        if (e instanceof AuthError) onUnauthorized()
        else {
          setSlots([])
          show('Не удалось загрузить расписание', 'danger')
        }
      })
      .finally(() => setLoading(false))
  }, [open, studentId, onUnauthorized, show])

  const sortedSlots = useMemo(
    () =>
      [...slots].sort((a, b) => {
        const byDay = dayOrder(a.day_of_week) - dayOrder(b.day_of_week)
        if (byDay !== 0) return byDay
        return normalizeTimeSlot(a.time_slot).localeCompare(
          normalizeTimeSlot(b.time_slot),
        )
      }),
    [slots],
  )

  async function persist(
    next: ScheduleSlotInput[],
    opts?: { close?: boolean; successMessage?: string; highlightKey?: string },
  ) {
    if (!studentId || saving) return false
    setSaving(true)
    try {
      const data = await scheduleApi.replaceForStudent(studentId, next)
      if (data.status) {
        setSlots(next)
        if (opts?.highlightKey) {
          setJustAddedKey(opts.highlightKey)
          window.setTimeout(() => setJustAddedKey(null), 1600)
        }
        if (opts?.successMessage) show(opts.successMessage, 'success')
        if (opts?.close) onClose()
        return true
      }
      show(data.message || 'Не удалось сохранить', 'danger')
      return false
    } catch (e) {
      if (e instanceof AuthError) onUnauthorized()
      else show('Не удалось сохранить расписание', 'danger')
      return false
    } finally {
      setSaving(false)
    }
  }

  function addSlot() {
    const timeSlot = normalizeTimeSlot(time)
    const exists = slots.some(
      (s) =>
        Number(s.day_of_week) === Number(selectedDay) &&
        normalizeTimeSlot(s.time_slot) === timeSlot,
    )
    if (exists) {
      show('Это время уже есть', 'danger')
      return
    }
    const next = [...slots, { day_of_week: selectedDay, time_slot: timeSlot }]
    const label = `${DAY_SHORT[selectedDay]} ${formatTime(timeSlot)}`
    void persist(next, {
      successMessage: `Добавлено: ${label}`,
      highlightKey: `${selectedDay}-${timeSlot}`,
    })
  }

  function removeSlot(slot: ScheduleSlotInput) {
    const key = `${slot.day_of_week}-${normalizeTimeSlot(slot.time_slot)}`
    const next = slots.filter(
      (s) =>
        `${s.day_of_week}-${normalizeTimeSlot(s.time_slot)}` !== key,
    )
    const label = `${DAY_SHORT[slot.day_of_week]} ${formatTime(slot.time_slot)}`
    void persist(next, { successMessage: `Удалено: ${label}` })
  }

  return (
    <Modal
      open={open}
      onClose={onClose}
      title="Расписание"
      size="lg"
      footer={
        <Button
          type="button"
          className="h-11 w-full font-semibold sm:w-auto"
          disabled={saving}
          onClick={() => void persist(slots, { close: true })}
        >
          Готово
        </Button>
      }
    >
      <div className="flex flex-col gap-4">
        <p className="text-sm text-muted-foreground">
          <span className="font-medium text-foreground">{studentName}</span>
        </p>

        {/* Список сверху — сразу видно, что уже записано */}
        <div>
          <p className="mb-2 text-sm font-medium text-muted-foreground">
            Занятия
          </p>
          {loading ? (
            <p className="py-6 text-center text-sm text-muted-foreground">
              Загрузка…
            </p>
          ) : sortedSlots.length === 0 ? (
            <p className="rounded-xl border border-dashed border-border px-4 py-6 text-center text-sm text-muted-foreground">
              Пока пусто. Добавьте день и время ниже.
            </p>
          ) : (
            <ul className="divide-y divide-border overflow-hidden rounded-xl border border-border">
              {sortedSlots.map((s) => {
                const key = `${s.day_of_week}-${normalizeTimeSlot(s.time_slot)}`
                return (
                  <li
                    key={key}
                    className={cn(
                      'flex items-center justify-between gap-3 px-3.5 py-2.5 transition-colors',
                      justAddedKey === key ? 'bg-primary/10' : 'bg-card',
                    )}
                  >
                    <span className="min-w-0 text-sm">
                      <span className="text-muted-foreground">
                        {DAY_NAMES[s.day_of_week]}
                      </span>
                      <span className="mx-1.5 text-border">·</span>
                      <strong className="tabular-nums">
                        {formatTime(s.time_slot)}
                      </strong>
                    </span>
                    <Button
                      type="button"
                      variant="ghost"
                      size="icon"
                      aria-label="Удалить"
                      disabled={saving}
                      onClick={() => removeSlot(s)}
                      className="size-9 shrink-0 text-destructive hover:bg-destructive/10"
                    >
                      <Trash2 size={15} />
                    </Button>
                  </li>
                )
              })}
            </ul>
          )}
        </div>

        {/* Компактный блок добавления */}
        <div className="space-y-3 rounded-2xl bg-muted/50 p-3 sm:p-4">
          <p className="text-sm font-medium text-foreground">Добавить</p>

          <div className="grid grid-cols-7 gap-1">
            {WEEK_DAYS.map((d) => (
              <button
                key={d}
                type="button"
                onClick={() => setSelectedDay(d)}
                className={cn(
                  'flex h-9 items-center justify-center rounded-lg text-xs font-semibold transition-colors',
                  'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring/50',
                  selectedDay === d
                    ? 'bg-primary text-primary-foreground'
                    : 'bg-card text-muted-foreground ring-1 ring-border hover:text-foreground',
                )}
              >
                {DAY_SHORT[d]}
              </button>
            ))}
          </div>

          <div className="flex gap-2">
            <Input
              type="time"
              value={time}
              onChange={(e) => setTime(e.target.value || '10:00')}
              className="h-11 flex-1 rounded-xl bg-card text-base tabular-nums"
              aria-label="Время"
            />
            <Button
              type="button"
              onClick={addSlot}
              disabled={saving}
              className="h-11 shrink-0 gap-1.5 rounded-xl px-4 font-semibold"
            >
              <Plus size={16} />
              Добавить
            </Button>
          </div>
        </div>
      </div>
    </Modal>
  )
}
