//
//  CategoryViewModel.swift
//  Tracker
//
//  Created by Илья on 19.10.2025.
//

import Foundation


// MARK: - CategoryViewModelDelegate
protocol CategoryViewModelDelegate: AnyObject {
    func didSelectCategory(_ category: TrackerCategory?)
}

// MARK: - CategoryViewModelProtocol
protocol CategoryViewModelProtocol: AnyObject {
    // MARK: - Properties
    var delegate: CategoryViewModelDelegate? { get set }
    
    // MARK: - Bindings
    var onCategoriesUpdated: (() -> Void)? { get set }
    var onSelectionChanged: ((Int?) -> Void)? { get set }
    var onError: ((String) -> Void)? { get set }
    
    // MARK: - Computed Properties
    var numberOfCategories: Int { get }
    var selectedCategory: TrackerCategory? { get }
    
    // MARK: - Public Methods
    func loadCategories()
    func getCategoryData(for index: Int) -> TrackerCategory?
    func getCategoryDataForCell(for index: Int) -> (title: String, isSelected: Bool)?
    func selectCategory(at index: Int)
    func addCategory(_ title: String)
    func updateCategory(at index: Int, newTitle: String)
    func deleteCategory(at index: Int)
    func setSelectedCategory(_ category: TrackerCategory?)
}

// MARK: - CategoryViewModel
final class CategoryViewModel: CategoryViewModelProtocol {
    
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
            categories = categoriesCD.compactMap { categoryCD in
                guard let title = categoryCD.title else { return nil }
                return TrackerCategory(title: title, trackers: [])
            }
            onCategoriesUpdated?()
        } catch {
            onError?("Ошибка загрузки категорий: \(error.localizedDescription)")
        }
    }
    
    /// Получить данные для ячейки по индексу
    func getCategoryData(for index: Int) -> TrackerCategory? {
        guard index < categories.count else { return nil }
        return categories[index]
    }
    
    /// Получить данные для ячейки по индексу (старый метод для совместимости)
    func getCategoryDataForCell(for index: Int) -> (title: String, isSelected: Bool)? {
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
    func addCategory(_ title: String) {
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
    
    func storeDidChangeSection(at sectionIndex: Int, for type: StoreChangeType) {
        // Обработка изменений секций (если понадобится)
    }
    
    func storeDidChangeObject(at indexPath: IndexPath?, for type: StoreChangeType, newIndexPath: IndexPath?) {
        // Обновляем данные при изменениях в Core Data
        loadCategories()
    }
    
    func storeDidChangeContent() {
        // Обновление завершено
    }
}
