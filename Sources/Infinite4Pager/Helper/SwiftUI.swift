//
//  SwiftUI.swift
//  Infinite4Pager
//
//  Created by Yang Xu on 2024/7/9.
//

import SwiftUI

extension View {
  @ViewBuilder
  func clipped(disable: Bool) -> some View {
    if disable {
      self
    } else {
      clipped()
    }
  }

  @ViewBuilder
  func frame(size: CGSize) -> some View {
    frame(width: size.width, height: size.height)
  }
}

public struct CurrentPage: Equatable {
  public let horizontal: Int
  public let vertical: Int
  public init(horizontal: Int, vertical: Int) {
    self.horizontal = horizontal
    self.vertical = vertical
  }
}

public struct CurrentPageKey: EnvironmentKey {
  public static let defaultValue: CurrentPage? = nil
}

public struct Infinite4PagerIsDragging: EnvironmentKey {
  public static let defaultValue = false
}

struct MainPageOffsetInfo: Equatable {
  let mainPagePercent: Double
  let direction: PageViewDirection
}

struct PageOffsetKey: EnvironmentKey {
  static let defaultValue: MainPageOffsetInfo? = .init(mainPagePercent: 0, direction: .none)
}

struct PageTypeKey: EnvironmentKey {
  static let defaultValue: PageType = .current
}

extension EnvironmentValues {
  var mainPageOffsetInfo: MainPageOffsetInfo? {
    get { self[PageOffsetKey.self] }
    set { self[PageOffsetKey.self] = newValue }
  }

  var pageType: PageType {
    get { self[PageTypeKey.self] }
    set { self[PageTypeKey.self] = newValue }
  }
}

extension EnvironmentValues {
  public var pagerCurrentPage: CurrentPage? {
    get { self[CurrentPageKey.self] }
    set { self[CurrentPageKey.self] = newValue }
  }

  public var infinite4PagerIsDragging: Bool {
    get { self[Infinite4PagerIsDragging.self] }
    set { self[Infinite4PagerIsDragging.self] = newValue }
  }
}

struct OnPageVisibleModifier: ViewModifier {
  @Environment(\.mainPageOffsetInfo) var info
  @Environment(\.pageType) var pageType
  let perform: (Double?) -> Void
  func body(content: Content) -> some View {
    content
      .task(id: info) {
        if let info {
          perform(valueTransform(info))
        }
      }
  }

  // 根据 pageType 对可见度进行转换
  func valueTransform(_ info: MainPageOffsetInfo) -> Double? {
    let percent = info.mainPagePercent
    switch (pageType, info.direction) {
    case (.current, _):
      return 1.0 - abs(percent)
    case (.leading, .horizontal), (.top, .vertical):
      if percent > 0 {
        return 1 - (1 - percent)
      } else {
        return 0
      }
    case (.trailing, .horizontal), (.bottom, .vertical):
      if percent < 0 {
        return 1 - (1 + percent)
      } else {
        return 0
      }
    default:
      return nil
    }
  }
}

extension View {
  /// 当前视图的可见尺寸比例
  /// 视图的尺寸为容器尺寸
  @ViewBuilder
  public func onPageVisible(_ perform: @escaping (Double?) -> Void) -> some View {
    modifier(OnPageVisibleModifier(perform: perform))
  }
}
