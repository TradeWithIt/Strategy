import Foundation

extension Double {
    public func toPoint(
        atTime time: TimeInterval,
        scale: Scale,
        canvasSize size: CGSize
    ) -> CGPoint {
        let y = (Double(scale.y.upperBound) - self) / scale.yAmplitiude * size.height
        let x = (time - scale.x.lowerBound) / scale.xAmplitiude * size.width
        return .init(x: x, y: y)
    }
}

public extension Array where Element == CGPoint {
    func simplifyLine(epsilon: Double = 38, windowSize: Int = 10, significanceThreshold: Double = 0.02) -> [PhaseLinePoint] {
        guard count > 2 else {
            return self.enumerated().map { ($0.element, $0.offset) }
        }
        // detect local min max
        var minMax = detectLocalMinMax(
            windowSize: windowSize,
            significanceThreshold: significanceThreshold
        ).map { (self[$0], $0) }
        
        // use last item as final point
        if let lastIndex = minMax.last?.1, lastIndex < (count - 1), let lastItem = self.last {
            minMax.append((lastItem, count - 1))
        }
        return minMax
    }

    /// Detects local minima and maxima using an adaptive window-based approach
    func detectLocalMinMax(windowSize: Int = 10, significanceThreshold: Double = 0.02) -> [Int] {
        guard count > windowSize * 2 else { return [] }

        var localExtremes: [Int] = []
        var lookingForMin: Bool? = nil // Start with unknown direction
        var lastExtremeIndex: Int? = nil // Track the last confirmed extreme

        var i = windowSize
        while i < count - windowSize {
            let window = self[(i - windowSize)...(i + windowSize)]
            let yValues = window.map { $0.y }
            let midIndex = i
            let currentY = self[midIndex].y

            let minY = yValues.min()!
            let maxY = yValues.max()!

            // Ensure the min/max is **significant** compared to previous
            let isSignificant = lastExtremeIndex == nil ||
                abs(currentY - self[lastExtremeIndex!].y) > significanceThreshold * abs(self[lastExtremeIndex!].y)

            if isSignificant {
                if lookingForMin == nil {
                    // Determine initial direction based on trend
                    lookingForMin = currentY == minY
                }

                if lookingForMin == true, currentY == minY {
                    localExtremes.append(midIndex)
                    lastExtremeIndex = midIndex
                    lookingForMin = false // Switch to looking for a max
                } else if lookingForMin == false, currentY == maxY {
                    localExtremes.append(midIndex)
                    lastExtremeIndex = midIndex
                    lookingForMin = true // Switch to looking for a min
                }
            }

            i += 1 // Only increment by 1 to avoid missing reversals
        }

        return localExtremes.sorted() // Ensures results are in ascending order
    }
}

public extension Array where Element == PhaseLinePoint {
    func convertToPhases(minPhaseLength: Int = 8) -> [Phase] {
        guard count > 1 else { return [] }

        var phases: [Phase] = []
        var startIdx = self[0].1
        var currentPhase: PhaseType = .uptrend

        for i in 1..<count {
            let prev = self[i - 1]
            let curr = self[i]

            // **Detect movement type**
            let xMove = abs(curr.0.x - prev.0.x)
            let yMove = abs(curr.0.y - prev.0.y)
            let angle = abs(prev.0.angleLineToXAxis(curr.0))

            let newPhase: PhaseType
            if angle > 20 {
                newPhase = curr.0.y > prev.0.y ? .downtrend : .uptrend
            } else {
                newPhase = .sideways
            }


            // **Detect phase transitions**
            if currentPhase != newPhase {
                let phaseLength = prev.1 - startIdx

                // **🔹 Merge small phases into the previous one**
                if phaseLength < minPhaseLength, !phases.isEmpty {
                    let lastPhase = phases.removeLast()
                    startIdx = lastPhase.range.lowerBound // Extend the previous phase
                } else {
                    phases.append(Phase(type: currentPhase, range: startIdx...prev.1))
                    startIdx = prev.1
                }
                
                currentPhase = newPhase
            }
        }

        // **Ensure the last phase is appended with a valid range**
        if startIdx <= self.last!.1 {
            let lastPhaseLength = self.last!.1 - startIdx
            if lastPhaseLength < minPhaseLength, !phases.isEmpty {
                let lastPhase = phases.removeLast()
                startIdx = lastPhase.range.lowerBound
            }
            phases.append(Phase(type: currentPhase, range: startIdx...(self.last!.1)))
        }

        return phases
    }
}
