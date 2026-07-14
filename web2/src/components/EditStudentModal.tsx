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
  const [form, setForm] = useState<StudentInput | null>(null)
  const [saving, setSaving] = useState(false)

  useEffect(() => {
    if (student) {
      setForm({
        first_name: student.first_name,
        last_name: student.last_name || '',
        middle_name: student.middle_name || '',
        total_lessons: student.total_lessons,
        remaining_lessons: student.remaining_lessons,
        paid_amount: student.paid_amount,
        missed_classes: student.missed_classes,
        is_paid: student.is_paid,
      })
    }
  }, [student])

  async function handleSubmit(e: FormEvent) {
    e.preventDefault()
    if (!student || !form) return
    setSaving(true)
    try {
      await onSubmit(student.id, form)
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
      title="Редактирование"
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
          <div className="grid grid-cols-2 gap-3">
            <Field
              label="Всего уроков"
              type="number"
              value={String(form.total_lessons)}
              onChange={(v) =>
                setForm((f) => f && { ...f, total_lessons: parseInt(v) || 0 })
              }
            />
            <Field
              label="Осталось"
              type="number"
              value={String(form.remaining_lessons)}
              onChange={(v) =>
                setForm(
                  (f) => f && { ...f, remaining_lessons: parseInt(v) || 0 },
                )
              }
            />
            <Field
              label="Сумма, ₸"
              type="number"
              value={String(form.paid_amount)}
              onChange={(v) =>
                setForm((f) => f && { ...f, paid_amount: parseInt(v) || 0 })
              }
            />
            <Field
              label="Пропуски"
              type="number"
              value={String(form.missed_classes)}
              onChange={(v) =>
                setForm((f) => f && { ...f, missed_classes: parseInt(v) || 0 })
              }
            />
          </div>
          <PaidToggle
            value={form.is_paid}
            onChange={(is_paid) => setForm((f) => f && { ...f, is_paid })}
          />
        </form>
      )}
    </Modal>
  )
}
