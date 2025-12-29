//
//  SearchBar.swift
//  App
//
//  Custom search bar component for PartScreen
//

import SwiftUI

struct SearchBar: View {
    @Binding var searchText: String
    @FocusState.Binding var isFocused: Bool
    let hasResults: Bool
    let onCancel: () -> Void
    let onSubmit: () -> Void
    let onPrevious: () -> Void
    let onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white.opacity(0.7))
                    
                    TextField("검색", text: $searchText)
                        .focused($isFocused)
                        .textFieldStyle(.plain)
                        .foregroundColor(.white)
                        .submitLabel(.search)
                        .onSubmit {
                            onSubmit()
                            isFocused = false  // Hide keyboard on return
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
                .padding(8)
                .background(Color.white.opacity(0.2))
                .cornerRadius(10)
                
                // Navigation buttons (shown only when there are results)
                if hasResults {
                    Button(action: onPrevious) {
                        Image(systemName: "chevron.up")
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .frame(width: 32, height: 32)
                    
                    Button(action: onNext) {
                        Image(systemName: "chevron.down")
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .frame(width: 32, height: 32)
                }
                
                Button("취소") {
                    onCancel()
                }
                .foregroundColor(.white)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(
            Color(red: 0.506, green: 0.831, blue: 0.980)
                .ignoresSafeArea(edges: .top)
        )
        .safeAreaPadding(.top) // Add safe area padding at the top
    }
}
