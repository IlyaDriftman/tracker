import UIKit

/// Базовый контроллер, автоматически отслеживающий появление/закрытие экранов
class AnalyticsViewController: UIViewController {
    var analyticsScreenName: Screen?

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let screen = analyticsScreenName {
            AnalyticsService.track(event: .open, screen: screen)
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if let screen = analyticsScreenName {
            AnalyticsService.track(event: .close, screen: screen)
        }
    }
}
