// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "TradingStrategy",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13)
    ],
    products: [
        .library(name: "TradingStrategy", targets: ["TradingStrategy"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "TradingStrategy", dependencies: []),
        .testTarget(name: "TradingStrategyTests", dependencies: ["TradingStrategy"]),
    ]
)
