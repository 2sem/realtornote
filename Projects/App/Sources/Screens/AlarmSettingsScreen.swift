//
//  AlarmSettingsScreen.swift
//  realtornote
//
//  Created by Claude Code
//

import SwiftUI
import SwiftData
import LSExtensions

struct AlarmSettingsScreen: View {
    @Environment(\.dismiss) private var dismiss
    
    let model: AlarmSettingsScreenModel
    
    // Theme colors matching app
    private let backgroundColor = Color(red: 0.506, green: 0.831, blue: 0.980)
    
    init(model: AlarmSettingsScreenModel) {
        self.model = model
    }
    
    var body: some View {
        content(model: model)
            .scrollContentBackground(.hidden)
            .background(backgroundColor)
            .navigationTitle("알림 설정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(backgroundColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onAppear {
                configureNavigationBarAppearance()
            }
    }
    
    private func configureNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.506, green: 0.831, blue: 0.980, alpha: 1.0)
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
    }
    
    @ViewBuilder
    private func content(model: AlarmSettingsScreenModel) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                WeekDayPicker(
                    selectedWeekDays: model.selectedWeekDays,
                    allWeekDays: model.allWeekDays,
                    onToggleWeekDay: { model.toggleWeekDay($0) },
                    onToggleAll: { model.toggleAll() }
                )

                AlarmTimePicker(
                    selectedTime: Binding(
                        get: { model.selectedTime },
                        set: { model.selectedTime = $0 }
                    )
                )

                // Error message
                if model.showError {
                    Text("적어도 하나 이상의 요일을 선택해야합니다")
                        .font(.callout)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color.white)
                        .cornerRadius(8)
                }

                ActionButtons(
                    backgroundColor: backgroundColor,
                    onCancel: { dismiss() },
                    onApply: {
                        Task {
                            if await model.applySettings() {
                                dismiss()
                            }
                        }
                    }
                )
            }
            .padding([.top, .horizontal])
        }
    }

}

// MARK: - WeekDayPicker Component

struct WeekDayPicker: View {
    let selectedWeekDays: DateComponents.DateWeekDay
    let allWeekDays: [DateComponents.DateWeekDay]
    let onToggleWeekDay: (DateComponents.DateWeekDay) -> Void
    let onToggleAll: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("요일 선택")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.leading, 8)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(allWeekDays, id: \.rawValue) { weekDay in
                        WeekDayButton(
                            title: weekDay.string,
                            isSelected: selectedWeekDays.contains(weekDay)
                        ) {
                            onToggleWeekDay(weekDay)
                        }
                    }
                }
                .padding(.horizontal, 8)
            }

            // Select All button
            Button {
                onToggleAll()
            } label: {
                Text(selectedWeekDays == .All ? "전체 해제" : "전체 선택")
                    .font(.body)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 8)
        }
    }
}

// MARK: - WeekDayButton Component

struct WeekDayButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    private let backgroundColor = Color(red: 0.506, green: 0.831, blue: 0.980)

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? backgroundColor : .white)
                .frame(width: 50, height: 50)
                .background(isSelected ? Color.white : Color.white.opacity(0.2))
                .cornerRadius(25)
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(Color.white, lineWidth: 2)
                )
        }
    }
}

// MARK: - AlarmTimePicker Component

struct AlarmTimePicker: View {
    @Binding var selectedTime: DateComponents

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("시간 선택")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.leading, 8)

            DatePicker(
                "",
                selection: Binding(
                    get: {
                        Calendar.current.date(from: selectedTime) ?? Date()
                    },
                    set: { newDate in
                        selectedTime = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                    }
                ),
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .colorScheme(.dark)
        }
    }
}

// MARK: - ActionButtons Component

struct ActionButtons: View {
    let backgroundColor: Color
    let onCancel: () -> Void
    let onApply: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Button {
                onCancel()
            } label: {
                Text("취소")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white.opacity(0.3))
                    .cornerRadius(10)
            }

            Button {
                onApply()
            } label: {
                Text("적용")
                    .font(.headline)
                    .foregroundColor(backgroundColor)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Alarm.self, Subject.self, configurations: config)
    let context = ModelContext(container)
    
    let model = AlarmSettingsScreenModel(
        alarm: nil,
        subject: nil,
        modelContext: context,
        onSave: nil
    )
    
    return NavigationStack {
        AlarmSettingsScreen(model: model)
    }
}
