import Foundation

public final class NeuralNetwork: Codable {
    public let layerSizes: [Int]
    public var lr: Double
    public var weights: [[[Double]]] // weights[layerIdx][inputNeuron][outputNeuron]
    public var biases: [[Double]] // biases[layerIdx][neuron]
    private var vWeights: [[[Double]]] // Momentum weights
    private var vBiases: [[Double]] // Momentum biases
    public let momentum: Double = 0.9

    // Accuracy and performance tracking
    public var predictionsMade: Int = 0
    public var correctDirections: Int = 0
    public var accuracy: Double = 0.0
    public var lastPrediction: Double = 0.0
    public var lastActivations: [[Double]]?
    public var lastPrice: Double?
    public var trainLoss: Double = 0.0

    public init(layerSizes: [Int], learningRate: Double = 0.005) {
        self.layerSizes = layerSizes
        self.lr = learningRate
        
        self.weights = []
        self.biases = []
        self.vWeights = []
        self.vBiases = []

        // Initialize weights and biases with He/Xavier-like random values
        for i in 0..<(layerSizes.count - 1) {
            let fanIn = layerSizes[i]
            let fanOut = layerSizes[i + 1]
            let std = sqrt(2.0 / Double(fanIn)) // He initialization for ReLU

            var w: [[Double]] = []
            var vw: [[Double]] = []
            for _ in 0..<fanIn {
                var wRow: [Double] = []
                var vwRow: [Double] = []
                for _ in 0..<fanOut {
                    wRow.append(Double.randomNormal(mean: 0.0, stdDev: std))
                    vwRow.append(0.0)
                }
                w.append(wRow)
                vw.append(vwRow)
            }
            weights.append(w)
            vWeights.append(vw)

            biases.append(Array(repeating: 0.0, count: fanOut))
            vBiases.append(Array(repeating: 0.0, count: fanOut))
        }
    }

    // Activations
    private func relu(_ x: Double) -> Double {
        return max(0.0, x)
    }

    private func reluDeriv(_ x: Double) -> Double {
        return x > 0.0 ? 1.0 : 0.0
    }

    private func tanhActivation(_ x: Double) -> Double {
        let clamped = max(-10.0, min(10.0, x))
        return tanh(clamped)
    }

    private func tanhDeriv(_ output: Double) -> Double {
        return 1.0 - output * output
    }

    // Forward pass
    public func forward(inputs: [Double]) -> (output: Double, activations: [[Double]]) {
        var activations: [[Double]] = [inputs] // layer 0 input
        var current = inputs

        for layerIdx in 0..<weights.count {
            let w = weights[layerIdx]
            let b = biases[layerIdx]
            let isOutput = (layerIdx == weights.count - 1)
            var nextLayer: [Double] = []

            for j in 0..<b.count {
                var z = b[j]
                for k in 0..<current.count {
                    z += current[k] * w[k][j]
                }
                let a = isOutput ? tanhActivation(z) : relu(z)
                nextLayer.append(a)
            }
            activations.append(nextLayer)
            current = nextLayer
        }

        return (current[0], activations)
    }

    // Single-sample backpropagation training
    @discardableResult
    public func train(inputs: [Double], target: Double) -> (output: Double, error: Double) {
        let (output, activations) = forward(inputs: inputs)
        let error = target - output
        self.trainLoss = error * error // Mean squared error

        var deltas = [[Double]](repeating: [], count: weights.count)

        // Output layer delta
        let outDeriv = tanhDeriv(output)
        deltas[deltas.count - 1] = [error * outDeriv]

        // Hidden layers deltas
        if weights.count > 1 {
            for layerIdx in stride(from: weights.count - 2, through: 0, by: -1) {
                let layerAct = activations[layerIdx + 1]
                let nextDeltas = deltas[layerIdx + 1]
                let w = weights[layerIdx + 1]
                var currDeltas: [Double] = []

                for j in 0..<layerAct.count {
                    var downstream = 0.0
                    for k in 0..<nextDeltas.count {
                        downstream += w[j][k] * nextDeltas[k]
                    }
                    let d = downstream * reluDeriv(layerAct[j])
                    currDeltas.append(d)
                }
                deltas[layerIdx] = currDeltas
            }
        }

        let maxGrad = 1.0 // Gradient clipping limit

        // Update weights and biases with momentum
        for layerIdx in 0..<weights.count {
            let layerInput = activations[layerIdx]
            let layerDelta = deltas[layerIdx]

            for j in 0..<layerDelta.count {
                for k in 0..<layerInput.count {
                    var grad = layerDelta[j] * layerInput[k]
                    grad = max(-maxGrad, min(maxGrad, grad)) // clip

                    vWeights[layerIdx][k][j] = momentum * vWeights[layerIdx][k][j] + lr * grad
                    weights[layerIdx][k][j] += vWeights[layerIdx][k][j]
                }

                var gradB = layerDelta[j]
                gradB = max(-maxGrad, min(maxGrad, gradB))

                vBiases[layerIdx][j] = momentum * vBiases[layerIdx][j] + lr * gradB
                biases[layerIdx][j] += vBiases[layerIdx][j]
            }
        }

        return (output, error)
    }

    public func predict(inputs: [Double]) -> Double {
        let (output, activations) = forward(inputs: inputs)
        self.lastActivations = activations
        self.lastPrediction = output
        return output
    }

    public func updateAccuracy(predicted: Double, actual: Double) {
        if (actual > 0.0 && predicted > 0.0) || (actual < 0.0 && predicted < 0.0) {
            correctDirections += 1
        }
        predictionsMade += 1
        accuracy = predictionsMade > 0 ? (Double(correctDirections) / Double(predictionsMade)) * 100.0 : 0.0
    }

    public func getLayerNorms() -> [Double] {
        var norms: [Double] = []
        for w in weights {
            var total = 0.0
            var count = 0
            for row in w {
                for v in row {
                    total += abs(v)
                    count += 1
                }
            }
            norms.append(count > 0 ? (total / Double(count)) : 0.0)
        }
        return norms
    }

    public func getOutputWeights() -> [Double] {
        guard let lastW = weights.last else { return [] }
        return lastW.map { $0[0] }
    }
}

// Helper for generating normally distributed random numbers (Box-Muller transform)
extension Double {
    static func randomNormal(mean: Double = 0.0, stdDev: Double = 1.0) -> Double {
        let u1 = Double.random(in: 0...1)
        let u2 = Double.random(in: 0...1)
        // Guard to prevent natural log of 0
        let logVal = log(max(u1, 1e-15))
        let randStdNormal = sqrt(-2.0 * logVal) * cos(2.0 * .pi * u2)
        return mean + stdDev * randStdNormal
    }
}
