import Foundation
import CoreGraphics

/// Shared models and helpers for automated test suites
public struct TestVector2 {
    public var x: Double
    public var y: Double
    public init(_ x: Double, _ y: Double) { self.x = x; self.y = y }
}

public struct TestVector4 {
    public var r: Double
    public var g: Double
    public var b: Double
    public var a: Double
    public init(_ r: Double, _ g: Double, _ b: Double, _ a: Double) {
        self.r = r; self.g = g; self.b = b; self.a = a
    }
}

public enum TestResult {
    case pass
    case fail(String)
}

public struct TestCaseRecord {
    public let name: String
    public let tier: Int
    public let feature: String
    public let result: TestResult
    public let durationMs: Double
}
