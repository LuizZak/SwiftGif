/// Represents an internal color table color value as an ARGB color value.
struct Color {
    static let transparentBlack: Color = Color(hex: 0x00000000)
    static let black: Color = Color(hex: 0xFF000000)

    var alpha: UInt8
    var red: UInt8
    var green: UInt8
    var blue: UInt8

    /// Returns the value of this color as a 32-bit integer ARGB color value.
    var asARGB: UInt32 {
        (UInt32(alpha) << 24) | (UInt32(red) << 16) | (UInt32(green) << 8) | UInt32(blue)
    }

    init(hex: UInt32) {
        alpha = UInt8((hex >> 24) & 0xFF)
        red = UInt8((hex >> 16) & 0xFF)
        green = UInt8((hex >> 8) & 0xFF)
        blue = UInt8(hex & 0xFF)
    }
}
