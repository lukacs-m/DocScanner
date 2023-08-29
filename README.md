# DocScanner and ScanInterpreter

![Swift](https://img.shields.io/badge/Swift-5.5-orange.svg)

This repository contains `DocScanner`, a SwiftUI wrapper around `VNDocumentCameraViewController`, and `ScanInterpreter`, a tool for interpreting scanned documents and cards using the Vision and VisionKit frameworks. It offers image to text parsing capabilities.

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
and add `https://github.com/your/repo.git`.

In our info.plist file, you will need to add a new propertie called `"Privacy — Camera Usage Description"` and set a description explaining the usage of the camera in your app. For example: **"Allow camera usage to scan documents and parse their content."**

Use the provided code examples to integrate DocScanner and ScanInterpreter into your app.


## DocScanner

The `DocScanner` struct provides a convenient way to integrate document scanning functionality into your SwiftUI apps. It wraps the `VNDocumentCameraViewController` and handles the scanning process. You can interpret the scanned documents by providing a element implementing the`ScanInterpreting` protocol.

The View returns the scanned results using 3 distinct methods:
- Callback
-  `Combine` `PassthroughSubject`
- SwiftUI `@Binding`

All of the above are optional and can be used or not. You can combine several of them at the same time if wanted.

### Example

Here's how you can use the `DocScanner` in your SwiftUI:

```swift
import SwiftUI
import DocScanner

struct ContentView: View {
    @State var scanResult: ScanResponse?

    var body: some View {
        VStack {
            // Other UI components
            DocScanner(scanResult: $scanResult)
            // Other UI components
        }
    }
}

Please refer to `DocScannerDemo` to have ideas on how to use and interact with the scan results

## DocScanner

The `DocScanner` struct provides a convenient way to integrate document scanning functionality into your SwiftUI apps. It wraps the `VNDocumentCameraViewController` and handles the scanning process. You can interpret the scanned documents by providing a `ScanInterpreter` implementation.

The View returns the scanned results using 3 distinct methods:
- Callback
-  `Combine` `PassthroughSubject`
- SwiftUI `@Binding`

All of the above are optional and can be used or not. You can combine several of them at the same time if wanted.

### Example

Here's how you can use the `DocScanner` in your SwiftUI:

```swift
import SwiftUI
import DocScanner

struct ContentView: View {
    @State var scanResult: ScanResponse?

    var body: some View {
        VStack {
            // Other UI components
            DocScanner(scanResult: $scanResult)
            // Other UI components
        }
    }
}

Please refer to `DocScannerDemo` to have ideas on how to use and interact with the scan results

## ScanInterpreter

The package come with a free `ScanInterpreter`. This actor is responsible for interpreting scanned documents and cards. It extracts text from scanned images and provides structured information about the content. It supports both document and card scanning.

We can of course decide to create your on interpreter to use with `DocScanner`.

If you scan documents the reponse of `ScanInterpreter` will be of type `ScannedDocument` otherwise it returns a `CardDetails`.

As for the interpreter feel free to create you own `ScanResponse` if needed.