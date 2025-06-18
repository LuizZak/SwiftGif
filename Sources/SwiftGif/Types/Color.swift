/// Represents an internal color table color value as an ARGB color value.
struct Color {
    static let transparentBlack: Color = Color(hex: 0x00000000)
    static let black: Color = Color(hex: 0xFF000000)

    var alpha: Int
    var red: Int
    var green: Int
    var blue: Int

    /// Returns the value of this color as a 32-bit integer ARGB color value.
    var asARGB: Int {
        (alpha << 24) | (red << 16) | (green << 8) | blue
    }

    init(hex: Int) {
        alpha = (hex >> 24) & 0xFF
        red = (hex >> 16) & 0xFF
        green = (hex >> 8) & 0xFF
        blue = hex & 0xFF
    }
}
