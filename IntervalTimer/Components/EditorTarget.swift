import SwiftUI

/// Identifies what the editor sheet should edit.
enum EditorTarget: Identifiable {
    case new
    case edit(Workout)

    var id: String {
        switch self {
        case .new: return "new"
        case .edit(let workout): return workout.uuid.uuidString
        }
    }
}
