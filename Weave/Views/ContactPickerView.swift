import ContactsUI
import SwiftUI

/// Multi-select system contact picker. Returns the chosen contacts;
/// the caller decides how to turn them into People.
struct ContactPickerView: UIViewControllerRepresentable {
    var onSelect: ([CNContact]) -> Void

    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onSelect: onSelect)
    }

    final class Coordinator: NSObject, CNContactPickerDelegate {
        let onSelect: ([CNContact]) -> Void

        init(onSelect: @escaping ([CNContact]) -> Void) {
            self.onSelect = onSelect
        }

        func contactPicker(_ picker: CNContactPickerViewController, didSelect contacts: [CNContact]) {
            onSelect(contacts)
        }

        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            onSelect([contact])
        }
    }
}
