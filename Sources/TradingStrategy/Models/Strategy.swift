import Foundation

public protocol Strategy {
    var recentCandlesSize: Int { get }
    var recentCandlesPatternPrediction: Bool { get }
    var patternIdentified: Bool { get }
    var patterInformatioin: [String: Bool] { get }
    
    init(candles: [Klines])
    init(candles: [Klines], multiplier: Int)
}