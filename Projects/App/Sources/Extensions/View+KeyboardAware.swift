//
//  View+KeyboardAware.swift
//  realtornote
//
//  Created by Claude Code
//

import SwiftUI
import Combine

extension View {
    /// Observes keyboard will show notification and executes the action
    /// - Parameter action: Closure that receives the notification
    /// - Returns: A view that responds to keyboard will show events
    func keyboardWillShow(perform action: @escaping (Notification) -> Void) -> some View {
        onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
            action(notification)
        }
    }
    
    /// Observes keyboard will hide notification and executes the action
    /// - Parameter action: Closure that receives the notification
    /// - Returns: A view that responds to keyboard will hide events
    func keyboardWillHide(perform action: @escaping (Notification) -> Void) -> some View {
        onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { notification in
            action(notification)
        }
    }
}
