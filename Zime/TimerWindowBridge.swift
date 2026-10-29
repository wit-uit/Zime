import SwiftUI
import AppKit

/// Keeps operations scoped to the timer window, even while Settings has focus.
struct TimerWindowBridge: NSViewRepresentable {
    let settings: TimerSettings

    func makeNSView(context: Context) -> WindowHostView {
        let view = WindowHostView()
        view.settings = settings
        return view
    }

    func updateNSView(_ view: WindowHostView, context: Context) {
        view.settings = settings
        view.apply(request: settings.resizeRequest, floating: settings.alwaysOnTop)
    }

    final class WindowHostView: NSView {
        var settings: TimerSettings?
        private var lastRequest: Int?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            guard let settings, window != nil else { return }
            window?.title = "Zime"
            window?.titleVisibility = .visible
            window?.backgroundColor = NSColor(ZimeStyle.canvas)
            apply(request: settings.resizeRequest, floating: settings.alwaysOnTop)
        }

        func apply(request: Int, floating: Bool) {
            guard let window, let settings else { return }
            window.level = floating ? .floating : .normal
            guard lastRequest != request else { return }
            lastRequest = request
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
    }
}
