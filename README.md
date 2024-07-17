# Infinite4Pager

Infinite4Pager is a flexible and powerful SwiftUI component that provides infinite scrolling capabilities in four directions: up, down, left, and right. It's perfect for creating image galleries, card decks, or any other content that requires seamless navigation in multiple directions.

**Please read [Developing an Infinite Four-Direction Scrollable Pager with SwiftUI](https://fatbobman.com/en/posts/developing-an-infinite-four-direction-scrollable-pager-with-swiftui/) to understand the implementation principles of this library and for more usage notes.**

https://github.com/fatbobman/Infinite4Pager/assets/55673881/e98bd549-e639-46e7-9adf-b9e82b75b858

## Features

- Infinite scrolling in four directions
- Support for both finite and infinite page counts
- Customizable threshold ratios for page switching
- Smooth animations and gesture handling
- Adaptive to different screen sizes
- 100% SwiftUI

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.10+

## Installation

### Swift Package Manager

You can add Infinite4Pager to your project using Swift Package Manager. In Xcode, go to File > Swift Packages > Add Package Dependency and enter the repository URL:

https://github.com/fatbobman/Infinite4Pager.git

## Usage

Here's a basic example of how to use Infinite4Pager:

```swift
import SwiftUI
import Infinite4Pager

struct TestView: View {
  var body: some View {
    Infinite4Pager(
      initialHorizontalPage: 2,
      initialVerticalPage: 2,
      totalHorizontalPage: 5,
      totalVerticalPage: 5,
      enableClipped: false,
      enablePageVisibility: true,
      getPage: { h, v in
        PageView(h: h, v: v)
      }
    )
    .ignoresSafeArea()
  }
}

struct PageView: View {
  let h: Int
  let v: Int
  let images = ["img1", "img2", "img3", "img4", "img5"]
  @Environment(\.pagerCurrentPage) var mainPage
  @State var percent: Double = 0
  @State var isCurrent = false
  var body: some View {
    VStack {
      let index = abs((h + v) % (images.count - 1))
      Color.clear
        .overlay(
          Image(images[index])
            .resizable()
            .aspectRatio(contentMode: .fill)
            .overlay(
              VStack {
                Text("\(h),\(v)")
                Text("visibility \(percent)")
                Text("isCurrent:\(isCurrent)")
              }
              .font(.largeTitle)
              .foregroundStyle(.white)
              .padding()
              .background(
                RoundedRectangle(cornerRadius: 15)
                  .foregroundColor(.black)
              )
            )
        )
        .onPageVisible { percent in
          if let percent {
            self.percent = percent
          }
        }
        .task(id: mainPage) {
          if let mainPage {
            if mainPage.horizontal == h, mainPage.vertical == v {
              isCurrent = true
            }
          }
        }
        .clipped()
    }
  }
}
```

For more advanced usage and customization options, please refer to the documentation.

## Customization

Infinite4Pager offers several customization options:

- `initialHorizontalPage` and `initialVerticalPage`: Set the starting page
- `totalHorizontalPage` and `totalVerticalPage`: Set the total number of pages (or `nil` for infinite scrolling)
- `horizontalThresholdRatio` and `verticalThresholdRatio`: Adjust the sensitivity of page switching
- `enableClipped` : enable clipped
- `animation` : page scroll animation
- `enablePageVisibility` : Whether to enable view visibility awareness. If false, onPageVisible will not respond.

## Page Visibility and Data Management

A view modifier similar to `onScrollVisibilityChange` that provides the view with the current proportion of the visible area.

```swift
  PageView()
   .onPageVisible { percent in
    if percent > 0.1 {
      // play video
    }
  }
```

The environment value pagerCurrentPage provides information about the current view within the container.

```swift
.task(id: mainPage) {
  if let mainPage {
    if mainPage.horizontal == h, mainPage.vertical == v {
      // load data , enable animation
    }
  }
}
```


## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

Infinite4Pager is available under the MIT license. See the LICENSE file for more info.
