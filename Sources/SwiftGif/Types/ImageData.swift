import Foundation

/// Holds image data information as a series of ARGB color values in a data stream.
public final class ImageData {
    public let size: Size
    private(set) var data: Data

    /// Initializes a new blank image, with the given size, with all data values
    /// initialized to zero.
    public init(size: Size) {
        self.size = size

        data = Data(count: size.width * size.height * 4)
    }

    /// Makes a fresh copy of this image data, with independent pixel data information.
    public func copy() -> ImageData {
        let copy = ImageData(size: size)
        copy.data = Data(data)
        return copy
    }

    public func withUnsafeMutableBytes(_ closure: (_ pointer: UnsafeMutableRawBufferPointer) -> Void) {
        data.withUnsafeMutableBytes { pointer in
            closure(pointer)
        }
    }

    func setPixel(index: Int, argb: UInt32) {
        precondition(index >= 0 && index < size.width * size.height, "Attempting to set pixel out of image bounds.")

        data[index * 4] = UInt8(truncatingIfNeeded: (argb >> 24) & 0xFF)
        data[index * 4 + 1] = UInt8(truncatingIfNeeded: (argb >> 16) & 0xFF)
        data[index * 4 + 2] = UInt8(truncatingIfNeeded: (argb >> 8) & 0xFF)
        data[index * 4 + 3] = UInt8(truncatingIfNeeded: argb & 0xFF)
    }

    /// Sets a given pixel's color on this image.
    ///
    /// Precondition: x and y are within the range of the image's bounds.
    func setPixel(x: Int, y: Int, argb: UInt32) {
        let index = (x + y * size.width)

        setPixel(index: index, argb: argb)
    }

    /// Sets a given pixel's color on this image.
    ///
    /// Precondition: x and y are within the range of the image's bounds.
    func setPixel(x: Int, y: Int, color: Color) {
        setPixel(x: x, y: y, argb: color.asARGB)
    }

    /// Fills a given row of pixel data with a given color.
    func fillRow(x: Int, y: Int, width: Int, argb: UInt32) {
        let width = min(width, self.size.width - x)
        let offset = x + y * size.width

        withUnsafeMutableBytes { pointer in
            pointer.withMemoryRebound(to: UInt32.self) { buffer in
                buffer[offset..<(offset + width)].update(repeating: argb)
            }
        }
    }

    /// Fills the entire data buffer with a given ARGB color value.
    func fill(argb: UInt32) {
        withUnsafeMutableBytes { pointer in
            pointer.withMemoryRebound(to: UInt32.self) { buffer in
                buffer.update(repeating: UInt32(argb))
            }
        }
    }

    /// Fills the entire data buffer with a given Color value.
    func fill(color: Color) {
        fill(argb: color.asARGB)
    }
}
