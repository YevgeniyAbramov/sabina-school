import { useEffect, useState, type FormEvent } from 'react'
import { Modal } from '@/components/Modal'
import { PaidToggle } from '@/components/PaidToggle'
import { Field } from '@/components/Field'
import { Button } from '@/components/ui/button'
import type { Student, StudentInput } from '@/types'

interface Props {
  open: boolean
  student: Student | null
  onClose: () => void
  onSubmit: (id: number, student: StudentInput) => Promise<void>
}

export function EditStudentModal({ open, student, onClose, onSubmit }: Props) {
  const [form, setForm] = useState<{
    first_name: string
    last_name: string
    middle_name: string
    is_paid: boolean
  } | null>(null)
  const [saving, setSaving] = useState(false)

  useEffect(() => {
    if (student) {
      setForm({
        first_name: student.first_name,
        last_name: student.last_name || '',
        middle_name: student.middle_name || '',
        is_paid: student.is_paid,
      })
    }
  }, [student])

  async function handleSubmit(e: FormEvent) {
    e.preventDefault()
    if (!student || !form) return

    // Уроки и сумма не трогаем — только ФИО и статус оплаты
    const payload: StudentInput = {
      first_name: form.first_name,
      last_name: form.last_name,
      middle_name: form.middle_name,
      total_lessons: student.total_lessons,
      remaining_lessons: student.remaining_lessons,
      paid_amount: student.paid_amount,
      missed_classes: student.missed_classes,
      is_paid: form.is_paid,
    }

    setSaving(true)
    try {
      await onSubmit(student.id, payload)
      onClose()
    } catch {
      // ошибка уже показана в родителе
    } finally {
      setSaving(false)
    }
  }

  return (
    <Modal
      open={open}
      onClose={onClose}
      title="Изменить"
      footer={
        <>
          <Button type="button" variant="ghost" className="h-10" onClick={onClose}>
            Отмена
          </Button>
          <Button
            type="submit"
            form="edit-student-form"
            disabled={saving || !form}
            className="h-10 rounded-xl font-semibold"
          >
            {saving ? 'Сохранение…' : 'Сохранить'}
          </Button>
        </>
      }
    >
      {form && (
        <form id="edit-student-form" onSubmit={handleSubmit} className="space-y-4">
          <Field
            label="Имя *"
            required
            value={form.first_name}
            onChange={(v) => setForm((f) => f && { ...f, first_name: v })}
          />
          <Field
            label="Фамилия"
            value={form.last_name}
            onChange={(v) => setForm((f) => f && { ...f, last_name: v })}
          />
          <Field
            label="Отчество"
            value={form.middle_name}
            onChange={(v) => setForm((f) => f && { ...f, middle_name: v })}
          />
          <PaidToggle
            value={form.is_paid}
            onChange={(is_paid) => setForm((f) => f && { ...f, is_paid })}
          />
          <p className="text-xs leading-relaxed text-muted-foreground">
            Уроки и сумму меняйте через «Продлить» в меню карточки.
          </p>
        </form>
      )}
    </Modal>
  )
}
