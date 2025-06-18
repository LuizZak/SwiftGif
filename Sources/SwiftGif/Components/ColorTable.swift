/// A global or local color table which forms part of a GIF data stream.
struct ColorTable {
    /// Gets the entire color table stored in this color table.
    var intColors: [UInt32]

    /// Gets the length of this color table.
    var tableSize: Int {
        intColors.count
    }

    init(inputStream: ByteReaderStream, numberOfColors: Int) throws {
        if numberOfColors < 0 || numberOfColors > 256 {
            throw GifError.dataCorrupted("Expected number of colors to be between 0 and 256, found \(numberOfColors)")
        }

        let bytesExpected = numberOfColors * 3

        if inputStream.remainingBytes < bytesExpected {
            throw GifError.dataCorrupted("Data too short for expected color table of size \(numberOfColors)")
        }

        let buffer = try inputStream.readData(length: bytesExpected)
        let colorsRead = bytesExpected / 3

        intColors = .init(repeating: 0, count: colorsRead)

        var j = 0
        for i in 0..<colorsRead {
            let r = buffer[j]
            let g = buffer[j + 1]
            let b = buffer[j + 2]

            j += 3

            intColors[i] = UInt32((255 << 24) | (r << 16) | (g << 8) | (b))
        }
    }

    /// Gets the color at a specified index in this color table as a ARGB integer.
    func colorInt(index: Int) -> UInt32 {
        intColors[index]
    }

    /// Gets the color at a specified index in this color table.
    func color(index: Int) -> Color {
        return Color(hex: colorInt(index: index))
    }
}
