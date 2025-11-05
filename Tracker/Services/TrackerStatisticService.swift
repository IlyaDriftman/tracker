import Foundation
import CoreData

final class TrackerStatisticService {
    
    private let recordStore: TrackerRecordStore
    private let trackerStore: TrackerStore
    
    init(
        recordStore: TrackerRecordStore = TrackerRecordStore(),
        trackerStore: TrackerStore = TrackerStore()
    ) {
        self.recordStore = recordStore
        self.trackerStore = trackerStore
    }
    
    // MARK: - Statistics Calculation
    
    /// Рассчитывает лучший период - максимальное количество дней подряд,
    /// когда трекер выполнялся согласно своему расписанию
    func calculateBestPeriod() -> Int {
        var maxPeriod = 0
        
        // Получаем все трекеры через Core Data напрямую
        let request = TrackerCoreData.fetchRequest()
        guard let allTrackersCD = try? CoreDataStack.shared.context.fetch(request) else {
            return 0
        }
        
        // Получаем все записи
        guard let allRecords = try? recordStore.fetchAllRecords() else {
            return 0
        }
        
        // Группируем записи по трекерам
        var recordsByTracker: [UUID: [TrackerRecordCoreData]] = [:]
        for record in allRecords {
            guard let trackerId = record.tracker?.id else { continue }
            if recordsByTracker[trackerId] == nil {
                recordsByTracker[trackerId] = []
            }
            recordsByTracker[trackerId]?.append(record)
        }
        
        // Для каждого трекера находим лучший период
        for trackerCD in allTrackersCD {
            guard let tracker = trackerStore.tracker(from: trackerCD),
                  let schedule = tracker.schedule,
                  let records = recordsByTracker[tracker.id] else {
                continue
            }
            
            // Сортируем записи по дате
            let sortedRecords = records.sorted { ($0.date ?? Date.distantPast) < ($1.date ?? Date.distantPast) }
            
            // Находим самую длинную последовательность дней, когда трекер выполнялся согласно расписанию
            var currentStreak = 0
            var maxStreak = 0
            var previousDate: Date?
            
            for record in sortedRecords {
                guard let recordDate = record.date else { continue }
                
                // Получаем день недели для записи
                let calendar = Calendar.current
                let weekdayFromCalendar = calendar.component(.weekday, from: recordDate)
                let weekday: Int
                if weekdayFromCalendar == 1 {
                    weekday = 7 // Воскресенье
                } else {
                    weekday = weekdayFromCalendar - 1
                }
                
                guard let weekdayEnum = Weekday(rawValue: weekday) else { continue }
                
                // Проверяем, соответствует ли день расписанию
                if schedule.contains(weekdayEnum) {
                    // Проверяем, является ли это продолжением последовательности
                    if let prevDate = previousDate {
                        let daysBetween = calendar.dateComponents([.day], from: calendar.startOfDay(for: prevDate), to: calendar.startOfDay(for: recordDate)).day ?? 0
                        
                        if daysBetween == 1 {
                            // Продолжение последовательности
                            currentStreak += 1
                        } else {
                            // Прерывание последовательности
                            maxStreak = max(maxStreak, currentStreak)
                            currentStreak = 1
                        }
                    } else {
                        // Первая запись
                        currentStreak = 1
                    }
                    
                    previousDate = recordDate
                } else {
                    // Не соответствует расписанию - прерываем последовательность
                    maxStreak = max(maxStreak, currentStreak)
                    currentStreak = 0
                    previousDate = nil
                }
            }
            
            // Проверяем последнюю последовательность
            maxStreak = max(maxStreak, currentStreak)
            
            // Обновляем общий максимум
            maxPeriod = max(maxPeriod, maxStreak)
        }
        
        return maxPeriod
    }
    
    /// Рассчитывает идеальные дни - количество дней, когда выполнены все трекеры
    func calculateIdealDays() -> Int {
        // Получаем все трекеры
        let request = TrackerCoreData.fetchRequest()
        guard let allTrackersCD = try? CoreDataStack.shared.context.fetch(request) else {
            return 0
        }
        
        // Преобразуем в Tracker
        let allTrackers = allTrackersCD.compactMap { trackerStore.tracker(from: $0) }
        guard !allTrackers.isEmpty else {
            return 0
        }
        
        // Получаем все записи
        guard let allRecords = try? recordStore.fetchAllRecords() else {
            return 0
        }
        
        // Группируем записи по датам (без времени)
        let calendar = Calendar.current
        var recordsByDate: [Date: Set<UUID>] = [:]
        
        for record in allRecords {
            guard let recordDate = record.date,
                  let trackerId = record.tracker?.id else {
                continue
            }
            
            let dateKey = calendar.startOfDay(for: recordDate)
            if recordsByDate[dateKey] == nil {
                recordsByDate[dateKey] = []
            }
            recordsByDate[dateKey]?.insert(trackerId)
        }
        
        // Проверяем каждую дату, выполнены ли все трекеры
        var idealDaysCount = 0
        
        for (date, completedTrackerIds) in recordsByDate {
            // Проверяем, выполнены ли все трекеры в этот день
            var allCompleted = true
            
            for tracker in allTrackers {
                // Проверяем, должен ли трекер выполняться в этот день
                let weekdayFromCalendar = calendar.component(.weekday, from: date)
                let weekday: Int
                if weekdayFromCalendar == 1 {
                    weekday = 7 // Воскресенье
                } else {
                    weekday = weekdayFromCalendar - 1
                }
                
                guard let weekdayEnum = Weekday(rawValue: weekday) else {
                    continue
                }
                
                // Если у трекера есть расписание, проверяем соответствует ли день
                if let schedule = tracker.schedule {
                    if schedule.contains(weekdayEnum) {
                        // Трекер должен быть выполнен в этот день
                        if !completedTrackerIds.contains(tracker.id) {
                            allCompleted = false
                            break
                        }
                    }
                } else {
                    // Для нерегулярных событий (schedule = nil) проверяем, выполнены ли они
                    // Если нерегулярный трекер не выполнен, это не идеальный день
                    if !completedTrackerIds.contains(tracker.id) {
                        allCompleted = false
                        break
                    }
                }
            }
            
            if allCompleted {
                idealDaysCount += 1
            }
        }
        
        return idealDaysCount
    }
    
    /// Рассчитывает среднее значение - среднее количество трекеров, выполняемых в день
    func calculateAverageValue() -> Int {
        // Получаем все записи
        guard let allRecords = try? recordStore.fetchAllRecords() else {
            return 0
        }
        
        guard !allRecords.isEmpty else {
            return 0
        }
        
        // Группируем записи по датам (без времени)
        let calendar = Calendar.current
        var recordsByDate: [Date: Set<UUID>] = [:]
        
        for record in allRecords {
            guard let recordDate = record.date,
                  let trackerId = record.tracker?.id else {
                continue
            }
            
            let dateKey = calendar.startOfDay(for: recordDate)
            if recordsByDate[dateKey] == nil {
                recordsByDate[dateKey] = []
            }
            recordsByDate[dateKey]?.insert(trackerId)
        }
        
        guard !recordsByDate.isEmpty else {
            return 0
        }
        
        // Считаем общее количество выполненных трекеров и количество дней
        var totalTrackers = 0
        for (_, trackerIds) in recordsByDate {
            totalTrackers += trackerIds.count
        }
        
        // Вычисляем среднее значение
        let average = Double(totalTrackers) / Double(recordsByDate.count)
        
        // Округляем до целого числа
        return Int(average.rounded())
    }
    
    /// Возвращает общее количество завершенных трекеров
    func totalCompletedTrackers() -> Int {
        return recordStore.totalCompletedTrackers()
    }
}


