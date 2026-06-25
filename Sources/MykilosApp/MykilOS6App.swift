import SwiftUI
import MykilosKit
import MykilosDesign
import MykilosServices
import MykilosWidgets

@main
struct MykilOS6App: App {
    @State private var appState = AppState(database: AppDatabase.production)
    @State private var context  = StudioContext()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .environment(context)
                .task { await appState.bootstrap() }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1340, height: 860)
        .commands { AppCommands() }
    }
}

// MARK: - AppModule
enum AppModule: String, CaseIterable, Identifiable {
    case today      = "Heute"
    case projects   = "Projekte"
    case assistant  = "Assistent"
    case brands     = "Marken & Daten"
    case offers     = "Angebote"
    case settings   = "Einstellungen"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .today:     "sun.min"
        case .projects:  "square.grid.2x2"
        case .assistant: "sparkles"
        case .brands:    "building.2"
        case .offers:    "doc.text"
        case .settings:  "gearshape"
        }
    }
}

// MARK: - ContentView
struct ContentView: View {
    @State private var module: AppModule = .today
    @Environment(AppState.self) private var appState

    var body: some View {
        HStack(spacing: 0) {
            SidebarView(selection: $module)
            Divider().overlay(MykColor.line.color)
            moduleView
        }
        .background(MykColor.paper.color)
    }

    @ViewBuilder
    private var moduleView: some View {
        switch module {
        case .today:     TodayView()
        case .projects:  ProjectGalleryView()
        case .assistant: AssistantPageView()
        case .settings:  SettingsView()
        default:         ComingSoonView(module: module)
        }
    }
}

struct AssistantPageView: View {
    @Environment(StudioContext.self) private var context

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MykSpace.s7) {
                Text("Assistent")
                    .font(.mykDisplay)
                    .foregroundStyle(MykColor.ink.color)
                Text("Der Dolmetscher liest alle Quellen und fasst zusammen, was wichtig ist.")
                    .font(.mykBody)
                    .foregroundStyle(MykColor.muted.color)
                AssistantWidget(projectID: "home")
            }
            .padding(MykSpace.s9)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(MykColor.paper.color)
    }
}

struct ComingSoonView: View {
    let module: AppModule
    var body: some View {
        ZStack {
            MykColor.paper.color.ignoresSafeArea()
            Text("\(module.rawValue) — kommt in einem späteren Akt")
                .font(.mykBody).foregroundStyle(MykColor.muted.color)
        }
    }
}

struct AppCommands: Commands {
    var body: some Commands {
        CommandGroup(replacing: .newItem) {}
    }
}
