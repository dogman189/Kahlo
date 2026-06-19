import SwiftUI

struct LLMAnalysisView: View {
    @ObservedObject var llm: LLMService

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                SectionLabel(text: "LOCAL LLM ANALYSIS")
                Spacer()
                if llm.isAnalyzing {
                    ProgressView()
                        .scaleEffect(0.7)
                        .tint(.cyan)
                }
            }

            if !llm.isEnabled {
                VStack(spacing: 8) {
                    Image(systemName: "brain.head.profile")
                        .font(.title2)
                        .foregroundColor(.gray)
                    Text("LLM analysis is disabled")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("Enable it in Settings to run on-device analysis")
                        .font(.caption2)
                        .foregroundColor(.gray.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else if let error = llm.errorMessage {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.caution)
                    Text("Analysis failed")
                        .font(.caption)
                        .foregroundColor(.caution)
                    Text(error)
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            } else if let analysis = llm.lastAnalysis {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        SignalBadge(signal: analysis.signal)
                        Spacer()
                        Text("\(String(format: "%.0f", analysis.confidence * 100))% confidence")
                            .font(.monoSmall)
                            .foregroundColor(.mutedLabel)
                    }

                    Text(analysis.summary)
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(.primary)
                        .lineLimit(4)
                        .fixedSize(horizontal: false, vertical: true)

                    if !analysis.risks.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("RISKS")
                                .font(.sectionHeader)
                                .foregroundColor(.caution)
                            ForEach(analysis.risks, id: \.self) { risk in
                                Text("• \(risk)")
                                    .font(.monoSmall)
                                    .foregroundColor(.gray)
                            }
                        }
                    }

                    if let raw = llm.rawResponse {
                        DisclosureGroup("Full Response") {
                            ScrollView(.horizontal) {
                                Text(raw)
                                    .font(.system(size: 9, design: .monospaced))
                                    .foregroundColor(.gray)
                                    .textSelection(.enabled)
                            }
                            .frame(maxHeight: 120)
                        }
                        .font(.caption2)
                        .foregroundColor(.gray)
                    }
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.title2)
                        .foregroundColor(.gray)
                    Text("Waiting for market data...")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
        }
    }
}

struct SignalBadge: View {
    let signal: TradeSignal

    var color: Color {
        switch signal {
        case .bullish: return .positive
        case .bearish: return .negative
        case .neutral: return .gray
        }
    }

    var body: some View {
        Text(signal.rawValue)
            .font(.pillText)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(4)
    }
}
