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

extension Array where Element == CGPoint {
    func chunksMomentum() -> [[Element]] {
        guard count > 2 else { return self.map({ [$0] }) }
        var p1 = self[0]
        var p2 = self[1]
        
        var momentum: Momentum = p1.angleLineToXAxis(p2).momentum
        var chunk: [Element] = [p1, p2]
        
        var data: [[Element]] = []
        
        for i in 2..<count {
            let angle = p1.angleLineToXAxis(self[i])
            let newMomentum = angle.momentum
            if momentum.isSuprise(to: newMomentum) {
                data.append(chunk)
                momentum = newMomentum
                chunk = []
                p1 = self[i]
            } else if momentum != .strong {
                chunk.append(self[i])
            }
            p2 = self[i]
        }
        
        if !chunk.isEmpty {
            data.append(chunk)
        }
        
        return data
    }
}

