//
//  TrackerStore.swift
//  Tracker
//
//  Created by Илья on 05.10.2025.
//

import CoreData
import UIKit

final class TrackerStore: NSObject {
    private let context: NSManagedObjectContext
    private var fetchedResultsController:
        NSFetchedResultsController<TrackerCoreData>!

    weak var delegate: StoreChangesDelegate?

    init(context: NSManagedObjectContext = CoreDataStack.shared.context) {
        self.context = context
        super.init()
        setupFetchedResultsController()
    }

    // MARK: - NSFetchedResultsController Setup
    private func setupFetchedResultsController() {
        let request = TrackerCoreData.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(key: "category.title", ascending: true),
            NSSortDescriptor(key: "title", ascending: true),
        ]

        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: "category.title",
            cacheName: nil
        )
        fetchedResultsController.delegate = self
    }

    // MARK: - Public API
    func performFetch() throws {
        try fetchedResultsController.performFetch()
    }

    func updateFetchPredicate(_ predicate: NSPredicate?) throws {
        fetchedResultsController.fetchRequest.predicate = predicate
        try fetchedResultsController.performFetch()
    }

    var numberOfSections: Int {
        return fetchedResultsController.sections?.count ?? 0
    }

    func numberOfObjects(in section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }

    func object(at indexPath: IndexPath) -> TrackerCoreData {
        return fetchedResultsController.object(at: indexPath)
    }

    func sectionTitle(at section: Int) -> String? {
        return fetchedResultsController.sections?[section].name
    }
    
    func findTracker(by id: UUID) throws -> TrackerCoreData? {
        let request = TrackerCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        let results = try context.fetch(request)
        return results.first
    }
    
    // MARK: - Conversion Helper
    func tracker(from trackerCD: TrackerCoreData) -> Tracker? {
        guard let id = trackerCD.id else { return nil }
        guard let title = trackerCD.title else { return nil }
        guard let emoji = trackerCD.emoji else { return nil }
        guard let colorHex = trackerCD.colorHEX else { return nil }

        let color = UIColor(hex: colorHex) ?? .black

        var schedule: Schedule? = nil

        if let scheduleData = trackerCD.scheduleData,
            let data = scheduleData.data(using: .utf8)
        {
            schedule = try? JSONDecoder().decode(Schedule.self, from: data)
        }

        return Tracker(
            id: id,
            title: title,
            color: color,
            emoji: emoji,
            schedule: schedule,
            isPinned: trackerCD.isPinned
        )
    }

    // MARK: - Добавление
    func addTracker(_ tracker: Tracker, category: TrackerCategoryCoreData)
        throws
    {
        let trackerCD = TrackerCoreData(context: context)
        trackerCD.id = tracker.id
        trackerCD.title = tracker.title
        trackerCD.emoji = tracker.emoji

        let hexString = tracker.color.hexString
        trackerCD.colorHEX = hexString

        trackerCD.category = category
        trackerCD.isPinned = tracker.isPinned

        if let schedule = tracker.schedule {
            let data = try JSONEncoder().encode(schedule)
            trackerCD.scheduleData = String(data: data, encoding: .utf8)
        }

        try context.save()
    }

    // MARK: - Обновление
    func updateTracker(_ tracker: Tracker, category: TrackerCategoryCoreData) throws {
        guard let trackerCD = try findTracker(by: tracker.id) else {
            throw NSError(domain: "TrackerStore", code: 404, userInfo: [NSLocalizedDescriptionKey: "Трекер не найден"])
        }
        
        trackerCD.title = tracker.title
        trackerCD.emoji = tracker.emoji
        
        let hexString = tracker.color.hexString
        trackerCD.colorHEX = hexString
        
        trackerCD.category = category
        trackerCD.isPinned = tracker.isPinned
        
        if let schedule = tracker.schedule {
            let data = try JSONEncoder().encode(schedule)
            trackerCD.scheduleData = String(data: data, encoding: .utf8)
        } else {
            trackerCD.scheduleData = nil
        }
        
        try context.save()
    }
    
    // MARK: - Закрепление/Открепление
    func togglePin(for trackerId: UUID) throws {
        guard let trackerCD = try findTracker(by: trackerId) else {
            throw NSError(domain: "TrackerStore", code: 404, userInfo: [NSLocalizedDescriptionKey: "Трекер не найден"])
        }
        trackerCD.isPinned.toggle()
        try context.save()
    }
    
    // MARK: - Удаление
    func deleteTracker(_ tracker: TrackerCoreData) throws {
        // Удаляем все записи выполнения этого трекера
        if let id = tracker.id {
            let recordStore = TrackerRecordStore()
            let records = try recordStore.fetchAllRecords()
            for record in records {
                if record.tracker?.id == id {
                    try recordStore.deleteRecord(record)
                }
            }
        }
        
        // Удаляем сам трекер
        context.delete(tracker)
        try context.save()
    }
    
    // MARK: - Загрузка всех (legacy - для совместимости)
    func fetchAllTrackers() throws -> [Tracker] {
        let request = TrackerCoreData.fetchRequest()
        let results = try context.fetch(request)

        return results.compactMap { trackerCD in
            return tracker(from: trackerCD)
        }
    }
}

// MARK: - Private Helpers
private extension TrackerStore {
    func convertChangeType(_ type: NSFetchedResultsChangeType) -> StoreChangeType {
        switch type {
        case .insert:
            return .insert
        case .delete:
            return .delete
        case .move:
            return .move
        case .update:
            return .update
        @unknown default:
            return .update
        }
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension TrackerStore: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>
    ) {
        delegate?.storeWillChangeContent()
    }

    func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChange sectionInfo: NSFetchedResultsSectionInfo,
        atSectionIndex sectionIndex: Int,
        for type: NSFetchedResultsChangeType
    ) {
        let storeChangeType = convertChangeType(type)
        delegate?.storeDidChangeSection(at: sectionIndex, for: storeChangeType)
    }

    func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChange anObject: Any,
        at indexPath: IndexPath?,
        for type: NSFetchedResultsChangeType,
        newIndexPath: IndexPath?
    ) {
        let storeChangeType = convertChangeType(type)
        delegate?.storeDidChangeObject(
            at: indexPath,
            for: storeChangeType,
            newIndexPath: newIndexPath
        )
    }

    func controllerDidChangeContent(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>
    ) {
        delegate?.storeDidChangeContent()
    }
}
