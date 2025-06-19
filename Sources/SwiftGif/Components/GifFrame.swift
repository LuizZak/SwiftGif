/// A single image frame from a GIF file.
public struct GifFrame {
    /// Index of frame, starting from zero.
    public var index: Int

    /// Image data decoded from frame, in ARGB format.
    public var image: ImageData

    /// Delay, in hundredths of milliseconds (1/100), to wait while displaying
    /// this frame.
    public var delay: Int

    /// Whether this frame expects some sort of user input to progress.
    public var expectsUserInput: Bool

    /// Local color table, if present.
    public var localColorTable: ColorTable?

    /// The image descriptor for this frame.
    public var imageDescriptor: ImageDescriptor

    /// The computed background color for this frame.
    public var backgroundColor: Color

    /// The logical screen descriptor for the GIF file.
    public var logicalScreenDescriptor: LogicalScreenDescriptor

    /// A global color table allocated to this frame, if available.
    public var globalColorTable: ColorTable?

    /// The computed graphic control extension for this frame.
    public var graphicControlExtension: GraphicControlExtension

    init(
        inputStream: ByteReaderStream,
        logicalScreenDescriptor: LogicalScreenDescriptor,
        globalColorTable: ColorTable?,
        graphicControlExtension: GraphicControlExtension,
        previousFrame: GifFrame?,
        previousFrameBut1: GifFrame?,
        index: Int
    ) throws {
        self.index = index
        self.logicalScreenDescriptor = logicalScreenDescriptor
        self.globalColorTable = globalColorTable
        self.graphicControlExtension = graphicControlExtension
        self.expectsUserInput = graphicControlExtension.expectsUserInput

        let transparentColorIndex = graphicControlExtension.transparentColorIndex
        let imageDescriptor = try ImageDescriptor(inputStream: inputStream)
        var backgroundColor = Color.transparentBlack

        var activeColorTable: ColorTable
        if imageDescriptor.hasLocalColorTable {
            activeColorTable = try ColorTable(inputStream: inputStream, numberOfColors: imageDescriptor.localColorTableSize)
            localColorTable = activeColorTable
        } else {
            if let globalColorTable {
                activeColorTable = globalColorTable
            } else {
                throw GifError.dataCorrupted("Found frame with no local color table in no global color table GIF file")
            }

            if logicalScreenDescriptor.backgroundColorIndex == transparentColorIndex {
                backgroundColor = Color.transparentBlack
            }
        }

        // Decode pixel data
        let pixelCount = imageDescriptor.size.width * imageDescriptor.size.height
        let tbid = try TableBasedImageData(inputStream: inputStream, pixelCount: pixelCount)
        if tbid.pixelIndices.isEmpty {
            throw GifError.dataCorrupted("Found frame with no pixel data")
        }

        // Skip any remaining blocks up to the next block terminator (in case
        // there is any surplus data before the next frame)
        DataBlock.skipBlocks(inputStream: inputStream)

        delay = graphicControlExtension.delayTime
        self.imageDescriptor = imageDescriptor
        self.backgroundColor = backgroundColor

        let baseImage = Self.getBaseImage(
            previousFrame: previousFrame,
            previousFrameBut1: previousFrameBut1,
            lsd: logicalScreenDescriptor,
            gce: graphicControlExtension,
            act: activeColorTable
        )

        // MARK: - Decode image

        var pass = 1
        var interlaceRowIncrement = 8
        var interlaceRowNumber = 0
        let hasTransparent = graphicControlExtension.hasTransparentColor
        let transparentColor = graphicControlExtension.transparentColorIndex

        let logicalWidth = logicalScreenDescriptor.screenSize.width
        let logicalHeight = logicalScreenDescriptor.screenSize.height

        let imageX = imageDescriptor.position.x
        let imageY = imageDescriptor.position.y
        let imageWidth = imageDescriptor.size.width
        let imageHeight = imageDescriptor.size.height
        let isInterlaced = imageDescriptor.isInterlaced
        let pixelIndices = tbid.pixelIndices
        let numColors = activeColorTable.tableSize
        let colors = activeColorTable.intColors

        baseImage.withUnsafeMutableBytes { pointer in
            pointer.withMemoryRebound(to: UInt32.self) { imageBuffer in
                for i in 0..<imageHeight {
                    var pixelRowNumber = i

                    if isInterlaced {
                        if interlaceRowNumber >= imageHeight {
                            pass += 1

                            switch pass {
                            case 2:
                                interlaceRowNumber = 4

                            case 3:
                                interlaceRowNumber = 2
                                interlaceRowIncrement = 4

                            case 4:
                                interlaceRowNumber = 1
                                interlaceRowIncrement = 2

                            default:
                                break
                            }
                        }

                        pixelRowNumber = interlaceRowIncrement
                        interlaceRowNumber += interlaceRowIncrement
                    }

                    pixelRowNumber += imageY
                    if pixelRowNumber >= logicalHeight {
                        continue
                    }

                    let k = pixelRowNumber * logicalWidth
                    var dx = k + imageX // Start of line in dest
                    let dlim = min(k + logicalWidth, dx + imageWidth) // End of dest line

                    var sx = i * imageWidth // Start of line in source

                    while dx < dlim {
                        let indexInColorTable = Int(pixelIndices[sx])
                        sx += 1

                        // Set this pixel's color if its index isn't the transparent color
                        // index, or if this frame doesn't have a transparent color
                        if !hasTransparent || indexInColorTable != transparentColor {
                            if indexInColorTable < numColors {
                                let color = colors[indexInColorTable]

                                imageBuffer[dx] = color
                            }
                        }

                        dx += 1
                    }
                }
            }
        }

        self.image = baseImage

        // MARK: -
    }

    static func getBaseImage(
        previousFrame: GifFrame?,
        previousFrameBut1: GifFrame?,
        lsd: LogicalScreenDescriptor,
        gce: GraphicControlExtension,
        act: ColorTable
    ) -> ImageData {
        var act = act
        var previousDisposalMethod: GraphicControlExtension.DisposalMethod

        if let previousFrame {
            previousDisposalMethod = previousFrame.graphicControlExtension.disposalMethod

            if previousDisposalMethod == .restoreToPrevious && previousFrameBut1 == nil {
                previousDisposalMethod = .restoreToBackgroundColor
            }
        } else {
            previousDisposalMethod = .notSpecified
        }

        var baseImage: ImageData
        var backgroundColorIndex = lsd.backgroundColorIndex
        if let previousFrame {
            backgroundColorIndex = previousFrame.logicalScreenDescriptor.backgroundColorIndex
        }

        var transparentColorIndex = gce.transparentColorIndex
        if let previousFrame {
            transparentColorIndex = previousFrame.graphicControlExtension.transparentColorIndex
        }

        act = previousFrame?.localColorTable ?? previousFrame?.globalColorTable ?? act

        if let previousFrame {
            baseImage = previousFrame.image.copy()
        } else {
            baseImage = ImageData(size: lsd.screenSize)
        }

        switch previousDisposalMethod {
        case .notSpecified, .doNotDispose:
            break

        case .restoreToBackgroundColor:
            var backgroundColor: Color
            if backgroundColorIndex == transparentColorIndex {
                backgroundColor = .transparentBlack
            } else {
                if backgroundColorIndex < act.tableSize {
                    backgroundColor = act.color(index: backgroundColorIndex)
                } else {
                    backgroundColor = .black
                }
            }

            // Adjust transparency
            backgroundColor.alpha = 0

            guard let previousFrame else {
                break
            }

            if previousFrame.imageDescriptor.position == Point.zero && previousFrame.imageDescriptor.size == lsd.screenSize {
                baseImage.fill(color: backgroundColor)
            } else {
                let minY = previousFrame.imageDescriptor.position.y
                let maxY = previousFrame.imageDescriptor.position.y + previousFrame.imageDescriptor.size.height

                for y in minY..<maxY {
                    baseImage.fillRow(
                        x: previousFrame.imageDescriptor.position.x,
                        y: y,
                        width: previousFrame.imageDescriptor.position.x + previousFrame.imageDescriptor.size.width,
                        argb: backgroundColor.asARGB
                    )
                }
            }

        case .restoreToPrevious:
            if let previousFrameBut1 {
                baseImage = previousFrameBut1.image.copy()
            } else if let previousFrame {
                baseImage = previousFrame.image.copy()
            }
        }

        return baseImage
    }
}
