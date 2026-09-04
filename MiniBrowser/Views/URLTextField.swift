import SwiftUI
import UIKit

struct URLTextField: UIViewRepresentable {
    @Binding var text: String
    let onGo: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> UITextField {
        let field = UITextField()
        field.delegate = context.coordinator
        field.borderStyle = .roundedRect
        field.clearButtonMode = .whileEditing
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.spellCheckingType = .no
        field.keyboardType = .URL
        field.returnKeyType = .go
        field.textContentType = .URL
        field.placeholder = "https://example.com"

        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        toolbar.items = [
            UIBarButtonItem(systemItem: .flexibleSpace),
            UIBarButtonItem(title: "完了",
                            style: .done,
                            target: context.coordinator,
                            action: #selector(Coordinator.dismissKeyboard))
        ]
        field.inputAccessoryView = toolbar
        return field
    }

    func updateUIView(_ field: UITextField, context: Context) {
        if field.text != text {
            field.text = text
        }
        context.coordinator.parent = self
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: URLTextField
        weak var field: UITextField?

        init(parent: URLTextField) {
            self.parent = parent
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            field = textField
            DispatchQueue.main.async {
                textField.selectAll(nil)
            }
        }

        func textFieldDidChangeSelection(_ textField: UITextField) {
            parent.text = textField.text ?? ""
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            parent.text = textField.text ?? ""
            parent.onGo()
            textField.resignFirstResponder()
            return true
        }

        @objc func dismissKeyboard() {
            field?.resignFirstResponder()
        }
    }
}

