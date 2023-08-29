# DocScanner and ScanInterpreter

![Swift](https://img.shields.io/badge/Swift-5.5-orange.svg)

This repository contains `DocScanner`, a SwiftUI wrapper around `VNDocumentCameraViewController`, and `ScanInterpreter`, a tool for interpreting scanned documents and cards using the Vision and VisionKit frameworks. It offers image to text parsing capabilities.

## Installation

**Clone the repository:**

bash
Copy code
```bash
git clone https://github.com/your/repo.git
```
Add the Swift files to your Xcode project.

Ensure you have the required frameworks (Combine, SwiftUI, Vision, VisionKit, and NaturalLanguage) included in your project.

Use the provided code examples to integrate DocScanner and ScanInterpreter into your app.


## DocScanner

The `DocScanner` struct provides a convenient way to integrate document scanning functionality into your SwiftUI apps. It wraps the `VNDocumentCameraViewController` and handles the scanning process. You can interpret the scanned documents by providing a `ScanInterpreter` implementation.

### Example

Here's how you can use the `DocScanner` in your SwiftUI app:

```swift
import SwiftUI

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
