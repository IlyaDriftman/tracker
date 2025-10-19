//
//  TrackerCategoryStore.swift
//  Tracker
//
//  Created by Илья on 05.10.2025.
//

import CoreData

private enum CoreDataKeys {
    static let title = "title"
    static let categoryTitle = "category.title"
    static let date = "date"
}

final class TrackerCategoryStore: NSObject {
    private let context: NSManagedObjectContext
    private var numberOfCategories: Int {
        return fetchedResultsController.sections?[0].numberOfObjects ?? 0
    }
    private var fetchedResultsController:
        NSFetchedResultsController<TrackerCategoryCoreData>!
    weak var delegate: StoreChangesDelegate?

    init(context: NSManagedObjectContext = CoreDataStack.shared.context) {
        self.context = context
        super.init()
        setupFetchedResultsController()
    }

    private func setupFetchedResultsController() {
        let request = TrackerCategoryCoreData.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(key: CoreDataKeys.title, ascending: true)
        ]

        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: nil,  // Без секций
            cacheName: nil
        )
        fetchedResultsController.delegate = self
    }

    func performFetch() throws {
        try fetchedResultsController.performFetch()
    }

    func updateFetchPredicate(_ predicate: NSPredicate?) throws {
        fetchedResultsController.fetchRequest.predicate = predicate
        try fetchedResultsController.performFetch()
    }


    func category(at index: Int) -> TrackerCategoryCoreData {
        let indexPath = IndexPath(row: index, section: 0)
        return fetchedResultsController.object(at: indexPath)
    }

    func allCategories() -> [TrackerCategoryCoreData] {
        return fetchedResultsController.fetchedObjects ?? []
    }
    // Добавить категорию
    func addCategory(title: String) throws -> TrackerCategoryCoreData {
        let category = TrackerCategoryCoreData(context: context)
        category.title = title
        try context.save()
        return category
    }

    // Получить все категории
    func fetchAllCategories() throws -> [TrackerCategoryCoreData] {
        let request = TrackerCategoryCoreData.fetchRequest()
        return try context.fetch(request)
    }

    // Найти или создать категорию
    func findOrCreateCategory(title: String) throws -> TrackerCategoryCoreData {
        let request = TrackerCategoryCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "title == %@", title)
        request.fetchLimit = 1

        let results = try context.fetch(request)
        if let existingCategory = results.first {
            return existingCategory
        } else {
            return try addCategory(title: title)
        }
    }
}

extension TrackerCategoryStore: NSFetchedResultsControllerDelegate {
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
