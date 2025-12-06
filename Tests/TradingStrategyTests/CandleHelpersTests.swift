import XCTest
@testable import TradingStrategy

final class CandleHelpersTests: XCTestCase {
    func testATRCalculation() {
        let test: [(period: Int, candles: [Klines], expected: [Double])] = [
            (
                14,
                [
                    Candle(open: 1.0, close: 1.3, high: 1.5, low: 0.9, volume: 100),
                    Candle(open: 1.2, close: 1.4, high: 1.6, low: 1.1, volume: 110),
                    Candle(open: 1.3, close: 1.2, high: 1.5, low: 1.0, volume: 120),
                    Candle(open: 1.1, close: 1.3, high: 1.4, low: 0.8, volume: 130),
                    Candle(open: 1.2, close: 1.5, high: 1.6, low: 1.1, volume: 140),
                    Candle(open: 1.4, close: 1.6, high: 1.7, low: 1.3, volume: 150),
                    Candle(open: 1.5, close: 1.4, high: 1.8, low: 1.2, volume: 160),
                    Candle(open: 1.3, close: 1.5, high: 1.6, low: 1.2, volume: 170),
                    Candle(open: 1.4, close: 1.3, high: 1.7, low: 1.1, volume: 180),
                    Candle(open: 1.2, close: 1.4, high: 1.5, low: 1.0, volume: 190),
                    Candle(open: 1.3, close: 1.5, high: 1.6, low: 1.2, volume: 200),
                    Candle(open: 1.5, close: 1.7, high: 1.8, low: 1.4, volume: 210),
                    Candle(open: 1.6, close: 1.5, high: 1.9, low: 1.3, volume: 220),
                    Candle(open: 1.4, close: 1.6, high: 1.7, low: 1.2, volume: 230),
                    Candle(open: 1.5, close: 1.3, high: 1.8, low: 1.1, volume: 240),
                    Candle(open: 1.3, close: 1.5, high: 1.6, low: 1.2, volume: 250),
                    Candle(open: 1.4, close: 1.6, high: 1.7, low: 1.3, volume: 260),
                    Candle(open: 1.6, close: 1.4, high: 1.8, low: 1.2, volume: 270),
                    Candle(open: 1.3, close: 1.5, high: 1.6, low: 1.1, volume: 280),
                    Candle(open: 1.5, close: 1.7, high: 1.9, low: 1.4, volume: 290)
                ],
                [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.507, 0.520, 0.512, 0.504, 0.511, 0.510, 0.509]
            ),
            (
                14,
                [
                    Candle(open: 1.0, close: 1.2, high: 1.5, low: 0.8, volume: 100),
                    Candle(open: 1.2, close: 1.3, high: 1.6, low: 0.9, volume: 150),
                    Candle(open: 1.3, close: 1.4, high: 1.7, low: 1.0, volume: 200),
                    Candle(open: 1.4, close: 1.2, high: 1.6, low: 1.1, volume: 180),
                    Candle(open: 1.2, close: 1.5, high: 1.8, low: 1.0, volume: 220),
                    Candle(open: 1.5, close: 1.7, high: 2.0, low: 1.3, volume: 250),
                    Candle(open: 1.7, close: 1.6, high: 2.1, low: 1.4, volume: 230),
                    Candle(open: 1.6, close: 1.8, high: 2.2, low: 1.5, volume: 240),
                    Candle(open: 1.8, close: 1.7, high: 2.3, low: 1.6, volume: 260),
                    Candle(open: 1.7, close: 1.9, high: 2.4, low: 1.5, volume: 270),
                    Candle(open: 1.9, close: 2.0, high: 2.5, low: 1.7, volume: 280),
                    Candle(open: 2.0, close: 2.1, high: 2.6, low: 1.8, volume: 290),
                    Candle(open: 2.1, close: 2.2, high: 2.7, low: 1.9, volume: 300),
                    Candle(open: 2.2, close: 2.1, high: 2.8, low: 2.0, volume: 310),
                    Candle(open: 2.1, close: 2.3, high: 2.9, low: 2.0, volume: 320),
                    Candle(open: 2.3, close: 2.2, high: 3.0, low: 2.1, volume: 330),
                    Candle(open: 2.2, close: 2.4, high: 3.1, low: 2.1, volume: 340),
                    Candle(open: 2.4, close: 2.3, high: 3.2, low: 2.2, volume: 350),
                    Candle(open: 2.3, close: 2.5, high: 3.3, low: 2.2, volume: 360),
                    Candle(open: 2.5, close: 2.4, high: 3.4, low: 2.3, volume: 370)
                ],
                [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0.736, 0.747, 0.758, 0.776, 0.792, 0.814, 0.834]
            )
        ]
        for data in test  {
            let calculatedATRValues = data.candles.averageTrueRange(period: data.period)
            print(data.expected)
            print(calculatedATRValues)
            // Assert that calculated ATR values match the expected ATR values
            for (index, atr) in calculatedATRValues.enumerated() {
                XCTAssertEqual(atr, data.expected[index], accuracy: 0.001, "ATR value at index \(index) is incorrect")
            }
        }
    }
    
    func testDICalculation() {
        let test: [(period: Int, candles: [Klines], expected: (plusDI: [Double], minusDI: [Double]))] = [
            (
                5,
                [
                    Candle(open: 1.0, close: 1.2, high: 1.5, low: 0.8, volume: 100),
                    Candle(open: 1.2, close: 1.3, high: 1.6, low: 0.9, volume: 150),
                    Candle(open: 1.3, close: 1.4, high: 1.7, low: 1.0, volume: 200),
                    Candle(open: 1.4, close: 1.2, high: 1.6, low: 1.1, volume: 180),
                    Candle(open: 1.2, close: 1.5, high: 1.8, low: 1.0, volume: 220),
                    Candle(open: 1.5, close: 1.7, high: 2.0, low: 1.3, volume: 250),
                    Candle(open: 1.7, close: 1.6, high: 2.1, low: 1.4, volume: 230),
                    Candle(open: 1.6, close: 1.8, high: 2.2, low: 1.5, volume: 240),
                    Candle(open: 1.8, close: 1.7, high: 2.3, low: 1.6, volume: 260),
                    Candle(open: 1.7, close: 1.9, high: 2.4, low: 1.5, volume: 270)
                ],
                (
                    [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 17.64, 17.64, 17.64, 19.44, 13.51],
                    [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
                )
            ),
        ]
        for data in test  {
            // Calculate +DI and -DI using the function under test
            let (plusDI, minusDI) = data.candles.directionalIndicators(period: data.period)
            // Validate the calculated +DI and -DI against the expected values
            for i in 0..<data.expected.plusDI.count {
                XCTAssertEqual(plusDI[i], data.expected.plusDI[i], accuracy: 0.1, "Plus DI value at index \(i) is incorrect")
                XCTAssertEqual(minusDI[i], data.expected.minusDI[i], accuracy: 0.1, "Minus DI value at index \(i) is incorrect")
            }
        }
    }
    
    func testRSICalculation() {
        let test: [(period: Int, candles: [Klines], expected: [Double])] = [
            (
                5,
                [
                    Candle(open: 1.0, close: 1.2, high: 1.5, low: 0.8, volume: 100),
                    Candle(open: 1.2, close: 1.3, high: 1.6, low: 0.9, volume: 150),
                    Candle(open: 1.3, close: 1.4, high: 1.7, low: 1.0, volume: 200),
                    Candle(open: 1.4, close: 1.2, high: 1.6, low: 1.1, volume: 180),
                    Candle(open: 1.2, close: 1.5, high: 1.8, low: 1.0, volume: 220),
                    Candle(open: 1.5, close: 1.7, high: 2.0, low: 1.3, volume: 250),
                    Candle(open: 1.7, close: 1.6, high: 2.1, low: 1.4, volume: 230),
                    Candle(open: 1.6, close: 1.8, high: 2.2, low: 1.5, volume: 240),
                    Candle(open: 1.8, close: 1.7, high: 2.3, low: 1.6, volume: 260),
                    Candle(open: 1.7, close: 1.9, high: 2.4, low: 1.5, volume: 270)
                ],
                (
                    [0.0, 0.0, 0.0, 0.0, 71.42, 78.94, 67.79, 76.20, 65.51, 74.46]
                )
            ),
        ]
        for data in test  {
            // Calculate +DI and -DI using the function under test
            let rsi = data.candles.relativeStrengthIndex(period: data.period)
            print(rsi)
            // Validate the calculated +DI and -DI against the expected values
            for i in 0..<data.expected.count {
                XCTAssertEqual(rsi[i], data.expected[i], accuracy: 0.1, "RSI value at index \(i) is incorrect")
            }
        }
    }
    
    func testCalculateBollingerBands() {
        let candles: [Klines] = [
            Candle(open: 1.0, close: 1.2, high: 1.5, low: 0.8, volume: 100),
            Candle(open: 1.2, close: 1.3, high: 1.6, low: 0.9, volume: 150),
            Candle(open: 1.3, close: 1.4, high: 1.7, low: 1.0, volume: 200),
            Candle(open: 1.4, close: 1.2, high: 1.6, low: 1.1, volume: 180),
            Candle(open: 1.2, close: 1.5, high: 1.8, low: 1.0, volume: 220),
            Candle(open: 1.5, close: 1.7, high: 2.0, low: 1.3, volume: 250),
            Candle(open: 1.7, close: 1.6, high: 2.1, low: 1.4, volume: 230),
            Candle(open: 1.6, close: 1.8, high: 2.2, low: 1.5, volume: 240),
            Candle(open: 1.8, close: 1.7, high: 2.3, low: 1.6, volume: 260),
            Candle(open: 1.7, close: 1.9, high: 2.4, low: 1.5, volume: 270)
        ]
        
        // Calculate Bollinger Bands
        let (upperBand, middleBand, lowerBand) = candles.bollingerBands(period: 3, multiplier: 2.0)
        
        // Expected Results
        let expectedUpperBand: [Double] = [
            0.0, 0.0, 0.0, 1.46, 1.46, 1.61, 1.87, 1.76, 1.86, 1.86
        ]
        
        let expectedMiddleBand: [Double] = [
            0.0, 0.0, 0.0, 1.3, 1.3, 1.36, 1.46, 1.60, 1.7, 1.7
        ]
        
        let expectedLowerBand: [Double] = [
            0.0, 0.0, 0.0, 1.13, 1.13, 1.11, 1.05, 1.43, 1.53, 1.53
        ]
        // Check if calculated bands match the expected values
        for i in 0..<expectedUpperBand.count {
            XCTAssertEqual(upperBand[i], expectedUpperBand[i], accuracy: 0.01)
            XCTAssertEqual(middleBand[i], expectedMiddleBand[i], accuracy: 0.01)
            XCTAssertEqual(lowerBand[i], expectedLowerBand[i], accuracy: 0.01)
        }
    }
    
    func testBarAgregation() {
        // Use deterministic timestamps to ensure grouping is predictable.
        let base: TimeInterval = 0
        let oneSecond: TimeInterval = 1
        let candles: [Klines] = [
            Candle(open: 1, close: 2, high: 2.5, low: 0.5, volume: 10, time: base + oneSecond * 0),
            Candle(open: 2, close: 3, high: 3.5, low: 1.5, volume: 10, time: base + oneSecond * 1),
            Candle(open: 3, close: 4, high: 4.5, low: 2.5, volume: 10, time: base + oneSecond * 2),
            Candle(open: 4, close: 5, high: 5.5, low: 3.5, volume: 10, time: base + oneSecond * 3),
            Candle(open: 5, close: 6, high: 6.5, low: 4.5, volume: 10, time: base + oneSecond * 4),
            Candle(open: 6, close: 7, high: 7.5, low: 5.5, volume: 10, time: base + oneSecond * 5)
        ]
        
        // Target interval 2 seconds => buckets [0-1], [2-3], [4-5]
        let aggregated = candles.aggregateBars(to: 2)
        XCTAssertEqual(aggregated.count, 3)
        
        func assertCandle(_ candle: Klines, open: Double, high: Double, low: Double, close: Double, start: TimeInterval) {
            XCTAssertEqual(candle.priceOpen, open)
            XCTAssertEqual(candle.priceHigh, high)
            XCTAssertEqual(candle.priceLow, low)
            XCTAssertEqual(candle.priceClose, close)
            XCTAssertEqual(candle.timeOpen, start, accuracy: 0.0001)
            XCTAssertEqual(candle.interval, 2, accuracy: 0.0001)
        }
        
        assertCandle(aggregated[0], open: 1, high: 3.5, low: 0.5, close: 3, start: 0)
        assertCandle(aggregated[1], open: 3, high: 5.5, low: 2.5, close: 5, start: 2)
        assertCandle(aggregated[2], open: 5, high: 7.5, low: 4.5, close: 7, start: 4)
    }
}
