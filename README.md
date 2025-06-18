# SwiftGif

A pure-swift Gif file parsing library.

Usage:

```swift
let data: Data = ...
let decoder = try GifDecoder(data: data)

// Fetch frame information
for frame in decoder.frames {
    print(frame.index, ":", frame.delay)

    // Do something with raw ARGB image data...
    doSomething(frame.image.data)
}
```
