import SwiftUI

struct AlarmView: View {
    @Environment(AppStore.self) private var store
    @State private var editor: AlarmEditor?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("ALARMS")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .tracking(2.5)
                        Text("Wake up.\nCatch up.")
                            .font(.system(size: 40, weight: .black, design: .rounded))
                            .tracking(-1.2)
                    }
                    Spacer()
                    Button { editor = AlarmEditor() } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .bold))
                            .frame(width: 50, height: 50)
                            .foregroundStyle(.white)
                            .background(Circle().fill(.black))
                    }
                    .accessibilityLabel("Add alarm")
                }

                if store.alarms.isEmpty {
                    EmptyAlarmCard { editor = AlarmEditor() }
                } else {
                    VStack(spacing: 12) {
                        ForEach(store.alarms) { alarm in
                            AlarmRow(
                                alarm: alarm,
                                onEdit: { editor = AlarmEditor(alarm: alarm) },
                                onToggle: { enabled in
                                    Task { await store.setAlarmEnabled(id: alarm.id, enabled: enabled) }
                                },
                                onDelete: { store.deleteAlarm(id: alarm.id) }
                            )
                        }
                    }
                }

                Button { editor = AlarmEditor() } label: {
                    Label("ADD ANOTHER ALARM", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(MonochromeButtonStyle(filled: true))

                if let message = store.alarmMessage {
                    Text(message)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.black.opacity(0.05))
                }

                VStack(alignment: .leading, spacing: 10) {
                    Label("System alarms ring through Silent Mode and Focus.", systemImage: "speaker.wave.2.fill")
                    Label("If SideStore signing blocks AlarmKit, Catch Up automatically uses a standard daily notification.", systemImage: "bell.badge")
                    Label("Tap Start Catch-up on a system alarm—or tap the notification—to open the briefing.", systemImage: "newspaper")
                }
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
            }
            .padding(20)
            .padding(.bottom, 24)
        }
        .sheet(item: $editor) { editor in
            AlarmEditorSheet(editor: editor)
        }
        .toolbar(.hidden, for: .navigationBar)
        .background(Color.white)
    }
}

private struct AlarmRow: View {
    let alarm: CatchUpAlarm
    let onEdit: () -> Void
    let onToggle: (Bool) -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                Button(action: onEdit) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(alarm.time.formatted(date: .omitted, time: .shortened))
                            .font(.system(size: 38, weight: .black, design: .rounded))
                            .tracking(-1)
                        Text(alarm.label)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)

                Toggle("", isOn: Binding(
                    get: { alarm.isEnabled },
                    set: { newValue in onToggle(newValue) }
                ))
                .labelsHidden()
                .tint(.black)
            }

            HStack(spacing: 8) {
                Text("EVERY DAY").alarmBadge()
                Text(deliveryLabel)
                    .alarmBadge(inverted: alarm.isEnabled && alarm.deliveryMode == .alarmKit)
                Spacer()
                Button(action: onEdit) {
                    Image(systemName: "pencil").frame(width: 34, height: 34)
                }
                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash").frame(width: 34, height: 34)
                }
            }
            .foregroundStyle(.black)
        }
        .padding(18)
        .background(Color.black.opacity(alarm.isEnabled ? 0.055 : 0.025))
        .overlay(Rectangle().stroke(Color.black.opacity(0.12), lineWidth: 1))
        .opacity(alarm.isEnabled ? 1 : 0.58)
    }

    private var deliveryLabel: String {
        guard alarm.isEnabled else { return "OFF" }
        switch alarm.deliveryMode {
        case .alarmKit: return "SYSTEM ALARM"
        case .notification: return "NOTIFICATION"
        case nil: return "SCHEDULING"
        }
    }
}

private struct EmptyAlarmCard: View {
    let addAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: "alarm")
                .font(.system(size: 30, weight: .bold))
            Text("No alarms yet")
                .font(.system(size: 24, weight: .black, design: .rounded))
            Text("Add as many daily alarms as you need. Each one can be edited, switched off, or deleted on its own.")
                .font(.system(size: 15, design: .rounded))
                .foregroundStyle(.secondary)
            Button("ADD FIRST ALARM", action: addAction)
                .buttonStyle(MonochromeButtonStyle(filled: false))
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(Rectangle().stroke(Color.black, lineWidth: 1))
    }
}

private struct AlarmEditor: Identifiable {
    let id = UUID()
    let alarmID: UUID?
    let time: Date
    let label: String

    init(alarm: CatchUpAlarm? = nil) {
        alarmID = alarm?.id
        time = alarm?.time
            ?? Calendar.current.date(from: DateComponents(hour: 7, minute: 0))
            ?? .now
        label = alarm?.label ?? "Morning catch-up"
    }
}

private struct AlarmEditorSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let editor: AlarmEditor
    @State private var time: Date
    @State private var label: String
    @State private var isSaving = false

    init(editor: AlarmEditor) {
        self.editor = editor
        _time = State(initialValue: editor.time)
        _label = State(initialValue: editor.label)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                DatePicker("Alarm time", selection: $time, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()

                TextField("Alarm label", text: $label)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .padding(14)
                    .overlay(Rectangle().stroke(Color.black, lineWidth: 1))

                Button {
                    isSaving = true
                    Task {
                        let saved = await store.saveAlarm(id: editor.alarmID, time: time, label: label)
                        isSaving = false
                        if saved { dismiss() }
                    }
                } label: {
                    HStack {
                        if isSaving { ProgressView().tint(.white) }
                        Text(editor.alarmID == nil ? "SAVE ALARM" : "SAVE CHANGES")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(MonochromeButtonStyle(filled: true))
                .disabled(isSaving)
                Spacer()
            }
            .padding(20)
            .navigationTitle(editor.alarmID == nil ? "New alarm" : "Edit alarm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.black)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

private extension View {
    func alarmBadge(inverted: Bool = false) -> some View {
        font(.system(size: 10, weight: .black, design: .monospaced))
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .foregroundStyle(inverted ? Color.white : Color.black)
            .background(inverted ? Color.black : Color.clear)
            .overlay(Rectangle().stroke(Color.black.opacity(0.4), lineWidth: 1))
    }
}

