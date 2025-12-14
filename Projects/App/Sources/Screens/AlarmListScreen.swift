//
//  AlarmListScreen.swift
//  realtornote
//
//  Created by Claude Code
//

import SwiftUI
import SwiftData

struct AlarmListScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Alarm.id) private var alarms: [Alarm]
    
    @State private var model: AlarmListScreenModel?
    @State private var navigationPath = NavigationPath()
    
    // Theme colors matching app
    private let backgroundColor = Color(red: 0.506, green: 0.831, blue: 0.980)
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if let model = model {
                    content(model: model)
                } else {
                    ProgressView()
                        .tint(.white)
                }
            }
            .scrollContentBackground(.hidden)
            .background(backgroundColor.ignoresSafeArea())
            .navigationTitle("공부시간 알림")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(backgroundColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        navigationPath.append(AlarmEditMode.create)
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(.white)
                    }
                }
            }
            .navigationDestination(for: AlarmEditMode.self) { mode in
                switch mode {
                case .create:
                    let settingsModel = AlarmSettingsScreenModel(
                        alarm: nil,
                        subject: nil,
                        modelContext: modelContext,
                        onSave: { weekDays, time in
                            model?.createAlarm(weekDays: weekDays, time: time)
                            navigationPath.removeLast()
                        }
                    )
                    AlarmSettingsScreen(model: settingsModel)
                    
                case .edit(let alarm):
                    let settingsModel = AlarmSettingsScreenModel(
                        alarm: alarm,
                        subject: nil,
                        modelContext: modelContext,
                        onSave: { weekDays, time in
                            model?.updateAlarm(alarm, weekDays: weekDays, time: time)
                            navigationPath.removeLast()
                        }
                    )
                    AlarmSettingsScreen(model: settingsModel)
                }
            }
            .onAppear {
                if model == nil {
                    model = AlarmListScreenModel(modelContext: modelContext, alarms: alarms)
                }
                configureNavigationBarAppearance()
            }
            .onChange(of: alarms) { _, newAlarms in
                model?.updateAlarms(newAlarms)
            }
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
    private func content(model: AlarmListScreenModel) -> some View {
        if alarms.isEmpty {
            VStack(spacing: 16) {
                Spacer()
                Image(systemName: "bell.slash")
                    .font(.system(size: 60))
                    .foregroundColor(.white.opacity(0.6))
                Text("설정된 알림이 없습니다")
                    .font(.headline)
                    .foregroundColor(.white)
                Text("+ 버튼을 눌러 알림을 추가하세요")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
        } else {
            List {
                ForEach(Array(alarms.enumerated()), id: \.element.id) { index, alarm in
                    AlarmListCell(
                        alarm: alarm,
                        isFirst: index == 0,
                        onToggle: { isOn in
                            model.toggleAlarm(alarm, enabled: isOn)
                        },
                        onDelete: {
                            model.showDeleteConfirmation(for: alarm)
                        },
                        onEdit: {
                            navigationPath.append(AlarmEditMode.edit(alarm))
                        }
                    )
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.plain)
            .alert("알림 삭제", isPresented: Binding(
                get: { model.showDeleteAlert },
                set: { model.showDeleteAlert = $0 }
            )) {
                Button("삭제", role: .destructive) {
                    if let alarmToDelete = model.alarmToDelete {
                        model.deleteAlarm(alarmToDelete)
                    }
                }
                Button("취소", role: .cancel) {}
            } message: {
                Text("공부 알림을 삭제하시겠습니까?")
            }
        }
    }
}

// Navigation mode for alarm editing
enum AlarmEditMode: Hashable {
    case create
    case edit(Alarm)
}

struct AlarmListCell: View {
    let alarm: Alarm
    let isFirst: Bool
    let onToggle: (Bool) -> Void
    let onDelete: () -> Void
    let onEdit: () -> Void
    
    // Theme colors matching RNAlarmTableViewCell
    private let enabledBackgroundColor = Color(red: 0, green: 0.667, blue: 0.983).opacity(0.3)
    private let disabledBackgroundColor = Color(red: 0.976, green: 0.977, blue: 0.976)
    private let enabledBorderColor = Color(red: 0, green: 0.667, blue: 0.983).opacity(0.1)
    private let disabledBorderColor = Color(red: 0.947, green: 0.947, blue: 0.947)
    
    var body: some View {
        Button {
            onEdit()
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(alarm.subject?.name ?? "최근 과목")
                        .font(.headline)
                        .foregroundColor(alarm.enabled ? .primary : .gray)
                    
                    Text(alarm.alarmDescription)
                        .font(.subheadline)
                        .foregroundColor(alarm.enabled ? .primary : .gray)
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    if !isFirst {
                        Button {
                            onDelete()
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                                .frame(width: 44, height: 44)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Toggle("", isOn: Binding(
                        get: { alarm.enabled },
                        set: { newValue in
                            onToggle(newValue)
                        }
                    ))
                    .labelsHidden()
                    .tint(Color(red: 0.239, green: 0.675, blue: 0.969))
                }
            }
            .padding(16)
            .background(alarm.enabled ? enabledBackgroundColor : disabledBackgroundColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        alarm.enabled ? enabledBorderColor : disabledBorderColor,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        AlarmListScreen()
            .modelContainer(for: [Alarm.self, Subject.self])
    }
}
