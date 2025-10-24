import Foundation

// MARK: - SettingsManager
/// Класс для управления настройками онбординга
final class SettingsManager {
    
    // MARK: - Singleton
    static let shared = SettingsManager()
    
    // MARK: - Private Init
    private init() {}
    
    // MARK: - UserDefaults
    private let userDefaults = UserDefaults.standard
    
    // MARK: - Keys
    private enum Keys {
        static let hasSeenOnboarding = "hasSeenOnboarding"
    }
}

// MARK: - Onboarding Settings
extension SettingsManager {
    /// Пользователь прошел онбординг
    var hasSeenOnboarding: Bool {
        get {
            return userDefaults.bool(forKey: Keys.hasSeenOnboarding)
        }
        set {
            userDefaults.set(newValue, forKey: Keys.hasSeenOnboarding)
        }
    }
    
    /// Проверить, нужно ли показать онбординг
    var shouldShowOnboarding: Bool {
        return !hasSeenOnboarding
    }
}
