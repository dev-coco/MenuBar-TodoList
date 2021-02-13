import Cocoa

class TodoItemTableCellView: NSTableCellView {
    var todoItem: TodoItem?
    override func menu(for event: NSEvent) -> NSMenu? {
        let menuItem = NSMenuItem(
            title: "删除",
            action: #selector(EditTodosWindowController.deleteMenuItemPressed(_:)),
            keyEquivalent: ""
        )
        menuItem.representedObject = todoItem
        let menu = NSMenu()
        menu.addItem(menuItem)
        return menu
    }
}
