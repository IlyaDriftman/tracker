//
//  UIColor+Hex.swift
//  Tracker
//
//  Created by Assistant on 05.10.2025.
//

import UIKit

extension UIColor {
    
    // MARK: - Hex String to UIColor
    convenience init?(hex: String) {
        let hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        let scanner = Scanner(string: hexString)
        
        // Удаляем # если есть
        let cleanHexString: String
        if hexString.hasPrefix("#") {
            cleanHexString = String(hexString.dropFirst())
            scanner.currentIndex = hexString.index(after: hexString.startIndex)
        } else {
            cleanHexString = hexString
        }
        
        var hexNumber: UInt64 = 0
        
        guard scanner.scanHexInt64(&hexNumber) else {
            print("DEBUG: Не удалось распарсить hex: '\(hexString)'")
            return nil
        }
        
        let r, g, b, a: CGFloat
        
        switch cleanHexString.count {
        case 6: // RGB (24 bit)
            r = CGFloat((hexNumber & 0xFF0000) >> 16) / 255.0
            g = CGFloat((hexNumber & 0x00FF00) >> 8) / 255.0
            b = CGFloat(hexNumber & 0x0000FF) / 255.0
            a = 1.0
            
        case 8: // ARGB (32 bit)
            r = CGFloat((hexNumber & 0xFF000000) >> 24) / 255.0
            g = CGFloat((hexNumber & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((hexNumber & 0x0000FF00) >> 8) / 255.0
            a = CGFloat(hexNumber & 0x000000FF) / 255.0
            
        default:
            print("DEBUG: Неподдерживаемая длина hex: '\(hexString)' (чистая длина: \(cleanHexString.count))")
            return nil
        }
        
        print("DEBUG: Создаем UIColor из hex '\(hexString)' -> RGB(\(r), \(g), \(b), \(a))")
        self.init(red: r, green: g, blue: b, alpha: a)
    }
    
    // MARK: - UIColor to Hex String
    var hexString: String {
        // Конвертируем в RGB цветовое пространство для корректной работы с системными цветами
        let rgbColor = self.converted(to: CGColorSpaceCreateDeviceRGB())
        
        guard let components = rgbColor.components, components.count >= 3 else {
            print("DEBUG: Не удалось получить компоненты цвета для \(self)")
            return "#000000"
        }
        
        let r = components[0]
        let g = components[1]
        let b = components[2]
        
        let hexString = String(format: "#%02X%02X%02X",
                              Int(r * 255),
                              Int(g * 255),
                              Int(b * 255))
        
        print("DEBUG: Конвертируем цвет \(self) -> hex: \(hexString)")
        return hexString
    }
    
    // MARK: - Helper method to convert color space
    func converted(to colorSpace: CGColorSpace) -> CGColor {
        let cgColor = self.cgColor
        return cgColor.converted(to: colorSpace, intent: .defaultIntent, options: nil) ?? cgColor
    }
}
