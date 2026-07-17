//
//  AddSmartFeedWindowController.swift
//  NetNewsWire
//
//  Hosts the shared SwiftUI smart-feed editor in a sheet on Mac.
//

import AppKit
import SwiftUI

@MainActor final class AddSmartFeedWindowController: NSWindowController {

	private var hostWindow: NSWindow?

	convenience init(userSmartFeed: UserSmartFeed? = nil) {
		let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 460, height: 400),
							  styleMask: [.titled],
							  backing: .buffered,
							  defer: false)
		self.init(window: window)

		let editorView = SmartFeedEditorView(userSmartFeed: userSmartFeed) { [weak self] in
			self?.endSheet()
		}
		window.contentViewController = NSHostingController(rootView: editorView)
	}

	func runSheetOnWindow(_ hostWindow: NSWindow) {
		guard let window else {
			return
		}
		self.hostWindow = hostWindow
		Task { @MainActor in
			await hostWindow.beginSheet(window)
		}
	}

	private func endSheet() {
		guard let hostWindow, let window else {
			return
		}
		hostWindow.endSheet(window)
		self.hostWindow = nil
	}
}
