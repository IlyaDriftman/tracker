//
//  StoreChangesDelegate.swift
//  Tracker
//
//  Created by Assistant on 05.10.2025.
//

import Foundation
import CoreData

protocol StoreChangesDelegate: AnyObject {
    func storeWillChangeContent()
    func storeDidChangeSection(at sectionIndex: Int, for type: NSFetchedResultsChangeType)
    func storeDidChangeObject(at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?)
    func storeDidChangeContent()
}

// Опционально: дефолтные пустые реализации, чтобы не заставлять реализовывать всё
extension StoreChangesDelegate {
    func storeWillChangeContent() {}
    func storeDidChangeSection(at sectionIndex: Int, for type: NSFetchedResultsChangeType) {}
    func storeDidChangeObject(at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {}
    func storeDidChangeContent() {}
}

