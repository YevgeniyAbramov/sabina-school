import { Modal } from '@/components/Modal'
import { Button } from '@/components/ui/button'

interface Props {
  open: boolean
  studentName: string
  onClose: () => void
  onConfirm: () => Promise<void>
}

export function MarkMissedModal({
  open,
  studentName,
  onClose,
  onConfirm,
}: Props) {
  return (
    <Modal
      open={open}
      onClose={onClose}
      title="Отметить пропуск?"
      footer={
        <>
          <Button type="button" variant="ghost" className="h-11" onClick={onClose}>
            Отмена
          </Button>
          <Button
            type="button"
            variant="secondary"
            className="h-11 font-semibold"
            onClick={async () => {
              await onConfirm()
              onClose()
            }}
          >
            Отметить
          </Button>
        </>
      }
    >
      <div className="space-y-2 text-sm leading-relaxed text-muted-foreground">
        <p>
          <span className="font-medium text-foreground">{studentName}</span>{' '}
          не пришёл на урок.
        </p>
        <p>Пропуск запишется. Остаток уроков не изменится.</p>
      </div>
    </Modal>
  )
}
