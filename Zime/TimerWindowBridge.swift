import SwiftUI
import AppKit

@MainActor
final class TimerWindowReference {
    weak var window: NSWindow?

    var settingsArrowEdge: Edge {
        guard let window, let screen = window.screen else { return .leading }
        return Self.settingsArrowEdge(windowFrame: window.frame, visibleFrame: screen.visibleFrame)
    }

    static func settingsArrowEdge(windowFrame: CGRect, visibleFrame: CGRect) -> Edge {
        let neededWidth: CGFloat = 304 + 16
        let rightSpace = visibleFrame.maxX - windowFrame.maxX
        let leftSpace = windowFrame.minX - visibleFrame.minX
        if rightSpace >= neededWidth { return .leading }
        if leftSpace >= neededWidth { return .trailing }
        // Prefer the roomier side; AppKit then keeps the popover on screen.
        return rightSpace >= leftSpace ? .leading : .trailing
    }
}

/// Keeps operations scoped to the timer window, even while Settings has focus.
struct TimerWindowBridge: NSViewRepresentable {
    let settings: TimerSettings
    var windowReference: TimerWindowReference? = nil

    func makeNSView(context: Context) -> WindowHostView {
        let view = WindowHostView()
        view.settings = settings
        view.windowReference = windowReference
        return view
    }

    func updateNSView(_ view: WindowHostView, context: Context) {
        view.settings = settings
        view.windowReference = windowReference
        windowReference?.window = view.window
        view.apply(request: settings.resizeRequest, floating: settings.alwaysOnTop)
    }

    final class WindowHostView: NSView {
        var settings: TimerSettings?
        var windowReference: TimerWindowReference?
        private var lastRequest: Int?
        private var isApplyingSize = false

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            NotificationCenter.default.removeObserver(self, name: NSWindow.didResizeNotification, object: nil)
            windowReference?.window = window
            guard let settings, window != nil else { return }
            NotificationCenter.default.addObserver(self, selector: #selector(windowDidResize(_:)),
                                                   name: NSWindow.didResizeNotification, object: window)
            window?.title = "Zime"
            window?.titleVisibility = .visible
            window?.backgroundColor = NSColor(ZimeStyle.canvas)
            apply(request: settings.resizeRequest, floating: settings.alwaysOnTop)
        }

        func apply(request: Int, floating: Bool) {
            guard let window, let settings else { return }
            window.level = floating ? .floating : .normal
            // Floating windows default to .transient, which hides them in
            // Mission Control. Opt in explicitly without changing their Space.
            var behavior = window.collectionBehavior
            behavior.subtract([.transient, .stationary])
            behavior.insert(.managed)
            window.collectionBehavior = behavior
            guard lastRequest != request else { return }
            lastRequest = request
            isApplyingSize = true
            defer { isApplyingSize = false }
            let available = window.screen?.visibleFrame.size ?? CGSize(width: 1200, height: 900)
            let width = min(settings.windowWidth, available.width)
            let height = min(settings.windowHeight, max(220, available.height - 36))
            let oldTop = window.frame.maxY
            window.setContentSize(CGSize(width: width, height: height))
            var frame = window.frame
            frame.origin.y = oldTop - frame.height
            if let screen = window.screen?.visibleFrame {
                frame.origin.x = max(screen.minX, min(frame.origin.x, screen.maxX - frame.width))
                frame.origin.y = max(screen.minY, min(frame.origin.y, screen.maxY - frame.height))
            }
            window.setFrame(frame, display: true, animate: false)
        }

        @objc private func windowDidResize(_ notification: Notification) {
            guard !isApplyingSize, let window, let settings,
                  notification.object as? NSWindow === window else { return }
            let size = window.contentRect(forFrameRect: window.frame).size
            let width = size.width.rounded()
            let height = size.height.rounded()
            if settings.windowWidth != width { settings.windowWidth = width }
            if settings.windowHeight != height { settings.windowHeight = height }
        }
    }
}
