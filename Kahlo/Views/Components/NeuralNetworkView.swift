import SwiftUI

struct NeuralNetworkView: View {
    let architecture: [Int] // [8, 16, 8, 4, 1]
    let activations: [[Double]]
    let layerNorms: [Double]
    let featureNames: [String] = ["RSI", "BB Pos", "Bandwidth", "Momentum", "Volatility", "P/SMA", "ConsecDir", "MeanRev"]

    var body: some View {
        GeometryReader { geo in
            let layersCount = architecture.count
            let colWidth = geo.size.width / CGFloat(max(1, layersCount))
            
            ZStack {
                // Connections (Weights)
                ForEach(0..<(layersCount - 1), id: \.self) { layerIdx in
                    let fromCount = min(architecture[layerIdx], 8) // Limit rendered nodes to prevent clutter
                    let toCount = min(architecture[layerIdx + 1], 8)
                    
                    let fromColX = CGFloat(layerIdx) * colWidth + (colWidth / 2.0)
                    let toColX = CGFloat(layerIdx + 1) * colWidth + (colWidth / 2.0)
                    
                    let fromHeight = geo.size.height / CGFloat(fromCount + 1)
                    let toHeight = geo.size.height / CGFloat(toCount + 1)
                    
                    ForEach(0..<fromCount, id: \.self) { fromIdx in
                        let fromY = CGFloat(fromIdx + 1) * fromHeight
                        ForEach(0..<toCount, id: \.self) { toIdx in
                            let toY = CGFloat(toIdx + 1) * toHeight
                            
                            Path { path in
                                path.move(to: CGPoint(x: fromColX, y: fromY))
                                path.addLine(to: CGPoint(x: toColX, y: toY))
                            }
                            .stroke(
                                Color.purple.opacity(0.12),
                                lineWidth: 0.8
                            )
                        }
                    }
                }
                
                // Nodes
                ForEach(0..<layersCount, id: \.self) { layerIdx in
                    let nodesCount = min(architecture[layerIdx], 8)
                    let colX = CGFloat(layerIdx) * colWidth + (colWidth / 2.0)
                    let nodeHeight = geo.size.height / CGFloat(nodesCount + 1)
                    let isInput = (layerIdx == 0)
                    let isOutput = (layerIdx == layersCount - 1)
                    
                    ForEach(0..<nodesCount, id: \.self) { nodeIdx in
                        let nodeY = CGFloat(nodeIdx + 1) * nodeHeight
                        
                        // Compute activation value for styling
                        let activationVal = (layerIdx < activations.count && nodeIdx < activations[layerIdx].count) ? activations[layerIdx][nodeIdx] : 0.0
                        
                        VStack(spacing: 2) {
                            Circle()
                                .fill(nodeColor(val: activationVal, isInput: isInput, isOutput: isOutput))
                                .frame(width: isOutput ? 22 : 14, height: isOutput ? 22 : 14)
                                .overlay(
                                    Circle().stroke(Color.white.opacity(0.8), lineWidth: 1)
                                )
                                .shadow(color: isOutput ? Color.cyan.opacity(0.8) : Color.purple.opacity(0.4), radius: 3)
                            
                            if isInput && nodeIdx < featureNames.count {
                                Text(featureNames[nodeIdx])
                                    .font(.system(size: 8, weight: .semibold, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        .position(x: colX, y: nodeY)
                    }
                }
            }
        }
    }
    
    private func nodeColor(val: Double, isInput: Bool, isOutput: Bool) -> Color {
        if isOutput {
            return val > 0.05 ? .green : (val < -0.05 ? .red : .gray)
        }
        
        // Hidden activations are ReLU (positive)
        if isInput {
            // Normalized inputs are [-1.0, 1.0]
            return val > 0.0 ? Color.cyan.opacity(0.4 + val * 0.6) : Color.blue.opacity(0.4 + abs(val) * 0.6)
        } else {
            return Color.purple.opacity(0.3 + min(val, 1.0) * 0.7)
        }
    }
}
