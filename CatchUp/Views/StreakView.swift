import SwiftUI

struct StreakView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            Text("YOUR STREAK")
                .font(.system(size: 13, weight: .black, design: .rounded))
                .tracking(2.5)

            Spacer()

            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text("\(store.progress.currentStreak)")
                    .font(.system(size: 112, weight: .black, design: .rounded))
                    .tracking(-6)
                Text("DAYS")
                    .font(.system(size: 16, weight: .black, design: .monospaced))
            }

            Text(store.progress.currentStreak == 0 ? "Finish today's briefing to begin." : "Keep showing up. A few informed minutes is enough.")
                .font(.system(size: 22, weight: .bold, design: .serif))
                .lineSpacing(4)

            Divider().overlay(Color.black)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("BEST")
                    Text("\(store.progress.longestStreak) days")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                }
                Spacer()
                Image(systemName: "flame.fill")
                    .font(.system(size: 42))
            }
            .font(.system(size: 11, weight: .black, design: .monospaced))

            Spacer()
        }
        .padding(20)
        .toolbar(.hidden, for: .navigationBar)
        .background(Color.white)
    }
}


