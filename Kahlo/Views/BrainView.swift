import SwiftUI

struct BrainView: View {
    @ObservedObject var engine: TradingEngine
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                HStack {
                    Text("AI BRAIN & FORECAST")
                        .font(.system(.title2, design: .rounded))
                        .bold()
                        .foregroundColor(.primary)
                    Spacer()
                    
                    Text("v4.0")
                        .font(.system(.caption, design: .monospaced))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.purple.opacity(0.3))
                        .foregroundColor(.purple)
                        .cornerRadius(8)
                }
                .padding(.top, 10)
                
                // Forecast Card
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Current Forecast")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text(String(format: "%+.4f", engine.aiPrediction))
                            .font(.system(size: 32, weight: .bold, design: .monospaced))
                            .foregroundColor(engine.aiPrediction > 0.05 ? .green : (engine.aiPrediction < -0.05 ? .red : .gray))
                        
                        Text(engine.aiPrediction > 0.05 ? "BULLISH" : (engine.aiPrediction < -0.05 ? "BEARISH" : "NEUTRAL"))
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(engine.aiPrediction > 0.05 ? Color.green.opacity(0.2) : (engine.aiPrediction < -0.05 ? Color.red.opacity(0.2) : Color.gray.opacity(0.2)))
                            .foregroundColor(engine.aiPrediction > 0.05 ? .green : (engine.aiPrediction < -0.05 ? .red : .gray))
                            .cornerRadius(4)
                    }
                    
                    Divider().background(Color.white.opacity(0.1))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Accuracy")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text(String(format: "%.1f%%", engine.aiAccuracyScore))
                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                            .foregroundColor(.primary)
                        
                        Text("Loss: \(String(format: "%.6f", engine.nnTrainLoss))")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.gray)
                    }
                    Spacer()
                }
                .padding()
                .glassPanel()
                
                // Neural Network Graph
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("NETWORK TOPOLOGY")
                            .font(.system(.caption, design: .monospaced))
                            .bold()
                            .foregroundColor(.gray)
                        Spacer()
                        Text("[8, 16, 8, 4, 1]")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.purple)
                    }
                    
                    NeuralNetworkView(
                        architecture: [8, 16, 8, 4, 1],
                        activations: engine.nnActivations,
                        layerNorms: engine.nnLayerNorms
                    )
                    .frame(height: 280)
                    .padding()
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(12)
                }
                .padding()
                .glassPanel()
                
                // Layer Norms
                VStack(alignment: .leading, spacing: 12) {
                    Text("LAYER NORMS (AVG WEIGHT)")
                        .font(.system(.caption, design: .monospaced))
                        .bold()
                        .foregroundColor(.gray)
                    
                    if engine.nnLayerNorms.isEmpty {
                        Text("Awaiting training cycle...")
                            .font(.caption)
                            .foregroundColor(.gray)
                    } else {
                        ForEach(0..<engine.nnLayerNorms.count, id: \.self) { idx in
                            HStack {
                                Text("Layer \(idx + 1)")
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.8))
                                Spacer()
                                Text(String(format: "%.4f", engine.nnLayerNorms[idx]))
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(.cyan)
                            }
                            if idx < engine.nnLayerNorms.count - 1 {
                                Divider().background(Color.white.opacity(0.05))
                            }
                        }
                    }
                }
                .padding()
                .glassPanel()
            }
            .padding(.horizontal)
        }
        .background(GlassBackgroundView())
    }
}
