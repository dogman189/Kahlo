import SwiftUI

struct ChatFloatingButton: View {
    @ObservedObject var engine: TradingEngine
    @State private var showSheet = false

    var body: some View {
        Button(action: { showSheet = true }) {
            HStack(spacing: 6) {
                Image(systemName: "message.fill")
                    .font(.system(size: 12))
                Text("Ask AI")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                LinearGradient(
                    colors: [.cyan.opacity(0.8), .purple.opacity(0.6)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(20)
            .shadow(color: .cyan.opacity(0.3), radius: 8, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showSheet) {
            NavigationView {
                ChatView(engine: engine)
                    .navigationTitle("AI Chat")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showSheet = false
                            }
                            .font(.caption)
                            .foregroundColor(.cyan)
                        }
                    }
            }
            .preferredColorScheme(.dark)
        }
    }
}
