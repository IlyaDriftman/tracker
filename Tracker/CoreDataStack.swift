//
//  CoreDataStack.swift
//  Tracker
//
//  Created by Илья on 05.10.2025.
//

import CoreData

final class CoreDataStack {
    static let shared = CoreDataStack()

    // MARK: - Persistent Container
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Library")

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Ошибка инициализации Core Data: \(error), \(error.userInfo)")
            }
        }
        
        // Настройка автоматического слияния изменений из фоновых контекстов
        let viewContext = container.viewContext
        viewContext.automaticallyMergesChangesFromParent = true
        viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        return container
    }()

    // MARK: - Context
    var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    // MARK: - Save Context
    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Ошибка сохранения контекста: \(nserror), \(nserror.userInfo)")
            }
        }
    }
}

