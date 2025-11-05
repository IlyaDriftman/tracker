# Анализ кода проекта Tracker

## 🔍 Найденные дубликаты и проблемы

### 1. Дублирование метода `showAlert` (6 файлов)

**Файлы:**
- `TrackersViewController.swift` (строка 991)
- `EditTrackerViewController.swift` (строка 899)
- `AddTrackerViewController.swift` (строка 722)
- `CategoryViewController.swift` (строка 373)
- `AddCategoryViewController.swift` (строка 126)
- `EditCategoryViewController.swift` (строка 131)

**Проблема:** Один и тот же код повторяется в 6 местах:
```swift
private func showAlert(title: String, message: String) {
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .default))
    present(alert, animated: true)
}
```

**Рекомендация:** Вынести в extension `UIViewController`:
```swift
extension UIViewController {
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
```

---

### 2. Дублирование `showBottomDeleteAlert` и `dismissDeleteAlert`

**Файлы:**
- `TrackersViewController.swift` (строки 819-971)
- `CategoryViewController.swift` (строки 232-371)

**Проблема:** Почти идентичный код (~150 строк) для показа диалога удаления. Различия только в:
- Тексте сообщения ("Уверены что хотите удалить трекер?" vs "Эта категория точно не нужна?")
- Действии при подтверждении

**Рекомендация:** Создать переиспользуемый компонент `DeleteConfirmationView` или extension с параметризованным методом.

---

### 3. Неиспользуемый метод `handleTrackerPlusTapped`

**Файл:** `TrackersViewController.swift` (строка 278)

**Проблема:** Метод содержит только `print("Tracker plus tapped")` и вызывается, но не выполняет полезных действий.

**Рекомендация:** Удалить метод и его вызов, если он не нужен.

---

### 4. Отладочные print-ы

**Найдено:** 25 вхождений в 6 файлах:
- `StatisticsViewController.swift`: 1
- `TrackersViewController.swift`: 16
- `EditTrackerViewController.swift`: 4
- `TrackerCell.swift`: 1
- `AddTrackerViewController.swift`: 1
- `AnalyticsService.swift`: 2

**Рекомендация:** Удалить все отладочные `print` или заменить на логирование через `AnalyticsService`.

---

### 5. Похожие функции конвертации

**Проверка:** `convertChangeType` в Store классах
- `TrackerStore.swift`
- `TrackerRecordStore.swift`
- `TrackerCategoryStore.swift`

**Статус:** ✅ Эти методы нужны, но можно вынести в общий extension.

---

## 📊 Статистика

- **Дубликатов функций:** 2 основных случая (`showAlert`, `showBottomDeleteAlert`)
- **Неиспользуемых методов:** 1 (`handleTrackerPlusTapped`)
- **Отладочных print:** 25
- **Потенциал для рефакторинга:** Средний

---

## ✅ Рекомендации по рефакторингу

### Приоритет 1 (Высокий)
1. Вынести `showAlert` в extension `UIViewController`
2. Удалить отладочные `print` или заменить на логирование

### Приоритет 2 (Средний)
3. Создать переиспользуемый компонент для `showBottomDeleteAlert`
4. Удалить неиспользуемый метод `handleTrackerPlusTapped`

### Приоритет 3 (Низкий)
5. Вынести `convertChangeType` в общий extension для Store классов


