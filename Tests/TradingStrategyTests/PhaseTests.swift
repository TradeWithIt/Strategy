import XCTest
@testable import TradingStrategy

final class PhaseTests: XCTestCase {
    func testConvertToPhasesCreatesUpAndDownTrends() {
        // Prices above MA then below MA should yield uptrend then downtrend.
        let ma = Array(repeating: 10.0, count: 6)
        let candles: [Klines] = [
            Candle(open: 10, close: 11, high: 11, low: 9, volume: 100), // up
            Candle(open: 11, close: 12, high: 12, low: 10, volume: 100), // up
            Candle(open: 12, close: 9, high: 12, low: 9, volume: 100),   // down start
            Candle(open: 9, close: 8.5, high: 9.5, low: 8, volume: 100), // down
            Candle(open: 8.5, close: 8.2, high: 9, low: 8, volume: 100), // down
            Candle(open: 8.2, close: 8, high: 8.5, low: 7.8, volume: 100) // down
        ]
        
        let phases = candles.convertToPhases(minPhaseLength: 1, longTermMA: ma)
        XCTAssertEqual(phases.count, 2)
        XCTAssertEqual(phases[0].type, .uptrend)
        XCTAssertEqual(phases[1].type, .downtrend)
    }
    
    func testDetectPhasesUsingMovingAverageDetectsSideways() {
        let sma = [10.0, 10.0, 10.0, 10.0, 10.0]
        let scale = Scale(x: 0..<5, y: 9..<11, candlesPerScreen: 5)
        let candles: [Klines] = [
            Candle(open: 10, close: 10.02, high: 10.05, low: 9.95, volume: 100), // near MA -> sideways
            Candle(open: 10.01, close: 10.0, high: 10.04, low: 9.96, volume: 100), // sideways
            Candle(open: 10.0, close: 10.5, high: 10.6, low: 9.9, volume: 100), // up
            Candle(open: 10.5, close: 10.6, high: 10.8, low: 10.4, volume: 100), // up
            Candle(open: 10.6, close: 10.1, high: 10.7, low: 10.0, volume: 100) // down
        ]
        
        let phases = candles.detectPhasesUsingMovingAverage(period: 1, shortTermMA: sma, scale: scale)
        XCTAssertFalse(phases.isEmpty)
        XCTAssertTrue(phases.contains { $0.type == .sideways })
    }
}
