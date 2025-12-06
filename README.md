# TradingStrategy

Core protocol and utilities for describing and evaluating trading strategies in Swift. The package focuses on async-friendly, multi-chart strategies so you can load data concurrently and evaluate synchronized bar updates cleanly.

## Features
- Async strategy initialization that can fetch chart data in parallel using `StrategyChartInput`.
- Multi-chart awareness with ordered evaluation via `chartOrder` and `StrategyEvaluationContext`.
- Common supporting types for charts, indicators, levels, and pattern results.
- Designed for per-bar evaluation in both backtests and live environments.

## Installation (Swift Package Manager)
Add the package dependency to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/TradeWithIt/Strategy.git", branch: "main")
],
targets: [
    .target(
        name: "YourTarget",
        dependencies: [
            .product(name: "TradingStrategy", package: "Strategy")
        ]
    )
]
```

Minimum platforms: macOS 10.15 / iOS 13 (for Swift concurrency APIs used in the library).

## Quick Start
Define chart inputs that load data asynchronously, then initialize your strategy:

```swift
import TradingStrategy

let inputs = [
    StrategyChartInput(id: ChartID("ES")) {
        // Fetch or generate candlesticks for the chart
        try await loadCandles()
    }
]

let strategy = try await MyStrategy(charts: inputs)
```

Implement your strategy by conforming to `Strategy`:

```swift
struct MyStrategy: Strategy {
    let charts: [ChartID: StrategyChart]

    init(charts inputs: [StrategyChartInput]) async throws {
        self.charts = try await inputs.loadCharts()
    }

    func evaluate(update: StrategyEvaluationContext) async -> [StrategyAction] {
        guard let primary = primaryChart?.mostRecentBar else { return [.none] }
        // Decide whether to enter/exit based on your logic
        return [.none]
    }

    // Implement the remaining required methods such as shouldEnterWitUnitCount, exitTargets, shouldExit.
}
```

`StrategyEvaluationContext` provides synchronized bar updates across charts, plus metadata like equity, tick value, and fees so you can produce `StrategyAction` decisions per bar.

## Running Tests

```
swift test
```

## License
Licensed under the MIT License. See `LICENSE` for details.
