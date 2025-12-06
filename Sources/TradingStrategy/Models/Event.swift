import Foundation

public protocol Annoucment: Sendable {
    var timestamp: TimeInterval  { get }
    var annoucmentImpact: AnnoucmentImpact { get }
}

public enum AnnoucmentImpact: Sendable {
    case high
    case medium
    case low
}
