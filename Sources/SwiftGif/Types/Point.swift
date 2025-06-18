/// A 2D coordinate point.
struct Point: Hashable {
    static let zero: Point = Point(x: 0, y: 0)

    var x: Int
    var y: Int
}
