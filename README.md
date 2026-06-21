# DocScanner and ScanInterpreter

![Swift](https://img.shields.io/badge/Swift-6-orange.svg)
![Platform](https://img.shields.io/badge/iOS-18%2B-blue.svg)

This repository contains `DocScanner`, a SwiftUI wrapper around `VNDocumentCameraViewController`, and `ScanInterpreter`, a tool for interpreting scanned documents and cards using the Vision and VisionKit frameworks. It offers image to text parsing capabilities.

> **Requirements:** iOS 18+. Built with Swift 6 strict concurrency and the native async Vision API (`RecognizeTextRequest`).

## What
- [x] Document scanner
- [x] Image to text interpretor
- [x] Pure Swift, simple, lightweight & 0 dependencies

## Getting Started
* [Installation](#installation)
* [DocScanner](#docScanner)
    * [Example](#example)
* [ScanInterpreter](#ScanInterpreter)
 
### Installation

`DocScanner` is installed via the official [Swift Package Manager](https://swift.org/package-manager/).  

Select `Xcode`>`File`> `Swift Packages`>`Add Package Dependency...`  
and add `https://github.com/lukacs-m/DocScanner`.

In our info.plist file, you will need to add a new propertie called `"Privacy — Camera Usage Description"` and set a description explaining the usage of the camera in your app. For example: **"Allow camera usage to scan documents and parse their content."**

Use the provided code examples to integrate DocScanner and ScanInterpreter into your app.


## DocScanner

The `DocScanner` struct provides a convenient way to integrate document scanning functionality into your SwiftUI apps. It wraps the `VNDocumentCameraViewController` and handles the scanning process. You can interpret the scanned documents by providing a element implementing the`ScanInterpreting` protocol.

The view returns the scanned results through 3 optional channels, all delivering a `ScanOutcome` (`.scanned`, `.cancelled`, or `.failed`):
- A completion closure
- An `AsyncStream` — pass a `ScanResultStreamBox`, or use the higher-level `@Observable` `ScannerModel`
- SwiftUI `@Binding`

All of the above are optional. You can combine several of them at the same time if wanted.

### Example

Here's how you can use the `DocScanner` in your SwiftUI:

```swift
import SwiftUI
import DocScanner

struct ContentView: View {
    @State private var scanResult: (any ScanResult)?

    var body: some View {
        VStack {
            // Other UI components
            DocScanner(scanResult: $scanResult)
            // Other UI components
        }
    }
}
```

Prefer `async/await`? The `@Observable` `ScannerModel` owns a stream and republishes the latest result — just observe `scanner.latest`:

```swift
import SwiftUI
import DocScanner

struct ContentView: View {
    @State private var scanner = ScannerModel()

    var body: some View {
        VStack {
            DocScanner(resultStream: scanner.streamBox)
            if let result = scanner.latest {
                // use the scanned result
            }
        }
    }
}
```

For direct control, create your own `ScanResultStreamBox` and iterate its stream (`AsyncStream` is single-consumer, so don't also wrap it in a `ScannerModel`):

```swift
let streamBox = ScanResultStreamBox()
// pass streamBox to DocScanner(resultStream:), then:
for await outcome in streamBox.stream {
    print(outcome)
}
```

Please refer to `DocScannerDemo` to have ideas on how to use and interact with the scan results

## ScanInterpreter

The package comes with a free `ScanInterpreter`. This `Sendable` value type is responsible for interpreting scanned documents and cards. It extracts text from scanned images and provides structured information about the content. It supports both document and card scanning.

You can also create your own interpreter by conforming to the `ScanInterpreting` protocol and pass it to `DocScanner`.

If you scan documents the response of `ScanInterpreter` will be of type `ScannedDocument` otherwise it returns a `CardDetails`.

As for the interpreter, feel free to create your own `ScanResult` if needed.
