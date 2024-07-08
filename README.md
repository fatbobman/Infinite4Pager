# Infinite4Pager

Infinite4Pager is a flexible and powerful SwiftUI component that provides infinite scrolling capabilities in four directions: up, down, left, and right. It's perfect for creating image galleries, card decks, or any other content that requires seamless navigation in multiple directions.

## Features

- Infinite scrolling in four directions
- Support for both finite and infinite page counts
- Customizable threshold ratios for page switching
- Smooth animations and gesture handling
- Adaptive to different screen sizes
- 100% SwiftUI

## Requirements

- iOS 17.0+
- Xcode 14.0+
- Swift 5.10+

## Installation

### Swift Package Manager

You can add Infinite4Pager to your project using Swift Package Manager. In Xcode, go to File > Swift Packages > Add Package Dependency and enter the repository URL:

https://github.com/yourusername/Infinite4Pager.git

## Usage

Here's a basic example of how to use Infinite4Pager:

```swift
import SwiftUI
import Infinite4Pager

struct ContentView: View {
    var body: some View {
        Infinite4Pager(
            initialHorizontalPage: 0,
            initialVerticalPage: 0,
            totalHorizontalPage: 5,
            totalVerticalPage: 5,
            getPage: { h, v in
                Text("Page (\(h), \(v))")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.blue.opacity(0.3))
            }
        )
        .ignoresSafeArea()
    }
}
```

For more advanced usage and customization options, please refer to the documentation.

## Customization

Infinite4Pager offers several customization options:

- `initialHorizontalPage` and `initialVerticalPage`: Set the starting page
- `totalHorizontalPage` and `totalVerticalPage`: Set the total number of pages (or `nil` for infinite scrolling)
- `horizontalThresholdRatio` and `verticalThresholdRatio`: Adjust the sensitivity of page switching
- `bounce`: Enable or disable additional placeholder views to prevent blank spaces during bounce animations

The `bounce` parameter, when set to `true`, creates extra placeholder views beyond the immediate adjacent pages. This prevents blank or empty spaces from appearing during bouncing animations, especially when users scroll quickly or overshoot the page boundaries. It ensures a seamless visual experience even during rapid or exaggerated scrolling motions.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

Infinite4Pager is available under the MIT license. See the LICENSE file for more info.
