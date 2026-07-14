import { Modal } from '@/components/Modal'
import { Button } from '@/components/ui/button'

interface Props {
  open: boolean
  studentName: string
  onClose: () => void
  onConfirm: () => Promise<void>
}

export function CompleteLessonModal({
  open,
  studentName,
  onClose,
  onConfirm,
}: Props) {
  return (
    <Modal
      open={open}
      onClose={onClose}
      title="Провести урок?"
      footer={
        <>
          <Button type="button" variant="ghost" className="h-11" onClick={onClose}>
            Отмена
          </Button>
          <Button
            type="button"
            className="h-11 font-semibold"
            onClick={async () => {
              await onConfirm()
              onClose()
            }}
          >
            Провести
          </Button>
        </>
      }
    >
      <div className="space-y-2 text-sm leading-relaxed text-muted-foreground">
        <p>
          Урок с{' '}
          <span className="font-medium text-foreground">{studentName}</span>{' '}
          состоялся.
        </p>
        <p>Остаток уроков уменьшится на 1.</p>
      </div>
    </Modal>
  )
}
