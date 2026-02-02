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
    private let backgroundColor = Color.themeBackground
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if let model = model {
                    content(model: model)
                } else {
                    ProgressView()
                        .tint(Color.themePrimary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(backgroundColor.ignoresSafeArea())
            .navigationTitle("공부시간 알림")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if #available(iOS 26.0, *) {
                        Button(role: .close) {
                            dismiss()
                        }.tint(.accentColor)
                    } else {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                        }
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        navigationPath.append(AlarmEditMode.create)
                    } label: {
                        Image(systemName: "plus")
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
                            Task {
                                await model?.createAlarm(weekDays: weekDays, time: time)
                            }
                        }
                    )
                    AlarmSettingsScreen(model: settingsModel)

                case .edit(let alarm):
                    let settingsModel = AlarmSettingsScreenModel(
                        alarm: alarm,
                        subject: nil,
                        modelContext: modelContext,
                        onSave: { weekDays, time in
                            Task {
                                await model?.updateAlarm(alarm, weekDays: weekDays, time: time)
                            }
                        }
                    )
                    AlarmSettingsScreen(model: settingsModel)
                }
            }
            .onAppear {
                if model == nil {
                    model = AlarmListScreenModel(modelContext: modelContext, alarms: alarms)
                }
            }
            .onChange(of: alarms) { _, newAlarms in
                model?.updateAlarms(newAlarms)
            }
            .animation(.default, value: alarms.isEmpty)
        }
    }
    
    @ViewBuilder
    private func content(model: AlarmListScreenModel) -> some View {
        Group {
            if alarms.isEmpty {
                AlarmListEmptyView()
            } else {
                List {
                    ForEach(alarms, id: \.id) { alarm in
                        AlarmListCell(
                            alarm: alarm,
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
            }
        }
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

struct AlarmListEmptyView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "bell.slash")
                .font(.system(size: 60))
                .foregroundColor(Color.themePrimary.opacity(0.7))
            Text("설정된 알림이 없습니다")
                .font(.headline)
                .foregroundColor(Color.themePrimary)
            Text("+ 버튼을 눌러 알림을 추가하세요")
                .font(.subheadline)
                .foregroundColor(Color.themePrimary.opacity(0.8))
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// Navigation mode for alarm editing
enum AlarmEditMode: Hashable {
    case create
    case edit(Alarm)
}

struct AlarmListCell: View {
    let alarm: Alarm
    let onToggle: (Bool) -> Void
    let onDelete: () -> Void
    let onEdit: () -> Void
    
    // Theme colors matching RNAlarmTableViewCell
    private let enabledBackgroundColor = Color(red: 0, green: 0.667, blue: 0.983).opacity(0.3)
    private let disabledBackgroundColor = Color.themeDisabledBackground
    private let enabledBorderColor = Color(red: 0, green: 0.667, blue: 0.983).opacity(0.1)
    private let disabledBorderColor = Color.themeDisabledBorder
    
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
                    Button {
                            onDelete()
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                                .frame(width: 44, height: 44)
                        }
                        .buttonStyle(.plain)
                    
                    Toggle("", isOn: Binding(
                        get: { alarm.enabled },
                        set: { newValue in
                            onToggle(newValue)
                        }
                    ))
                    .labelsHidden()
                    .tint(Color.themeTint)
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
