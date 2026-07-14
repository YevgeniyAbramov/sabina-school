import { useState, type FormEvent } from 'react'
import { Modal } from '@/components/Modal'
import { PaidToggle } from '@/components/PaidToggle'
import { Field } from '@/components/Field'
import { Button } from '@/components/ui/button'
import type { StudentInput } from '@/types'

interface Props {
  open: boolean
  onClose: () => void
  onSubmit: (student: StudentInput) => Promise<void>
}

const empty = {
  first_name: '',
  last_name: '',
  middle_name: '',
  total_lessons: 8,
  paid_amount: 0,
  is_paid: false,
}

export function AddStudentModal({ open, onClose, onSubmit }: Props) {
  const [form, setForm] = useState(empty)
  const [saving, setSaving] = useState(false)

  function reset() {
    setForm(empty)
  }

  async function handleSubmit(e: FormEvent) {
    e.preventDefault()
    setSaving(true)
    try {
      await onSubmit({
        ...form,
        remaining_lessons: form.total_lessons,
        missed_classes: 0,
      })
      reset()
      onClose()
    } catch {
      // ошибка уже показана в родителе
    } finally {
      setSaving(false)
    }
  }

  function close() {
    reset()
    onClose()
  }

  return (
    <Modal
      open={open}
      onClose={close}
      title="Новый ученик"
      footer={
        <>
          <Button type="button" variant="ghost" className="h-10" onClick={close}>
            Отмена
          </Button>
          <Button
            type="submit"
            form="add-student-form"
            disabled={saving}
            className="h-10 rounded-xl font-semibold"
          >
            {saving ? 'Сохранение…' : 'Добавить'}
          </Button>
        </>
      }
    >
      <form id="add-student-form" onSubmit={handleSubmit} className="space-y-4">
        <Field
          label="Имя *"
          required
          value={form.first_name}
          onChange={(v) => setForm((f) => ({ ...f, first_name: v }))}
        />
        <Field
          label="Фамилия"
          value={form.last_name}
          onChange={(v) => setForm((f) => ({ ...f, last_name: v }))}
        />
        <Field
          label="Отчество"
          value={form.middle_name}
          onChange={(v) => setForm((f) => ({ ...f, middle_name: v }))}
        />
        <div className="grid grid-cols-2 gap-3">
          <Field
            label="Всего уроков"
            type="number"
            required
            value={String(form.total_lessons)}
            onChange={(v) =>
              setForm((f) => ({ ...f, total_lessons: parseInt(v) || 0 }))
            }
          />
          <Field
            label="Сумма, ₸"
            type="number"
            required
            value={String(form.paid_amount)}
            onChange={(v) =>
              setForm((f) => ({ ...f, paid_amount: parseInt(v) || 0 }))
            }
          />
        </div>
        <PaidToggle
          value={form.is_paid}
          onChange={(is_paid) => setForm((f) => ({ ...f, is_paid }))}
        />
      </form>
    </Modal>
  )
}
