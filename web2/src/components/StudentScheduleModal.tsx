import { useEffect, useState } from 'react'
import { Plus, Trash2 } from 'lucide-react'
import { Modal } from '@/components/Modal'
import { TimeWheel } from '@/components/TimeWheel'
import { Button } from '@/components/ui/button'
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

interface Props {
  open: boolean
  studentId: number | null
  studentName: string
  onClose: () => void
  onUnauthorized: () => void
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
  const [selectedDay, setSelectedDay] = useState<number | null>(null)
  const [hour, setHour] = useState('10')
  const [minute, setMinute] = useState('00')

  useEffect(() => {
    if (!open || !studentId) return
    setSelectedDay(null)
    setHour('10')
    setMinute('00')
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

  async function persist(next: ScheduleSlotInput[], close = false) {
    if (!studentId) return
    try {
      const data = await scheduleApi.replaceForStudent(studentId, next)
      if (data.status) {
        setSlots(next)
        if (close) onClose()
      } else {
        show(data.message || 'Не удалось сохранить', 'danger')
      }
    } catch (e) {
      if (e instanceof AuthError) onUnauthorized()
      else show('Не удалось сохранить расписание', 'danger')
    }
  }

  function addSlot() {
    if (selectedDay === null) {
      show('Сначала выберите день', 'danger')
      return
    }
    const timeSlot = normalizeTimeSlot(`${hour}:${minute}`)
    const exists = slots.some(
      (s) =>
        Number(s.day_of_week) === Number(selectedDay) &&
        normalizeTimeSlot(s.time_slot) === timeSlot,
    )
    if (exists) {
      show('Такое время уже есть', 'danger')
      return
    }
    const next = [...slots, { day_of_week: selectedDay, time_slot: timeSlot }]
    void persist(next)
  }

  function removeSlot(index: number) {
    const next = slots.filter((_, i) => i !== index)
    void persist(next)
  }

  return (
    <Modal
      open={open}
      onClose={onClose}
      title={`Расписание · ${studentName}`}
      size="lg"
      footer={
        <Button
          type="button"
          className="h-11 w-full font-semibold sm:w-auto"
          onClick={() => void persist(slots, true)}
        >
          Готово
        </Button>
      }
    >
      <div className="space-y-5">
        <div>
          <p className="mb-2.5 text-sm font-medium text-foreground">
            День
          </p>
          <div className="flex flex-wrap gap-2">
            {[1, 2, 3, 4, 5, 6, 0].map((d) => (
              <button
                key={d}
                type="button"
                onClick={() => setSelectedDay(d)}
                className={cn(
                  'inline-flex h-11 min-w-11 items-center justify-center rounded-xl px-3 text-sm font-medium transition-colors',
                  'focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-ring/50',
                  selectedDay === d
                    ? 'bg-primary text-primary-foreground'
                    : 'bg-muted text-muted-foreground hover:bg-accent hover:text-accent-foreground',
                )}
              >
                {DAY_SHORT[d]}
              </button>
            ))}
          </div>
        </div>

        {selectedDay !== null && (
          <div className="animate-fade-in space-y-3 rounded-2xl border border-border bg-muted/40 p-4">
            <p className="text-sm font-medium text-foreground">Время</p>
            <TimeWheel
              hour={hour}
              minute={minute}
              onHourChange={setHour}
              onMinuteChange={setMinute}
            />
            <Button
              type="button"
              onClick={addSlot}
              className="h-11 w-full font-semibold"
            >
              <Plus size={16} /> Добавить время
            </Button>
          </div>
        )}

        <div>
          <p className="mb-2.5 text-sm font-medium text-foreground">
            Занятия
          </p>
          {loading ? (
            <p className="text-sm text-muted-foreground">Загрузка…</p>
          ) : slots.length === 0 ? (
            <p className="rounded-xl border border-dashed border-border px-4 py-8 text-center text-sm text-muted-foreground">
              Пока пусто — выберите день и добавьте время
            </p>
          ) : (
            <ul className="divide-y divide-border overflow-hidden rounded-xl border border-border">
              {slots.map((s, i) => (
                <li
                  key={`${s.day_of_week}-${s.time_slot}-${i}`}
                  className="flex items-center justify-between bg-card px-4 py-3"
                >
                  <span className="text-sm">
                    {DAY_NAMES[s.day_of_week]} —{' '}
                    <strong className="tabular-nums">
                      {formatTime(s.time_slot)}
                    </strong>
                  </span>
                  <Button
                    type="button"
                    variant="ghost"
                    size="icon"
                    aria-label="Удалить слот"
                    onClick={() => removeSlot(i)}
                    className="size-10 text-destructive hover:bg-destructive/10"
                  >
                    <Trash2 size={15} />
                  </Button>
                </li>
              ))}
            </ul>
          )}
        </div>
      </div>
    </Modal>
  )
}
