/**
 * Единый словарь UI-подписей.
 * Логика трёх сигналов:
 *  - unpaid     → статус оплаты (деньги)
 *  - endingSoon → остался ровно 1 урок
 *  - finished   → осталось 0 уроков
 *
 * Пара «Заканчивается / Закончился» — про уроки, не про оплату.
 */

export const copy = {
  paid: 'Оплачено',
  unpaid: 'Не оплачено',
  unpaidShort: 'Не оплачено',

  /** Ровно 1 урок */
  endingSoon: 'Заканчивается',
  endingSoonHint: 'остался один урок',
  endingSoonChip: (n: number) =>
    n === 1 ? '1 заканчивается' : `${n} заканчиваются`,

  /** 0 уроков */
  finished: 'Закончился',
  finishedChip: (n: number) =>
    n === 1 ? '1 закончился' : `${n} закончились`,

  filterAll: 'Все',
  filterPaid: 'Оплачено',
  filterUnpaid: 'Не оплачено',
  filterEndingSoon: 'Заканчивается',
  filterFinished: 'Закончился',
  filterEmpty: 'По этому фильтру пусто',
  filterEmptyHint: 'Сбросьте фильтр или добавьте нового',
  filterShowAll: 'Показать всех',

  searchPlaceholder: 'Поиск по имени…',
  searchEmpty: 'Никого не нашли',
  searchEmptyHint: 'Попробуйте другое имя или сбросьте поиск',
  searchClear: 'Сбросить поиск',

  paidToggleOn: 'Оплачен',
  paidToggleOff: 'Не оплачен',
  paidToggleHintOn: 'Деньги получены',
  paidToggleHintOff: 'Ждём оплату',
} as const
