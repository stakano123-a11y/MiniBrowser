import Foundation
import SwiftUI

enum ToastKind {
    case success
    case failure
    case warning

    var color: Color {
        switch self {
        case .success: return .green
        case .failure: return .red
        case .warning: return .yellow
        }
    }

    var foregroundColor: Color {
        switch self {
        case .warning: return .black
        case .success, .failure: return .white
        }
    }
}


struct ToastMessage: Identifiable {
    let id = UUID()
    let text: String
    let kind: ToastKind
}
