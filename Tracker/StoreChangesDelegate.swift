//
//  StoreChangesDelegate.swift
//  Tracker
//
//  Created by Assistant on 05.10.2025.
//

import Foundation

// MARK: - Store Change Types
enum StoreChangeType {
    case insert
    case delete
    case move
    case update
}

protocol StoreChangesDelegate: AnyObject {
    func storeWillChangeContent()
    func storeDidChangeSection(at sectionIndex: Int, for type: StoreChangeType)
    func storeDidChangeObject(at indexPath: IndexPath?, for type: StoreChangeType, newIndexPath: IndexPath?)
    func storeDidChangeContent()
    
    // Новый метод для уведомления о завершённых трекерах
    func trackerRecordsDidUpdate()
}

// Опционально: дефолтные пустые реализации, чтобы не заставлять реализовывать всё
extension StoreChangesDelegate {
    func storeWillChangeContent() {}
    func storeDidChangeSection(at sectionIndex: Int, for type: StoreChangeType) {}
    func storeDidChangeObject(at indexPath: IndexPath?, for type: StoreChangeType, newIndexPath: IndexPath?) {}
    func storeDidChangeContent() {}
}

