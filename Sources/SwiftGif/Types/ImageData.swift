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
