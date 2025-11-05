import Foundation
import AppMetricaCore

struct AnalyticsService {
    static func activate() {
        guard let configuration = AppMetricaConfiguration(apiKey: "ebfb8380-5178-4e0d-b7ad-635097ed11cc") else { return }
        AppMetrica.activate(with: configuration)
    }

    private static func report(event: String, params: [String: Any]) {
        AppMetrica.reportEvent(name: event, parameters: params, onFailure: { _ in
            // Ошибка отправки аналитики
        })
    }

    static func track(event: AnalyticsEvent, screen: Screen, item: Item? = nil) {
        var params: [String: Any] = [
            "event": event.rawValue,
            "screen": screen.rawValue,
            "timestamp": Date().timeIntervalSince1970
        ]

        if let item = item, event == .click {
            params["item"] = item.rawValue
        }

        report(event: event.rawValue, params: params)
    }
    
    /// Удобный метод для отслеживания кликов
    static func click(screen: Screen, item: Item) {
        track(event: .click, screen: screen, item: item)
    }
}

// MARK: - Типы событий
enum AnalyticsEvent: String {
    case open
    case close
    case click
}

// MARK: - Экраны
enum Screen: String {
    case main = "Main"
    case addTrackers = "AddTrackers"
    case addCategory = "AddCategory"
    case selectCategory = "selectCategory"
    case editCategory = "EditCategory"
    case onBoarding = "OnBoarding"
    case selectSchedule = "selectSchedule"
    case statistics = "Statistics"
}

// MARK: - Элементы (только для клика)
enum Item: String {
    case addTrack = "add_track"
    case track = "track"
    case filter = "filter"
    case edit = "edit"
    case delete = "delete"
    case pin = "pin"
    case unpin = "unpin"
    case complete = "complete"
    case uncomplete = "uncomplete"
}

// Событие открытия экрана
//AnalyticsService.track(event: .open, screen: .main)

// Событие клика на кнопку "Добавить трек"
//AnalyticsService.click(screen: .main, item: .addTrack)
