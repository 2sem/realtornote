import SwiftUI

enum AppearanceMode: String, CaseIterable {
    case system
    case light
    case dark

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }

    var title: String {
        switch self {
        case .system: return "시스템 따라가기"
        case .light:  return "항상 라이트"
        case .dark:   return "항상 다크"
        }
    }

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light:  return "sun.max"
        case .dark:   return "moon"
        }
    }
}
