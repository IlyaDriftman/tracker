import UIKit

struct PageModel {
    let image: UIImage?
    let text: String
    let buttonText: String
}

extension PageModel {
    static let aboutTracking = PageModel(
        image: UIImage(named: "bg1"),
        text: "Отслеживайте только\n то, что хотите",
        buttonText: "Вот это технологии!"
    )
    
    static let aboutWaterAndYoga = PageModel(
        image: UIImage(named: "bg2"),
        text: "Даже если это\n не литры воды и йога",
        buttonText: "Вот это технологии!"
    )
}
