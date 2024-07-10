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

#if os(iOS)
  struct DragGestureModifier: ViewModifier {
    var onEnded: (CGPoint) -> Void

    func body(content: Content) -> some View {
      content
        .overlay(DragGestureView(onEnded: onEnded))
    }
  }

  extension View {
    @MainActor
    func onDragEnd(perform: @escaping @MainActor (CGPoint) -> Void) -> some View {
      modifier(DragGestureModifier(onEnded: perform))
    }
  }

  struct DragGestureView: UIViewRepresentable {
    var onEnded: (CGPoint) -> Void

    func makeCoordinator() -> Coordinator {
      return Coordinator(onEnded: onEnded)
    }

    func makeUIView(context: Context) -> UIView {
      let view = UIView()
      let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handlePanGesture(_:)))
      panGesture.delegate = context.coordinator
      view.addGestureRecognizer(panGesture)
      return view
    }

    func updateUIView(_: UIView, context _: Context) {}

    class Coordinator: NSObject, UIGestureRecognizerDelegate {
      var onEnded: (CGPoint) -> Void

      init(onEnded: @escaping (CGPoint) -> Void) {
        self.onEnded = onEnded
      }

      @objc func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .ended, .cancelled:
          onEnded(gesture.translation(in: gesture.view))
        default:
          break
        }
      }

      // 允许其他手势同时进行
      func gestureRecognizer(_: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith _: UIGestureRecognizer) -> Bool {
        return true
      }
    }
  }
#else
  extension View {
    func onDragEnd(perform _: @escaping @MainActor (CGPoint) -> Void) -> some View {
      self
    }
  }
#endif
