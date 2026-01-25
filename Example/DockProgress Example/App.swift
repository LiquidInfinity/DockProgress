import SwiftUI
import DockProgress

@MainActor
@main
struct AppMain: App {
	@State private var appState = AppState()

	var body: some Scene {
		WindowGroup {
			ContentView(appState: appState)
		}
	}
}

struct ContentView: View {
	var appState: AppState
	@State private var useModifier = false
	@State private var progress = 0.0
	@State private var selectedStyle = StyleOption.bar
	@State private var progressTask: Task<Void, Never>?

	enum StyleOption: String, CaseIterable {
		case bar = "Bar"
		case squircle = "Squircle"
		case circle = "Circle"
		case badge = "Badge"
		case pie = "Pie"

		var dockStyle: DockProgress.Style {
			switch self {
			case .bar:
				.bar
			case .squircle:
				.squircle(color: .blue)
			case .circle:
				.circle(radius: 30, color: .white)
			case .badge:
				.badge(color: .blue) { Int(DockProgress.displayedProgress * 10) }
			case .pie:
				.pie(color: .blue)
			}
		}
	}

	var body: some View {
		VStack(spacing: 20) {
			Picker("Mode", selection: $useModifier) {
				Text("Classic").tag(false)
				Text(".dockProgress").tag(true)
			}
			.pickerStyle(.segmented)
			if useModifier {
				Picker("Style", selection: $selectedStyle) {
					ForEach(StyleOption.allCases, id: \.self) { style in
						Text(style.rawValue).tag(style)
					}
				}
				.pickerStyle(.segmented)
			}
		}
		.padding(40)
		.frame(width: 400)
		.onChange(of: useModifier) { newValue in
			if newValue {
				appState.stop()
				progress = 0
				startProgressTask()
			} else {
				progressTask?.cancel()
				progressTask = nil
				appState.start()
			}
		}
		.onAppear {
			appState.setUp()
			appState.start()
		}
		.modifier(ConditionalDockProgress(
			isEnabled: useModifier,
			progress: progress,
			style: selectedStyle.dockStyle
		))
	}

	private func startProgressTask() {
		progressTask = Task {
			while !Task.isCancelled {
				try? await Task.sleep(for: .seconds(0.5))
				progress += 0.1
				if progress > 1 {
					// Skip 0 to avoid clearing the dock icon between cycles.
					progress = 0.1
				}
			}
		}
	}
}

struct ConditionalDockProgress: ViewModifier {
	let isEnabled: Bool
	let progress: Double
	let style: DockProgress.Style

	func body(content: Content) -> some View {
		if isEnabled {
			content.dockProgress(progress, style: style)
		} else {
			content
		}
	}
}
