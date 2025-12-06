import XCTest
@testable import TradingStrategy

// MARK: - Test Doubles

private struct TestAnnouncement: Annoucment {
    let timestamp: TimeInterval
    let annoucmentImpact: AnnoucmentImpact
}

private struct TestKline: Klines {
    var timeOpen: TimeInterval
    var interval: TimeInterval
    var priceOpen: Double
    var priceHigh: Double
    var priceLow: Double
    var priceClose: Double
    var volume: Double?
    
    init(open: Double, high: Double, low: Double, close: Double, start: TimeInterval = 0, interval: TimeInterval = 60) {
        self.timeOpen = start
        self.interval = interval
        self.priceOpen = open
        self.priceHigh = high
        self.priceLow = low
        self.priceClose = close
        self.volume = nil
    }
}

// MARK: - Example Strategies (test-only)

/// Goes long when the last two bars on the primary chart are bullish.
private struct TwoBarMomentumStrategy: Strategy {
    let charts: [ChartID: StrategyChart]
    let chartOrder: [ChartID]
    
    static let id = "com.example.twobar-momentum"
    static let name = "Two Bar Momentum"
    static let version = (major: 1, minor: 0, patch: 0)
    
    init(charts inputs: [StrategyChartInput]) async throws {
        let loaded = try await inputs.loadCharts()
        self.charts = loaded
        self.chartOrder = Array(loaded.keys)
    }
    
    func shouldEnterWitUnitCount(
        on chart: ChartID,
        signal: Signal,
        entryBar: Klines,
        equity: Double,
        tickValue: Double,
        tickSize: Double,
        feePerUnit cost: Double,
        nextAnnouncment announcment: Annoucment?
    ) -> Int {
        1
    }
    
    func exitTargets(for signal: Signal, chart: ChartID, entryBar: Klines) -> (takeProfit: Double?, stopLoss: Double?) {
        (takeProfit: nil, stopLoss: nil)
    }
    
    func shouldExit(signal: Signal, chart: ChartID, entryBar: Klines, nextAnnouncment announcment: Annoucment?) -> Bool {
        false
    }
    
    func evaluate(update: StrategyEvaluationContext) async -> [StrategyAction] {
        guard let primaryID = chartOrder.first,
              let barUpdate = update.bars[primaryID],
              let chart = charts[primaryID] else {
            return []
        }
        
        let index = barUpdate.index
        let candles = chart.candles
        guard index >= 1, index < candles.count else { return [] }
        
        let previous = candles[index - 1]
        let current = candles[index]
        
        if previous.isLong && current.isLong {
            let signal: Signal = .buy(confidence: 0.6)
            let units = shouldEnterWitUnitCount(
                on: primaryID,
                signal: signal,
                entryBar: current,
                equity: update.equity,
                tickValue: update.tickValue,
                tickSize: update.tickSize,
                feePerUnit: update.feePerUnit,
                nextAnnouncment: update.nextAnnouncment
            )
            let exits = exitTargets(for: signal, chart: primaryID, entryBar: current)
            return [.enter(chart: primaryID, signal: signal, units: units, takeProfit: exits.takeProfit, stopLoss: exits.stopLoss)]
        }
        
        return []
    }
}

/// Enters long on both charts when each closes above resistance on the same bar index.
private struct DualBreakoutStrategy: Strategy {
    let charts: [ChartID: StrategyChart]
    let chartOrder: [ChartID]
    
    static let id = "com.example.dual-breakout"
    static let name = "Dual Breakout"
    static let version = (major: 1, minor: 0, patch: 0)
    
    struct Levels: Sendable {
        let support: Double
        let resistance: Double
    }
    
    private let chartLevels: [ChartID: Levels]
    
    init(charts inputs: [StrategyChartInput]) async throws {
        try await self.init(charts: inputs, levels: [:])
    }
    
    init(
        charts inputs: [StrategyChartInput],
        levels: [ChartID: Levels]
    ) async throws {
        let loaded = try await inputs.loadCharts()
        self.charts = loaded
        self.chartOrder = Array(loaded.keys)
        self.chartLevels = levels
    }
    
    func shouldEnterWitUnitCount(
        on chart: ChartID,
        signal: Signal,
        entryBar: Klines,
        equity: Double,
        tickValue: Double,
        tickSize: Double,
        feePerUnit cost: Double,
        nextAnnouncment announcment: Annoucment?
    ) -> Int {
        1
    }
    
    func exitTargets(for signal: Signal, chart: ChartID, entryBar: Klines) -> (takeProfit: Double?, stopLoss: Double?) {
        (takeProfit: nil, stopLoss: nil)
    }
    
    func shouldExit(signal: Signal, chart: ChartID, entryBar: Klines, nextAnnouncment announcment: Annoucment?) -> Bool {
        false
    }
    
    func evaluate(update: StrategyEvaluationContext) async -> [StrategyAction] {
        guard let futuresID = chartOrder.first(where: { $0.rawValue == "FUTURES" }) ?? chartOrder.first,
              let indexID = chartOrder.first(where: { $0.rawValue == "INDEX" }) ?? chartOrder.dropFirst().first,
              let futuresBar = update.bars[futuresID],
              let indexBar = update.bars[indexID],
              let futuresLevels = chartLevels[futuresID],
              let indexLevels = chartLevels[indexID]
        else {
            return []
        }
        
        guard futuresBar.index == indexBar.index else { return [] }
        
        let futuresBreakout = futuresBar.bar.priceClose > futuresLevels.resistance
        let indexBreakout = indexBar.bar.priceClose > indexLevels.resistance
        
        guard futuresBreakout && indexBreakout else { return [] }
        
        let signal: Signal = .buy(confidence: 0.7)
        let futuresUnits = shouldEnterWitUnitCount(
            on: futuresID,
            signal: signal,
            entryBar: futuresBar.bar,
            equity: update.equity,
            tickValue: update.tickValue,
            tickSize: update.tickSize,
            feePerUnit: update.feePerUnit,
            nextAnnouncment: update.nextAnnouncment
        )
        let indexUnits = shouldEnterWitUnitCount(
            on: indexID,
            signal: signal,
            entryBar: indexBar.bar,
            equity: update.equity,
            tickValue: update.tickValue,
            tickSize: update.tickSize,
            feePerUnit: update.feePerUnit,
            nextAnnouncment: update.nextAnnouncment
        )
        
        let futuresTargets = exitTargets(for: signal, chart: futuresID, entryBar: futuresBar.bar)
        let indexTargets = exitTargets(for: signal, chart: indexID, entryBar: indexBar.bar)
        
        return [
            .enter(chart: futuresID, signal: signal, units: futuresUnits, takeProfit: futuresTargets.takeProfit, stopLoss: futuresTargets.stopLoss),
            .enter(chart: indexID, signal: signal, units: indexUnits, takeProfit: indexTargets.takeProfit, stopLoss: indexTargets.stopLoss)
        ]
    }
}

// MARK: - Tests

@MainActor
final class ExampleStrategiesTests: XCTestCase {
    func testTwoBarMomentumPerformance() async throws {
        let barCount = 2_000
        let bars = (0..<barCount).map { i in
            TestKline(open: Double(i), high: Double(i) + 1, low: Double(i) - 1, close: Double(i) + 0.5)
        }
        
        let strategy = try await TwoBarMomentumStrategy(
            charts: [StrategyChartInput(id: ChartID("PRIMARY"), candles: bars)]
        )
        
        let start = CFAbsoluteTimeGetCurrent()
        var lastActions: [StrategyAction] = []
        for i in 1..<barCount {
            let context = StrategyEvaluationContext(
                bars: [ChartID("PRIMARY"): StrategyBarUpdate(chart: ChartID("PRIMARY"), index: i, bar: bars[i])],
                equity: 10_000,
                feePerUnit: 0.5
            )
            lastActions = await strategy.evaluate(update: context)
        }
        let duration = CFAbsoluteTimeGetCurrent() - start
        XCTAssertNotNil(lastActions)
        XCTAssertLessThan(duration, 1.5, "TwoBarMomentumStrategy evaluation should remain performant")
    }
    
    func testDualBreakoutPerformance() async throws {
        let barCount = 1_000
        let futuresBars = (0..<barCount).map { i in
            TestKline(open: Double(i), high: Double(i) + 2, low: Double(i) - 1, close: Double(i) + 1.1)
        }
        let indexBars = (0..<barCount).map { i in
            TestKline(open: Double(i), high: Double(i) + 1.5, low: Double(i) - 0.8, close: Double(i) + 0.9)
        }
        
        let strategy = try await DualBreakoutStrategy(
            charts: [
                StrategyChartInput(id: ChartID("FUTURES"), candles: futuresBars),
                StrategyChartInput(id: ChartID("INDEX"), candles: indexBars)
            ],
            levels: [
                ChartID("FUTURES"): .init(support: -1, resistance: Double(barCount) / 2),
                ChartID("INDEX"): .init(support: -1, resistance: Double(barCount) / 2)
            ]
        )
        
        let start = CFAbsoluteTimeGetCurrent()
        for i in 0..<barCount {
            let context = StrategyEvaluationContext(
                bars: [
                    ChartID("FUTURES"): StrategyBarUpdate(chart: ChartID("FUTURES"), index: i, bar: futuresBars[i]),
                    ChartID("INDEX"): StrategyBarUpdate(chart: ChartID("INDEX"), index: i, bar: indexBars[i])
                ]
            )
            _ = await strategy.evaluate(update: context)
        }
        let duration = CFAbsoluteTimeGetCurrent() - start
        XCTAssertLessThan(duration, 1.5, "DualBreakoutStrategy evaluation should remain performant")
    }
    
    func testLoadChartsBuildsDictionary() async throws {
        let inputs: [StrategyChartInput] = [
            StrategyChartInput(id: ChartID("A")) { [TestKline(open: 1, high: 2, low: 0.5, close: 1.5)] },
            StrategyChartInput(id: ChartID("B")) { [TestKline(open: 2, high: 3, low: 1, close: 2.5)] }
        ]
        
        let charts = try await inputs.loadCharts()
        XCTAssertEqual(charts.count, 2)
        XCTAssertNotNil(charts[ChartID("A")])
        XCTAssertNotNil(charts[ChartID("B")])
    }
    
    func testTwoBarMomentumEntersOnTwoBullBars() async throws {
        let bars = [
            TestKline(open: 1, high: 2, low: 0.5, close: 1.5), // long
            TestKline(open: 1.6, high: 2.2, low: 1.4, close: 2.1), // long
            TestKline(open: 2.2, high: 2.8, low: 2.1, close: 2.6) // target evaluation bar
        ]
        
        let strategy = try await TwoBarMomentumStrategy(
            charts: [StrategyChartInput(id: ChartID("PRIMARY"), candles: bars)]
        )
        
        let context = StrategyEvaluationContext(
            bars: [ChartID("PRIMARY"): StrategyBarUpdate(chart: ChartID("PRIMARY"), index: 2, bar: bars[2])],
            equity: 10_000,
            feePerUnit: 1.0
        )
        
        let actions = await strategy.evaluate(update: context)
        XCTAssertEqual(actions.count, 1)
        if case let .enter(chart, signal, units, _, _) = actions[0] {
            XCTAssertEqual(chart, ChartID("PRIMARY"))
            XCTAssertTrue(signal.isLong)
            XCTAssertEqual(units, 1)
        } else {
            XCTFail("Expected enter action")
        }
    }
    
    func testDualBreakoutRequiresBothCharts() async throws {
        let futuresBars = [
            TestKline(open: 10, high: 11, low: 9.5, close: 10.5),
            TestKline(open: 10.6, high: 12.1, low: 10.5, close: 12.0)
        ]
        let indexBars = [
            TestKline(open: 4, high: 4.5, low: 3.9, close: 4.3),
            TestKline(open: 4.4, high: 5.1, low: 4.3, close: 5.05)
        ]
        
        let strategy = try await DualBreakoutStrategy(
            charts: [
                StrategyChartInput(id: ChartID("FUTURES"), candles: futuresBars),
                StrategyChartInput(id: ChartID("INDEX"), candles: indexBars)
            ],
            levels: [
                ChartID("FUTURES"): .init(support: 9.0, resistance: 11.5),
                ChartID("INDEX"): .init(support: 3.5, resistance: 5.0)
            ]
        )
        
        let context = StrategyEvaluationContext(
            bars: [
                ChartID("FUTURES"): StrategyBarUpdate(chart: ChartID("FUTURES"), index: 1, bar: futuresBars[1]),
                ChartID("INDEX"): StrategyBarUpdate(chart: ChartID("INDEX"), index: 1, bar: indexBars[1])
            ],
            equity: 50_000,
            tickValue: 12.5,
            tickSize: 0.25,
            feePerUnit: 1.5,
            nextAnnouncment: TestAnnouncement(timestamp: 0, annoucmentImpact: .medium)
        )
        
        let actions = await strategy.evaluate(update: context)
        XCTAssertEqual(actions.count, 2)
        
        let futuresAction = actions.first { if case let .enter(chart, _, _, _, _) = $0 { return chart == ChartID("FUTURES") } else { return false } }
        let indexAction = actions.first { if case let .enter(chart, _, _, _, _) = $0 { return chart == ChartID("INDEX") } else { return false } }
        
        XCTAssertNotNil(futuresAction)
        XCTAssertNotNil(indexAction)
    }
    
    func testDualBreakoutDoesNothingWhenOnlyOneBreaks() async throws {
        let futuresBars = [
            TestKline(open: 10, high: 11, low: 9.5, close: 10.5),
            TestKline(open: 10.6, high: 11.4, low: 10.5, close: 11.2) // below resistance
        ]
        let indexBars = [
            TestKline(open: 4, high: 4.5, low: 3.9, close: 4.3),
            TestKline(open: 4.4, high: 5.1, low: 4.3, close: 5.05) // above resistance
        ]
        
        let strategy = try await DualBreakoutStrategy(
            charts: [
                StrategyChartInput(id: ChartID("FUTURES"), candles: futuresBars),
                StrategyChartInput(id: ChartID("INDEX"), candles: indexBars)
            ],
            levels: [
                ChartID("FUTURES"): .init(support: 9.0, resistance: 11.5),
                ChartID("INDEX"): .init(support: 3.5, resistance: 5.0)
            ]
        )
        
        let context = StrategyEvaluationContext(
            bars: [
                ChartID("FUTURES"): StrategyBarUpdate(chart: ChartID("FUTURES"), index: 1, bar: futuresBars[1]),
                ChartID("INDEX"): StrategyBarUpdate(chart: ChartID("INDEX"), index: 1, bar: indexBars[1])
            ],
            equity: 50_000,
            tickValue: 12.5,
            tickSize: 0.25,
            feePerUnit: 1.5
        )
        
        let actions = await strategy.evaluate(update: context)
        XCTAssertTrue(actions.isEmpty)
    }
}
