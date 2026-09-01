import AppKit
import SwiftUI

struct WindowLevelController: NSViewRepresentable {
    let alwaysOnTop: Bool
    let preferredContentSize: NSSize

    func makeNSView(context: Context) -> WindowProbeView {
        let view = WindowProbeView()
        view.alwaysOnTop = alwaysOnTop
        view.preferredContentSize = preferredContentSize
        return view
    }

    func updateNSView(_ nsView: WindowProbeView, context: Context) {
        nsView.alwaysOnTop = alwaysOnTop
        nsView.preferredContentSize = preferredContentSize
        nsView.applyWindowPreferences()
    }
}

final class WindowProbeView: NSView {
    var alwaysOnTop = false
    var preferredContentSize = NSSize(width: 560, height: 350)
    private var lastAppliedContentSize: NSSize?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        applyWindowPreferences()
    }

    func applyWindowPreferences() {
        guard let window else { return }
        window.level = alwaysOnTop ? .floating : .normal
        window.titlebarAppearsTransparent = false
        window.backgroundColor = .windowBackgroundColor
        window.isOpaque = true

        if lastAppliedContentSize != preferredContentSize {
            let contentRect = NSRect(origin: .zero, size: preferredContentSize)
            let newFrameSize = window.frameRect(forContentRect: contentRect).size
            var newFrame = window.frame
            newFrame.origin.y += newFrame.height - newFrameSize.height
            newFrame.size = newFrameSize
            window.setFrame(
                newFrame,
                display: true,
                animate: lastAppliedContentSize != nil
            )
            lastAppliedContentSize = preferredContentSize
        }
    }
}
