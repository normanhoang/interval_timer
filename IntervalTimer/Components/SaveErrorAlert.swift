import SwiftData
import SwiftUI

extension ModelContext {
    /// Saves, rolling the context back so a failed write can't leave half-applied
    /// edits in memory. The underlying error goes to the log, never to the user.
    @discardableResult
    func saveOrRollback(_ operation: String) -> Bool {
        do {
            try save()
            return true
        } catch {
            rollback()
            AppLog.persistence.error(
                "\(operation, privacy: .public) failed: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }
}

extension View {
    /// The standard "your edit didn't stick" alert shared by the editing screens.
    func saveErrorAlert(_ title: String, isPresented: Binding<Bool>) -> some View {
        alert(title, isPresented: isPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your changes weren’t saved. Please try again.")
        }
    }
}
