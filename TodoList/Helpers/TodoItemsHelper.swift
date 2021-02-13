import Foundation

class TodoItemsHelper {
    private let itemsKey = "TodoItems"
    private(set) var todoItems = [TodoItem]()
    init() {
        guard
            let data = UserDefaults.standard.object(forKey: itemsKey) as? Data,
            let items = NSKeyedUnarchiver.unarchiveObject(with: data) as? [TodoItem]
        else {
            return
        }
        todoItems = items
    }
    func mark(todoItem: TodoItem, completed: Bool) {
        todoItem.completed = completed
        saveTodoItems()
    }
    func addTodoItem(title: String) {
        let todoItem = TodoItem(title: title)
        todoItems.append(todoItem)
        saveTodoItems()
    }
    func deleteAll() {
        todoItems.removeAll()
        saveTodoItems()
    }
    func deleteTodoItem(at index: Int) {
        todoItems.remove(at: index)
        saveTodoItems()
    }
    func update(title: String, for todoItem: TodoItem) {
        todoItem.title = title
        saveTodoItems()
    }
    private func saveTodoItems() {
        let data = NSKeyedArchiver.archivedData(withRootObject: todoItems)
        UserDefaults.standard.set(data, forKey: itemsKey)
    }
}
