/// A 2D coordinate point.
public struct Point: Hashable {
    nonisolated(unsafe)
    public static let zero: Point = Point(x: 0, y: 0)

    public var x: Int
    public var y: Int
}
