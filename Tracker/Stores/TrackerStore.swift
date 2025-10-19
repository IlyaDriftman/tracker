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

        // Отладочная информация
        print(
            "DEBUG: Загружаем трекер '\(title)' с цветом hex: '\(colorHex)' -> UIColor: \(color)"
        )

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
            schedule: schedule
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

        // Отладочная информация
        print(
            "DEBUG: Сохраняем трекер '\(tracker.title)' с цветом: \(tracker.color) -> hex: '\(hexString)'"
        )

        trackerCD.category = category

        if let schedule = tracker.schedule {
            let data = try JSONEncoder().encode(schedule)
            trackerCD.scheduleData = String(data: data, encoding: .utf8)
        }

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
        delegate?.storeDidChangeSection(at: sectionIndex, for: type)
    }

    func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChange anObject: Any,
        at indexPath: IndexPath?,
        for type: NSFetchedResultsChangeType,
        newIndexPath: IndexPath?
    ) {
        delegate?.storeDidChangeObject(
            at: indexPath,
            for: type,
            newIndexPath: newIndexPath
        )
    }

    func controllerDidChangeContent(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>
    ) {
        delegate?.storeDidChangeContent()
    }
}
