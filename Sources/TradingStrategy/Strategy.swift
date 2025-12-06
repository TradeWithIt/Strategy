import Foundation

/// Unique identifier for a chart tracked by a strategy.
public struct ChartID: RawRepresentable, Hashable, Sendable {
    public let rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    public init(_ value: String) {
        self.init(rawValue: value)
    }
}

/// Aggregates all computed state for a single chart tracked by the strategy.
public struct StrategyChart: Sendable {
    public let id: ChartID
    public var candles: [Klines]
    public var resolution: Scale
    public var distribution: [Phase]
    public var indicators: [String: [Double]]
    public var levels: [Level]
    public var patterns: [(index: Int, pattern: PricePattern)]
    public var patternIdentified: Signal?
    public var patternInformation: [String: Double]
    
    public init(
        id: ChartID,
        candles: [Klines],
        resolution: Scale? = nil,
        distribution: [Phase] = [],
        indicators: [String: [Double]] = [:],
        levels: [Level] = [],
        patterns: [(index: Int, pattern: PricePattern)] = [],
        patternIdentified: Signal? = nil,
        patternInformation: [String: Double] = [:]
    ) {
        self.id = id
        self.candles = candles
        self.resolution = resolution ?? Scale(data: candles)
        self.distribution = distribution
        self.indicators = indicators
        self.levels = levels
        self.patterns = patterns
        self.patternIdentified = patternIdentified
        self.patternInformation = patternInformation
    }
    
    public var mostRecentBar: Klines? {
        candles.last
    }
}

/// Represents a single bar update for a given chart during evaluation.
public struct StrategyBarUpdate: Sendable {
    public let chart: ChartID
    public let index: Int
    public let bar: Klines
    
    public init(chart: ChartID, index: Int, bar: Klines) {
        self.chart = chart
        self.index = index
        self.bar = bar
    }
}

/// Encapsulates a synchronized set of bar updates across charts when evaluating the strategy.
public struct StrategyEvaluationContext: Sendable {
    public let bars: [ChartID: StrategyBarUpdate]
    public let equity: Double
    public let tickValue: Double
    public let tickSize: Double
    public let feePerUnit: Double
    public let nextAnnouncment: Annoucment?
    
    public init(
        bars: [ChartID: StrategyBarUpdate],
        equity: Double = .nan,
        tickValue: Double = 1.0,
        tickSize: Double = 1.0,
        feePerUnit: Double = 0.0,
        nextAnnouncment: Annoucment? = nil
    ) {
        self.bars = bars
        self.equity = equity
        self.tickValue = tickValue
        self.tickSize = tickSize
        self.feePerUnit = feePerUnit
        self.nextAnnouncment = nextAnnouncment
    }
}

/// Action emitted by a strategy when evaluating a bar update.
public enum StrategyAction: Sendable {
    case enter(chart: ChartID, signal: Signal, units: Int, takeProfit: Double?, stopLoss: Double?)
    case exit(chart: ChartID, signal: Signal)
    case none
}

/// Input description for asynchronously loading chart data.
public struct StrategyChartInput: Sendable {
    public let id: ChartID
    private let loader: @Sendable () async throws -> [Klines]
    public let resolution: Scale?
    
    public init(
        id: ChartID = ChartID(UUID().uuidString),
        resolution: Scale? = nil,
        loader: @escaping @Sendable () async throws -> [Klines]
    ) {
        self.id = id
        self.resolution = resolution
        self.loader = loader
    }
    
    public init(
        id: ChartID = ChartID(UUID().uuidString),
        candles: [Klines],
        resolution: Scale? = nil
    ) {
        self.init(
            id: id,
            resolution: resolution,
            loader: { candles }
        )
    }
    
    public func load() async throws -> StrategyChart {
        let candles = try await loader()
        return StrategyChart(
            id: id,
            candles: candles,
            resolution: resolution
        )
    }
}

public extension Collection where Element == StrategyChartInput {
    /// Loads chart snapshots in parallel to keep strategy setup responsive.
    func loadCharts() async throws -> [ChartID: StrategyChart] {
        try await withThrowingTaskGroup(of: StrategyChart.self) { group in
            var charts: [ChartID: StrategyChart] = [:]
            charts.reserveCapacity(count)
            
            for input in self {
                group.addTask {
                    try await input.load()
                }
            }
            
            for try await chart in group {
                charts[chart.id] = chart
            }
            
            return charts
        }
    }
}

/// Core contract for trading strategies, now supporting multi-chart setups.
/// Initialization is async to allow loading heterogeneous data sources without blocking.
public protocol Strategy: Sendable, Versioned {
    /// The complete set of charts keyed by their identifiers.
    var charts: [ChartID: StrategyChart] { get }
    
    /// Order in which charts should be evaluated (e.g., primary -> secondary).
    var chartOrder: [ChartID] { get }
    
    /// Initializes a strategy with chart inputs. Implementations can perform
    /// expensive work (I/O, heavy preprocessing) concurrently during setup.
    init(charts: [StrategyChartInput]) async throws
    
    /// Evaluates the number of units/contracts to trade for a specific chart.
    func shouldEnterWitUnitCount(
        on chart: ChartID,
        signal: Signal,
        entryBar: Klines,
        equity: Double,
        tickValue: Double,
        tickSize: Double,
        feePerUnit cost: Double,
        nextAnnouncment announcment: Annoucment?
    ) -> Int
    
    /// the stop-loss and take profit targets for a given chart.
    func exitTargets(for signal: Signal, chart: ChartID, entryBar: Klines) -> (takeProfit: Double?, stopLoss: Double?)
    
    /// Determines whether the trade should be exited based on strategy conditions.
    func shouldExit(signal: Signal, chart: ChartID, entryBar: Klines, nextAnnouncment announcment: Annoucment?) -> Bool
    
    /// Evaluate the strategy for the current bar updates across charts.
    /// This should be called on every bar update (live or backtest) to emit entry/exit decisions.
    func evaluate(update: StrategyEvaluationContext) async -> [StrategyAction]
}

public extension Strategy {
    /// Default evaluation order falls back to the order in which charts were loaded.
    var chartOrder: [ChartID] {
        Array(charts.keys)
    }
    
    /// Convenience access to the first chart in evaluation order.
    var primaryChart: StrategyChart? {
        chartOrder.compactMap { charts[$0] }.first ?? charts.values.first
    }
    
    /// Backwards-compatible access to the primary chart's candles.
    var candles: [Klines] {
        primaryChart?.candles ?? []
    }
    
    /// Default evaluation returns no action so existing strategies remain opt-in.
    func evaluate(update: StrategyEvaluationContext) async -> [StrategyAction] {
        []
    }
}
