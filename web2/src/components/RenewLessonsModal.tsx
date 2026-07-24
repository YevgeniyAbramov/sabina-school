import { useEffect, useState, type FormEvent } from 'react'
import { Modal } from '@/components/Modal'
import { Field } from '@/components/Field'
import { Button } from '@/components/ui/button'
import { cn, formatNumber, studentFullName } from '@/lib/utils'
import type { Student } from '@/types'

const PRESETS = [4, 8, 12] as const

interface Props {
  open: boolean
  student: Student | null
  onClose: () => void
  onConfirm: (payload: {
    lessons: number
    paymentAmount: number
  }) => Promise<void>
}

export function RenewLessonsModal({
  open,
  student,
  onClose,
  onConfirm,
}: Props) {
  const [lessons, setLessons] = useState('8')
  const [payment, setPayment] = useState('')
  const [saving, setSaving] = useState(false)

  useEffect(() => {
    if (!open || !student) return
    setLessons('8')
    setPayment('')
  }, [open, student])

  const lessonCount = Math.max(0, Math.floor(Number(lessons)) || 0)
  const paymentAmount = Math.max(0, Math.floor(Number(payment)) || 0)

  async function handleSubmit(e: FormEvent) {
    e.preventDefault()
    if (!student || lessonCount <= 0) return
    setSaving(true)
    try {
      await onConfirm({ lessons: lessonCount, paymentAmount })
      onClose()
    } catch {
      // ошибка уже в родителе
    } finally {
      setSaving(false)
    }
  }

  if (!student) return null

  return (
    <Modal
      open={open}
      onClose={onClose}
      title="Продлить"
      footer={
        <>
          <Button type="button" variant="ghost" className="h-11" onClick={onClose}>
            Отмена
          </Button>
          <Button
            type="submit"
            form="renew-lessons-form"
            disabled={saving || lessonCount <= 0}
            className="h-11 font-semibold"
          >
            {saving ? 'Сохраняем…' : 'Сохранить'}
          </Button>
        </>
      }
    >
      <form id="renew-lessons-form" onSubmit={handleSubmit} className="space-y-5">
        <p className="text-sm leading-relaxed text-muted-foreground">
          <span className="font-medium text-foreground">
            {studentFullName(student)}
          </span>
          {student.remaining_lessons <= 0
            ? ' — уроки закончились.'
            : ` — осталось ${student.remaining_lessons}.`}
          {' '}
          Запишем новый набор с нуля.
        </p>

        <div className="space-y-3">
          <div className="flex gap-2">
            {PRESETS.map((n) => (
              <button
                key={n}
                type="button"
                onClick={() => setLessons(String(n))}
                className={cn(
                  'inline-flex h-11 flex-1 items-center justify-center rounded-xl text-sm font-semibold transition',
                  Number(lessons) === n
                    ? 'bg-primary text-primary-foreground'
                    : 'bg-muted text-muted-foreground hover:bg-accent hover:text-accent-foreground',
                )}
              >
                {n}
              </button>
            ))}
          </div>
          <Field
            label="Уроков"
            type="number"
            value={lessons}
            onChange={setLessons}
          />
          <Field
            label="Сумма оплаты, ₸"
            type="number"
            value={payment}
            onChange={setPayment}
            required
          />
        </div>

        {lessonCount > 0 && (
          <p className="text-sm text-muted-foreground">
            На карточке будет:{' '}
            <span className="font-medium text-foreground tabular-nums">
              0/{lessonCount}
            </span>
            {paymentAmount > 0 && (
              <>
                {' '}
                ·{' '}
                <span className="font-medium text-foreground tabular-nums">
                  {formatNumber(paymentAmount)} ₸
                </span>
              </>
            )}
            {' '}
            · оплачено
          </p>
        )}
      </form>
    </Modal>
  )
}
