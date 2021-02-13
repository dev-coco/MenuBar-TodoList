import Cocoa

protocol EditTodosWindowControllerDelegate: AnyObject {
    func editTodosWindowControllerDidUpdateTodoItems(_ controller: EditTodosWindowController)
}

class EditTodosWindowController: NSWindowController {
    @IBOutlet private weak var tableView: NSTableView!
    weak var delegate: EditTodosWindowControllerDelegate?
    var todoItemsHelper: TodoItemsHelper?
    private var addTodoPanel: NSPanel?
    override var windowNibName: NSNib.Name? {
        return NSNib.Name("EditTodosWindowController")
    }
    override func windowDidLoad() {
        super.windowDidLoad()
    }
    override func showWindow(_ sender: Any?) {
        window?.center()
        window?.makeFirstResponder(nil)
        window?.makeKeyAndOrderFront(self)
        tableView.reloadData()
    }
    private func hideAddTodoPanel() {
        guard let window = window, let panel = addTodoPanel else { return }
        window.endSheet(panel)
    }
    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        return true
    }
    @objc private func checkboxButtonStateChanged(_ sender: NSButton) {
        guard let todoItemsHelper = todoItemsHelper else { return }
        let todoItem = todoItemsHelper.todoItems[sender.tag]
        todoItemsHelper.mark(todoItem: todoItem, completed: sender.state == .on)
        tableView.reloadData(
            forRowIndexes: IndexSet(integer: sender.tag),
            columnIndexes: IndexSet(integer: 1)
        )
        delegate?.editTodosWindowControllerDidUpdateTodoItems(self)
    }
    @IBAction private func doubleClick(_ sender: NSTableView) {
        let row = sender.clickedRow
        guard
            row != -1,
            let view = tableView.view(
                atColumn: 1, row: row, makeIfNecessary: false
            ) as? NSTableCellView,
            let textField = view.textField
        else {
            return
        }
        textField.isEditable = true
        textField.target = self
        textField.action = #selector(todoTextFieldDidEndEditing(_:))
        textField.tag = row
        if textField.acceptsFirstResponder {
            window?.makeFirstResponder(textField)
        }
    }
    @IBAction private func addButtonPressed(_ sender: NSButton) {
        let addTodoViewController = AddTodoViewController()
        addTodoViewController.delegate = self
        guard let window = window else { return }
        let panel = NSPanel(contentViewController: addTodoViewController)
        var styleMask = panel.styleMask
        styleMask.remove(.resizable)
        panel.styleMask = styleMask
        self.addTodoPanel = panel
        window.beginSheet(panel)
    }
    @IBAction private func clearAllButtonPressed(_ sender: NSButton) {
        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.messageText = "你确定要删除所有待办事项吗？"
        alert.addButton(withTitle: "否")
        alert.addButton(withTitle: "是")
        let response = alert.runModal()
        if response == .alertSecondButtonReturn {
            todoItemsHelper?.deleteAll()
            tableView.reloadData()
            delegate?.editTodosWindowControllerDidUpdateTodoItems(self)
        }
    }
    @objc func todoTextFieldDidEndEditing(_ sender: NSTextField) {
        defer {
            sender.isEditable = false
        }
        guard let todoItemsHelper = todoItemsHelper else { return }
        let todoItem = todoItemsHelper.todoItems[sender.tag]  // #1
        todoItemsHelper.update(title: sender.stringValue, for: todoItem)
        delegate?.editTodosWindowControllerDidUpdateTodoItems(self)
    }
    @objc func deleteMenuItemPressed(_ sender: NSMenuItem) {
        guard
            let todoItemsHelper = todoItemsHelper,
            let todoItem = sender.representedObject as? TodoItem,
            let index = todoItemsHelper.todoItems.index(of: todoItem)
        else {
            return
        }
        todoItemsHelper.deleteTodoItem(at: index)
        tableView.reloadData()
        delegate?.editTodosWindowControllerDidUpdateTodoItems(self)
    }
}
extension EditTodosWindowController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return todoItemsHelper?.todoItems.count ?? 0
    }
}
extension EditTodosWindowController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard
            let todoItem = todoItemsHelper?.todoItems[row],
            let identifier = tableColumn?.identifier,
            let cellView = tableView.makeView(
                withIdentifier: identifier, owner: self
            ) as? NSTableCellView
        else {
            return nil
        }
        if identifier.rawValue == "TextCell" {
            if todoItem.completed {
                let attributes: [NSAttributedStringKey : Any] = [
                    .strikethroughStyle: NSUnderlineStyle.styleSingle.rawValue,
                    .font: NSFont.menuFont(ofSize: 0)
                ]
                let attributedString = NSAttributedString(
                    string: todoItem.title,
                    attributes: attributes
                )
                cellView.textField?.attributedStringValue = attributedString
            } else {
                cellView.textField?.stringValue = todoItem.title
            }
            if let cellView = cellView as? TodoItemTableCellView {
                cellView.todoItem = todoItem
            }
        } else if identifier.rawValue == "CheckboxCell" {
            if let cellView = cellView as? CheckboxTableCellView {
                cellView.checkboxButton.state = todoItem.completed ? .on : .off
                cellView.checkboxButton.tag = row
                cellView.checkboxButton.target = self
                cellView.checkboxButton.action = #selector(checkboxButtonStateChanged(_:))
            }
        }
        return cellView
    }    
}
extension EditTodosWindowController: AddTodoViewControllerDelegate {
    func addTodoViewController(_ controller: AddTodoViewController, didAddTodoWith title: String) {
        todoItemsHelper?.addTodoItem(title: title)
        delegate?.editTodosWindowControllerDidUpdateTodoItems(self)
        tableView.reloadData()
        hideAddTodoPanel()
    }
    func addTodoViewControllerDidCancel(_ controller: AddTodoViewController) {
        hideAddTodoPanel()
    }
}
