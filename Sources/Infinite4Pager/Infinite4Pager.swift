//
//  Infinite4Pager.swift
//  Infinite4Pager
//
//  Created by Yang Xu on 2024/7/8.
//

import SwiftUI

public struct Infinite4Pager<Content: View>: View {
  @State private var currentHorizontalPage: Int
  @State private var currentVerticalPage: Int
  @State private var offset: CGSize = .zero
  @State private var dragDirection: PageViewDirection = .none
  @State private var size: CGSize = .zero
  @Environment(\.scenePhase) var scenePhase

  let totalHorizontalPage: Int?
  let totalVerticalPage: Int?
  let horizontalThresholdRatio: CGFloat
  let verticalThresholdRatio: CGFloat
  let getPage: (Int, Int) -> Content
  let bounce: Bool

  private let animation = Animation.spring(
    response: 0.44,
    dampingFraction: 0.76,
    blendDuration: 0
  )

  public init(initialHorizontalPage: Int = 0,
       initialVerticalPage: Int = 0,
       totalHorizontalPage: Int? = nil,
       totalVerticalPage: Int? = nil,
       horizontalThresholdRatio: CGFloat = 0.33, // 移动距离阈值，百分比
       verticalThresholdRatio: CGFloat = 0.25,
       bounce: Bool = true,
       @ViewBuilder getPage: @escaping (Int, Int) -> Content)
  {
    _currentHorizontalPage = State(initialValue: initialHorizontalPage)
    _currentVerticalPage = State(initialValue: initialVerticalPage)
    self.totalHorizontalPage = totalHorizontalPage
    self.totalVerticalPage = totalVerticalPage
    self.horizontalThresholdRatio = horizontalThresholdRatio
    self.verticalThresholdRatio = verticalThresholdRatio
    self.getPage = getPage
    self.bounce = bounce
  }

  public var body: some View {
    CurrentPageView(
      currentHorizontalPage: currentHorizontalPage,
      currentVerticalPage: currentVerticalPage,
      totalHorizontalPage: totalHorizontalPage,
      totalVerticalPage: totalVerticalPage,
      bounce: bounce,
      getPage: getPage
    )
    .offset(x: offset.width, y: offset.height)
    .gesture(
      DragGesture()
        .onChanged { value in
          if dragDirection == .none {
            dragDirection = abs(value.translation.width) > abs(value.translation.height) ? .horizontal : .vertical
          }

          let newOffset: CGSize
          if dragDirection == .horizontal {
            let limitedX = boundedDragOffset(
              value.translation.width,
              pageSize: size.width,
              currentPage: currentHorizontalPage,
              totalPages: totalHorizontalPage
            )
            newOffset = CGSize(width: limitedX, height: 0)
          } else {
            let limitedY = boundedDragOffset(
              value.translation.height,
              pageSize: size.height,
              currentPage: currentVerticalPage,
              totalPages: totalVerticalPage
            )
            newOffset = CGSize(width: 0, height: limitedY)
          }

          offset = newOffset
        }
        .onEnded { value in
          let pageSize = dragDirection == .horizontal ? size.width : size.height
          let currentPage = dragDirection == .horizontal ? currentHorizontalPage : currentVerticalPage
          let totalPages = dragDirection == .horizontal ? totalHorizontalPage : totalVerticalPage
          let thresholdRatio = dragDirection == .horizontal ? horizontalThresholdRatio : verticalThresholdRatio

          let translation = dragDirection == .horizontal ? value.predictedEndTranslation.width : value.predictedEndTranslation.height
          let boundedTranslation = boundedDragOffset(translation, pageSize: pageSize, currentPage: currentPage, totalPages: totalPages)

          let direction = -Int(translation / abs(translation))

          let isAtBoundary = isAtBoundary(direction: direction)
          if abs(boundedTranslation) > pageSize * thresholdRatio, !isAtBoundary {
            let newOffset = CGSize(
              width: dragDirection == .horizontal ? CGFloat(-direction) * pageSize : 0,
              height: dragDirection == .vertical ? CGFloat(-direction) * pageSize : 0
            )

            withAnimation(.smooth(duration: 0.3)) {
              offset = newOffset
            } completion: {
              if dragDirection == .horizontal {
                if let total = totalHorizontalPage {
                  // 有限页面的情况
                  currentHorizontalPage = (currentHorizontalPage + (direction == 1 ? 1 : -1) + total) % total
                } else {
                  // 无限滚动的情况
                  currentHorizontalPage += direction == 1 ? 1 : -1
                }
              } else {
                if let total = totalVerticalPage {
                  // 有限页面的情况
                  currentVerticalPage = (currentVerticalPage + (direction == 1 ? 1 : -1) + total) % total
                } else {
                  // 无限滚动的情况
                  currentVerticalPage += direction == 1 ? 1 : -1
                }
              }
              dragDirection = .none
            }
          } else {
            withAnimation(.bouncy) {
              offset = .zero
              dragDirection = .none
            }
          }
        }
    )
    .onChange(of: currentHorizontalPage) {
      offset = .zero
    }
    .onChange(of: currentVerticalPage) {
      offset = .zero
    }
    // 退到后台时，调整位置。避免出现滚动到一半的场景
    .onChange(of: scenePhase) {
      if scenePhase == .background {
        offset = .zero
      }
    }
    .background(
      GeometryReader { proxy in
        let size = proxy.size
        Color.clear
          .task(id: size) { self.size = size }
      }
    )
  }

  // 判断是否为边界视图
  private func isAtBoundary(direction: Int) -> Bool {
    switch dragDirection {
    case .horizontal:
      if let total = totalHorizontalPage {
        // 有限水平页面的情况
        return (currentHorizontalPage == 0 && direction < 0) || (currentHorizontalPage == total - 1 && direction > 0)

      } else {
        // 无限水平滚动的情况
        return false
      }
    case .vertical:
      if let total = totalVerticalPage {
        // 有限垂直页面的情况
        return (currentVerticalPage == 0 && direction < 0) ||
          (currentVerticalPage == total - 1 && direction > 0)
      } else {
        // 无限垂直滚动的情况
        return false
      }
    case .none:
      return false
    }
  }

  private func boundedDragOffset(
    _ offset: CGFloat,
    pageSize: CGFloat,
    currentPage: Int,
    totalPages: Int?
  ) -> CGFloat {
    let normalThreshold = pageSize / 1.8
    let maxThreshold = pageSize / 1.5

    if let total = totalPages {
      if (currentPage == 0 && offset > 0) || (currentPage == total - 1 && offset < 0) {
        if abs(offset) <= normalThreshold {
          return offset
        } else {
          let overThreshold = abs(offset) - normalThreshold
          let progress = overThreshold / (maxThreshold - normalThreshold)
          let dampeningFactor = 1 - pow(progress, 2)
          let dampenedOverThreshold = overThreshold * dampeningFactor
          return (offset > 0 ? 1 : -1) * (normalThreshold + dampenedOverThreshold)
        }
      }
    }
    return offset
  }
}

enum PageViewDirection {
  case horizontal, vertical, none
}

struct CurrentPageView<Content: View>: View {
  let currentHorizontalPage: Int
  let currentVerticalPage: Int
  let totalHorizontalPage: Int?
  let totalVerticalPage: Int?
  let bounce: Bool
  let getPage: (Int, Int) -> Content

  init(
    currentHorizontalPage: Int,
    currentVerticalPage: Int,
    totalHorizontalPage: Int?,
    totalVerticalPage: Int?,
    bounce: Bool = false,
    getPage: @escaping (Int, Int) -> Content
  ) {
    self.currentHorizontalPage = currentHorizontalPage
    self.currentVerticalPage = currentVerticalPage
    self.totalHorizontalPage = totalHorizontalPage
    self.totalVerticalPage = totalVerticalPage
    self.bounce = bounce
    self.getPage = getPage
  }

  var body: some View {
    Color.clear
      .overlay(alignment: .center) {
        getPage(currentHorizontalPage, currentVerticalPage)
      }
      .overlay(alignment: .top) {
        getAdjacentPage(direction: .vertical, offset: -1)
          .alignmentGuide(.top) { $0[.bottom] }
      }
      .overlay(alignment: .top) {
        VStack {
          if bounce {
            getAdjacentPage(direction: .vertical, offset: -2)
          }
        }.alignmentGuide(.top) { $0.height * 2 }
      }
      .overlay(alignment: .bottom) {
        getAdjacentPage(direction: .vertical, offset: 1)
          .alignmentGuide(.bottom) { $0[.top] }
      }
      .overlay(alignment: .bottom) {
        VStack {
          if bounce {
            getAdjacentPage(direction: .vertical, offset: 2)
          }
        }
        .alignmentGuide(.bottom) { $0.height * -1 }
      }
      .overlay(alignment: .leading) {
        getAdjacentPage(direction: .horizontal, offset: -1)
          .alignmentGuide(.leading) { $0[.trailing] }
      }
      .overlay(alignment: .leading) {
        VStack {
          if bounce {
            getAdjacentPage(direction: .horizontal, offset: -2)
          }
        }
        .alignmentGuide(.leading) { $0.width * 2 }
      }
      .overlay(alignment: .trailing) {
        getAdjacentPage(direction: .horizontal, offset: 1)
          .alignmentGuide(.trailing) { $0[.leading] }
      }
      .overlay(alignment: .trailing) {
        VStack {
          if bounce {
            getAdjacentPage(direction: .horizontal, offset: 2)
          }
        }
        .alignmentGuide(.trailing) { $0.width * -1 }
      }
      .contentShape(Rectangle())
  }

  private func getAdjacentPage(direction: PageViewDirection, offset: Int) -> some View {
    let nextPage: Int?
    let currentPage: Int
    let totalPages: Int?

    switch direction {
    case .horizontal:
      currentPage = currentHorizontalPage
      totalPages = totalHorizontalPage
      nextPage = getNextPage(currentPage, total: totalPages, direction: offset)
    case .vertical:
      currentPage = currentVerticalPage
      totalPages = totalVerticalPage
      nextPage = getNextPage(currentPage, total: totalPages, direction: offset)
    case .none:
      fatalError()
    }

    return Group {
      if let nextPage = nextPage {
        Color.clear
          .overlay(
            direction == .horizontal
              ? getPage(nextPage, currentVerticalPage)
              : getPage(currentHorizontalPage, nextPage)
          )
      }
    }
  }

  private func getNextPage(_ current: Int, total: Int?, direction: Int) -> Int? {
    if let total = total {
      let next = current + direction
      return (0 ..< total).contains(next) ? next : nil
    }
    return current + direction
  }
}
