import Foundation

struct TableBasedImageData {
    let maxStackSize = 4096
    let nullCode = -1

    var pixelIndices: Data
    var lzwMinimumCodeSize: Int

    init(inputStream: ByteReaderStream, pixelCount: Int) throws {
        pixelIndices = Data()

        var nextAvailableCode = 0 // The next code to be added to the dictionary
        var currentCodeSize = 0
        var inCode = 0
        var previousCode = 0
        var code = 0
        var datum = 0 // Temporary storage for codes read from the input stream
        var meaningfulBitsInDatum = 0 // Number of bits of useful information held in the datum variable
        var firstCode = 0 // First code read from the stream since last clear code
        var indexInDataBlock = 0
        var pixelIndex = 0

        // Number of bytes still to be extracted from the current data block
        var bytesToExtract = 0

        var prefix: [Int] = .init(repeating: 0, count: maxStackSize)
        var suffix: Data = Data(count: maxStackSize)
        var pixelStack: Data = .init(count: pixelCount)
        var pixelStackIndex = 0

        lzwMinimumCodeSize = Int(try inputStream.readByte())
        let clearCode = getClearCode()
        let endOfInformation = getEndOfInformation()
        nextAvailableCode = clearCode + 2
        previousCode = nullCode
        currentCodeSize = getInitialCodeSize()

        code = 0
        while code < clearCode {
            suffix[code] = UInt8(code)
            code += 1
        }

        // MARK: - Decompress LZW image data

        // Initialize the block to an empty data block. This will be overwritten
        // first time through the loop with a data block read from the input
        // stream.
        var block = DataBlock()

        pixelIndex = 0

        var pixelIndices = Data(count: pixelCount)
        try pixelIndices.withUnsafeMutableBytes { (pixelIndicesPointer: UnsafeMutableRawBufferPointer) in
            try pixelStack.withUnsafeMutableBytes { (pixelStack: UnsafeMutableRawBufferPointer) in
                while pixelIndex < pixelCount {
                    if pixelStackIndex == 0 {
                        // There are no pixels in the stack at the moment so...
                        if meaningfulBitsInDatum < currentCodeSize {
                            // Then we don't have enough bits in the datum to make a code;
                            // we need to get some more from the current data block, or
                            // we may need to read another data block from the stream
                            if bytesToExtract == 0 {
                                // Then we've extracted all the bytes from the current
                                // data block, so...

                                block = try DataBlock(inputStream: inputStream)
                                bytesToExtract = block.actualBlockSize

                                // Point to the first byte in the new data block
                                indexInDataBlock = 0

                                if block.isTooShort {
                                    // Then we've reached the end of the stream prematurely
                                    break
                                }

                                if bytesToExtract == 0 {
                                    // Then it's a block terminator, end of image data
                                    // (this is a data block other than the first one)
                                    break
                                }
                            }

                            // Append the contents of the current byte in the data block
                            // to the beginning of the datum
                            datum += Int(block[indexInDataBlock]) << meaningfulBitsInDatum

                            // So we've now got 8 more bits of information in the datum.
                            meaningfulBitsInDatum += 8

                            // Point to the next byte in the data block
                            indexInDataBlock += 1

                            // We've got one less byte still to read from the data block
                            // now.
                            bytesToExtract -= 1

                            // And carry on reading through the data block
                            continue
                        }

                        // Get the least significant bits from the read datum, up to the
                        // maximum allowed by the current code size.
                        code = datum & getMaximumPossibleCode(currentCodeSize: currentCodeSize)

                        // Drop the bits we've just extracted from the datum
                        datum >>= currentCodeSize

                        // Reduce the count of meaningful bits held in the datum
                        meaningfulBitsInDatum -= currentCodeSize

                        if code == endOfInformation {
                            // We've reached an explicit marker for the end of the image
                            // data
                            break
                        }

                        if code > nextAvailableCode {
                            // We expect the code to be either one which is already in
                            // the dictionary, or the next available one to be added. If
                            // it's neither of these then abandon processing of the image.
                            throw GifError.dataCorrupted()
                        }

                        if code == clearCode {
                            // We can get a clear code at any point in the image data,
                            // this is an instruction to reset the decoder and empty the
                            // dictionary of codes.
                            currentCodeSize = getInitialCodeSize()
                            nextAvailableCode = getClearCode() + 2
                            previousCode = nullCode

                            // Carry on reading from the input stream
                            continue
                        }

                        if previousCode == nullCode {
                            // This is the first code read since the start of the image
                            // data or the most recent clear code.
                            // There's no previously read code in memory yet, so get pixel
                            // index for the current code and add it to the stack.
                            pixelStack[pixelStackIndex] = suffix[code]
                            pixelStackIndex += 1
                            previousCode = code
                            firstCode = code

                            // And carry on to the next pixel
                            continue
                        }

                        inCode = code
                        if code == nextAvailableCode {
                            pixelStack[pixelStackIndex] = UInt8(truncatingIfNeeded: firstCode)
                            pixelStackIndex += 1
                            code = previousCode
                        }

                        while code > clearCode {
                            pixelStack[pixelStackIndex] = suffix[code]
                            pixelStackIndex += 1
                            code = prefix[code]
                        }

                        firstCode = Int(suffix[code] & 0xFF)
                        pixelStack[pixelStackIndex] = UInt8(truncatingIfNeeded: firstCode)
                        pixelStackIndex += 1

                        // This fix is based off of ImageSharp's LzwDecoder.cs:
                        // https://github.com/SixLabors/ImageSharp/blob/8899f23c1ddf8044d4dea7d5055386f684120761/src/ImageSharp/Formats/Gif/LzwDecoder.cs

                        // Fix for Gifs that have 'deferred clear code' as per here:
                        // https://bugzilla.mozilla.org/show_bug.cgi?id=55918
                        if nextAvailableCode < maxStackSize {
                            prefix[nextAvailableCode] = previousCode & 0xFFFF
                            suffix[nextAvailableCode] = UInt8(firstCode & 0xFF)
                            nextAvailableCode += 1

                            if nextAvailableCode & ((1 << currentCodeSize) - 1) == 0 {
                                // We've reached the largest code possible for this size
                                if nextAvailableCode < maxStackSize {
                                    // So increase the code size by 1
                                    currentCodeSize += 1
                                }
                            }
                        }

                        previousCode = inCode
                    }

                    // Pop all the pixels currently on the stack off, and add them to the
                    // return value
                    pixelStackIndex -= 1
                    pixelIndicesPointer[pixelIndex] = pixelStack[pixelStackIndex]
                    pixelIndex += 1
                }
            }
        }

        self.pixelIndices = pixelIndices

        if pixelIndex < pixelCount {
            throw GifError.dataCorrupted()
        }

        // MARK: -
    }

    // A special Clear code is defined which resets all compression /
    // decompression parameters and tables to a start-up state.
    // The value of this code is 2 ^ code size.
    // For example if the code size indicated was 4 (image was 4 bits/pixel)
    // the Clear code value would be 16 (10000 binary).
    // The Clear code can appear at any point in the image data stream and
    // therefore requires the LZW algorithm to process succeeding codes as
    // if a new data stream was starting.
    // Encoders should output a Clear code as the first code of each image
    // data stream.
    func getClearCode() -> Int {
        1 << lzwMinimumCodeSize
    }

    // Gets the size in bits of the first code to add to the dictionary.
    func getInitialCodeSize() -> Int {
        lzwMinimumCodeSize + 1
    }

    // Gets the code which explicitly marks the end of the image data in the stream.
    func getEndOfInformation() -> Int {
        getClearCode() + 1
    }

    // Gets the highest possible code for the supplied code size - when
    // all bits in the code are set to 1.
    // This is used as a bitmask to extract the correct number of least
    // significant bits from the datum to form a code.
    func getMaximumPossibleCode(currentCodeSize: Int) -> Int {
        (1 << currentCodeSize) - 1
    }
}
