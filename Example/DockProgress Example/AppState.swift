import SwiftUI
import DockProgress

@MainActor
final class AppState {
	private(set) var isRunning = false
	private var timer: Timer?

	private let styles: [DockProgress.Style] = [
		.bar,
		.squircle(color: .gray),
		.circle(radius: 30, color: .white),
		.badge(color: .blue) { Int(DockProgress.displayedProgress * 12) },
		.pie(color: .blue),
		.customView { progress in
			CustomView(progress: progress)
		}
	]

	private var stylesIterator: IndexingIterator<[DockProgress.Style]>?

	init() {
		stylesIterator = styles.makeIterator()
	}

	func setUp() {
		borrowIconFromApp("com.apple.Photos")
	}

	func start() {
		guard !isRunning else {
			return
		}

		isRunning = true
		advanceToNextStyle()

		timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
			Task { @MainActor [weak self] in
				guard let self, isRunning else {
					return
				}

				if DockProgress.displayedProgress >= 1 {
					advanceToNextStyle()
				}

				DockProgress.progress = min(DockProgress.progress + 0.2, 1)
			}
		}
	}

	func stop() {
		isRunning = false
		timer?.invalidate()
		timer = nil
		DockProgress.resetProgress()
	}

	private func advanceToNextStyle() {
		if let style = stylesIterator?.next() {
			DockProgress.resetProgress()
			DockProgress.style = style
			return
		}

		stylesIterator = styles.makeIterator()

		if let style = stylesIterator?.next() {
			DockProgress.resetProgress()
			DockProgress.style = style
		}
	}

	private func borrowIconFromApp(_ app: String) {
		guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: app) else {
			return
		}

		let icon = NSWorkspace.shared.icon(forFile: appURL.path)
		icon.size = CGSize(width: 128, height: 128)

		if NSApp.applicationIconImage != icon {
			NSApp.applicationIconImage = icon
		}
	}
}

private struct CustomView: View {
	let progress: Double

	var body: some View {
		ZStack {
			Circle()
				.stroke(
					LinearGradient(
						colors: [.blue, .purple],
						startPoint: .top,
						endPoint: .bottom
					),
					lineWidth: 8
				)
				.opacity(0.3)
				.frame(width: 80, height: 80)
			Circle()
				.trim(from: 0, to: progress)
				.stroke(
					LinearGradient(
						colors: [.blue, .purple],
						startPoint: .top,
						endPoint: .bottom
					),
					style: StrokeStyle(lineWidth: 8, lineCap: .round)
				)
				.rotationEffect(.degrees(-90))
				.frame(width: 80, height: 80)
			Text("\(Int(progress * 100))%")
				.font(.system(size: 20, weight: .bold).monospacedDigit())
				.foregroundColor(.white)
		}
	}
}
