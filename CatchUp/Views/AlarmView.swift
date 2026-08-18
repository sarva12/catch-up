import SwiftUI

struct AlarmView: View {
    @Environment(AppStore.self) private var store
    @State private var isSaving = false

    var body: some View {
        @Bindable var store = store
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                Text("MORNING ALARM")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .tracking(2.5)

                Text("Start the day\nwith context.")
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .tracking(-1.2)

                DatePicker("Alarm time", selection: $store.alarmTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 10) {
                    Label("Every day", systemImage: "repeat")
                    Label("Breaks through Silent Mode and Focus", systemImage: "speaker.wave.2")
                    Label("Tap Start Catch-up to open the briefing", systemImage: "newspaper")
                }
                .font(.system(size: 14, weight: .medium, design: .rounded))

                Button {
                    isSaving = true
                    Task {
                        await store.saveAlarm()
                        isSaving = false
                    }
                } label: {
                    HStack {
                        if isSaving { ProgressView().tint(.white) }
                        Text(store.alarmEnabled ? "UPDATE ALARM" : "SET DAILY ALARM")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(MonochromeButtonStyle(filled: true))
                .disabled(isSaving)

                if store.alarmEnabled {
                    Button("TURN OFF ALARM") { store.disableAlarm() }
                        .buttonStyle(MonochromeButtonStyle(filled: false))
                        .frame(maxWidth: .infinity)
                }

                if let message = store.alarmMessage {
                    Text(message)
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                Text("The standard Stop control cannot automatically open an iPhone app. Use the Start Catch-up action shown on the alarm.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(20)
        }
        .toolbar(.hidden, for: .navigationBar)
        .background(Color.white)
    }
}


