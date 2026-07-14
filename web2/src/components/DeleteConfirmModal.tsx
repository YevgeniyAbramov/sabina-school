import { Modal } from '@/components/Modal'
import { Button } from '@/components/ui/button'

interface Props {
  open: boolean
  onClose: () => void
  onConfirm: () => Promise<void>
}

export function DeleteConfirmModal({ open, onClose, onConfirm }: Props) {
  return (
    <Modal
      open={open}
      onClose={onClose}
      title="Удалить ученика?"
      danger
      footer={
        <>
          <Button type="button" variant="ghost" className="h-11" onClick={onClose}>
            Оставить
          </Button>
          <Button
            type="button"
            variant="destructive"
            className="h-11 bg-destructive font-semibold text-white hover:bg-destructive/90"
            onClick={async () => {
              await onConfirm()
              onClose()
            }}
          >
            Удалить
          </Button>
        </>
      }
    >
      <p className="text-sm leading-relaxed text-muted-foreground">
        Карточка и связанные данные пропадут. Вернуть будет нельзя.
      </p>
    </Modal>
  )
}
