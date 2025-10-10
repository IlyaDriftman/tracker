//
//  TrackerRecordStore.swift
//  Tracker
//
//  Created by Илья on 05.10.2025.
//

import CoreData
import UIKit

final class TrackerRecordStore: NSObject {
    private let context: NSManagedObjectContext
    private var fetchedResultsController:
        NSFetchedResultsController<TrackerRecordCoreData>!

    weak var delegate: StoreChangesDelegate?

    init(context: NSManagedObjectContext = CoreDataStack.shared.context) {
        self.context = context
        super.init()
        setupFetchedResultsController()
    }

    // MARK: - NSFetchedResultsController Setup
    private func setupFetchedResultsController() {
        let request = TrackerRecordCoreData.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(key: "date", ascending: false)  // Новые записи сверху
        ]

        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: nil,  // Без секций
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

    var numberOfRecords: Int {
        return fetchedResultsController.sections?[0].numberOfObjects ?? 0
    }

    func record(at index: Int) -> TrackerRecordCoreData {
        let indexPath = IndexPath(row: index, section: 0)
        return fetchedResultsController.object(at: indexPath)
    }

    func allRecords() -> [TrackerRecordCoreData] {
        return fetchedResultsController.fetchedObjects ?? []
    }

    // MARK: - CRUD Operations
    func addRecord(tracker: TrackerCoreData, date: Date) throws {
        let record = TrackerRecordCoreData(context: context)
        record.id = UUID()
        record.date = date
        record.tracker = tracker
        try context.save()
    }

    func deleteRecord(at index: Int) throws {
        let record = record(at: index)
        context.delete(record)
        try context.save()
    }

    // MARK: - Legacy (для совместимости)
    func fetchAllRecords() throws -> [TrackerRecordCoreData] {
        let request = TrackerRecordCoreData.fetchRequest()
        return try context.fetch(request)
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension TrackerRecordStore: NSFetchedResultsControllerDelegate {
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
