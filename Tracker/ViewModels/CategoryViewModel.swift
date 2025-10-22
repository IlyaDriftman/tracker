//
//  CategoryViewModel.swift
//  Tracker
//
//  Created by Илья on 19.10.2025.
//

import Foundation
import CoreData

// MARK: - CategoryViewModelDelegate
protocol CategoryViewModelDelegate: AnyObject {
    func didSelectCategory(_ category: TrackerCategory?)
}

// MARK: - CategoryViewModel
final class CategoryViewModel {
    
    // MARK: - Properties
    private let categoryStore: TrackerCategoryStore
    weak var delegate: CategoryViewModelDelegate?
    
    // MARK: - Bindings (замыкания для связи с View)
    var onCategoriesUpdated: (() -> Void)?
    var onSelectionChanged: ((Int?) -> Void)?
    var onError: ((String) -> Void)?
    
    // MARK: - Private Properties
    private var categories: [TrackerCategory] = []
    private var selectedCategoryIndex: Int?
    
    // MARK: - Computed Properties
    var numberOfCategories: Int {
        return categories.count
    }
    
    var selectedCategory: TrackerCategory? {
        guard let index = selectedCategoryIndex,
              index < categories.count else { return nil }
        return categories[index]
    }
    
    // MARK: - Initialization
    init(categoryStore: TrackerCategoryStore = TrackerCategoryStore()) {
        self.categoryStore = categoryStore
        setupStoreDelegate()
        setupFetchedResultsController()
    }
    
    // MARK: - Public Methods
    
    /// Загрузить категории из Core Data
    func loadCategories() {
        do {
            // Используем NSFetchedResultsController для получения данных
            let categoriesCD = categoryStore.allCategories()
            print("DEBUG: Загружено категорий из Core Data: \(categoriesCD.count)")
            categories = categoriesCD.compactMap { categoryCD in
                guard let title = categoryCD.title else { return nil }
                return TrackerCategory(title: title, trackers: [])
            }
            print("DEBUG: Обработано категорий: \(categories.count)")
            onCategoriesUpdated?()
        } catch {
            print("DEBUG: Ошибка загрузки категорий: \(error)")
            onError?("Ошибка загрузки категорий: \(error.localizedDescription)")
        }
    }
    
    /// Получить данные для ячейки по индексу
    func getCategoryData(for index: Int) -> (title: String, isSelected: Bool)? {
        guard index < categories.count else { return nil }
        let category = categories[index]
        let isSelected = selectedCategoryIndex == index
        return (title: category.title, isSelected: isSelected)
    }
    
    /// Выбрать категорию по индексу
    func selectCategory(at index: Int) {
        guard index < categories.count else { return }
        selectedCategoryIndex = index
        onSelectionChanged?(selectedCategoryIndex)
    }
    
    /// Снять выбор с категории
    func deselectCategory() {
        selectedCategoryIndex = nil
        onSelectionChanged?(nil)
    }
    
    /// Подтвердить выбор категории
    func confirmSelection() {
        delegate?.didSelectCategory(selectedCategory)
    }
    
    /// Установить выбранную категорию по названию
    func setSelectedCategory(_ category: TrackerCategory?) {
        guard let category = category else {
            selectedCategoryIndex = nil
            onSelectionChanged?(nil)
            return
        }
        
        // Находим индекс категории по названию
        for (index, cat) in categories.enumerated() {
            if cat.title == category.title {
                selectedCategoryIndex = index
                onSelectionChanged?(index)
                return
            }
        }
        selectedCategoryIndex = nil
        onSelectionChanged?(nil)
    }
    
    /// Добавить новую категорию
    func addCategory(title: String) {
        do {
            _ = try categoryStore.addCategory(title: title)
            // Данные обновятся через NSFetchedResultsController
        } catch {
            onError?("Ошибка добавления категории: \(error.localizedDescription)")
        }
    }
    
    /// Обновить категорию
    func updateCategory(at index: Int, newTitle: String) {
        guard index < categories.count else { return }
        
        do {
            let categoryCD = categoryStore.category(at: index)
            categoryCD.title = newTitle
            try categoryStore.context.save()
            // Данные обновятся через NSFetchedResultsController
        } catch {
            onError?("Ошибка обновления категории: \(error.localizedDescription)")
        }
    }
    
    /// Удалить категорию
    func deleteCategory(at index: Int) {
        guard index < categories.count else { return }
        
        do {
            let categoryCD = categoryStore.category(at: index)
            categoryStore.context.delete(categoryCD)
            try categoryStore.context.save()
            // Данные обновятся через NSFetchedResultsController
        } catch {
            onError?("Ошибка удаления категории: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Private Methods
    private func setupStoreDelegate() {
        categoryStore.delegate = self
    }
    
    private func setupFetchedResultsController() {
        do {
            try categoryStore.performFetch()
        } catch {
            onError?("Ошибка инициализации FRC: \(error.localizedDescription)")
        }
    }
}

// MARK: - StoreChangesDelegate
extension CategoryViewModel: StoreChangesDelegate {
    func storeWillChangeContent() {
        // Можно добавить анимацию загрузки
    }
    
    func storeDidChangeSection(at sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        // Обработка изменений секций (если понадобится)
    }
    
    func storeDidChangeObject(at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        // Обновляем данные при изменениях в Core Data
        print("DEBUG: StoreDidChangeObject - type: \(type), indexPath: \(String(describing: indexPath)), newIndexPath: \(String(describing: newIndexPath))")
        loadCategories()
    }
    
    func storeDidChangeContent() {
        // Обновление завершено
    }
}
