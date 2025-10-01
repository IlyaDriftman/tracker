import UIKit

enum Weekday: Int, CaseIterable, Codable {
    case mon = 1, tue, wed, thu, fri, sat, sun
}

enum Schedule: Equatable, Codable {
    case everyDay
    case weekdays
    case custom(Set<Weekday>)
    
    func contains(_ weekday: Weekday) -> Bool {
        switch self {
        case .everyDay:
            return true
        case .weekdays:
            return weekday != .sat && weekday != .sun
        case .custom(let weekdays):
            return weekdays.contains(weekday)
        }
    }
}

/// Для нерегулярного события `schedule` = nil
struct Tracker {
    let id: UUID
    let title: String
    let color: UIColor
    let emoji: String
    let schedule: Schedule?   // nil → нерегулярное событие
}
