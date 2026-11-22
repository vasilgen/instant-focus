import SwiftUI

/// The introduction at the top of Settings.
struct AboutView: View {
    let style: IconStyle
    let listShortcut: String?
    private let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(nsImage: MenuBarIcon.make(style: style, app: nil, side: 36))
                    .overlay(RoundedRectangle(cornerRadius: 9).strokeBorder(.quaternary))
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("InstantFocus").font(.title3.weight(.semibold))
                        if let version { Text(version).font(.caption).foregroundStyle(.tertiary) }
                    }
                    Text("One shortcut per app. Press it to jump straight there.")
                        .foregroundStyle(.secondary)
                }
            }
            VStack(alignment: .leading, spacing: 6) {
                Label("Finds the app on any Space, even in full screen", systemImage: "macwindow.on.rectangle")
                Label("Switches instantly, with no sliding animation", systemImage: "bolt.fill")
                Label("The menu bar shows which app is focused", systemImage: "menubar.rectangle")
                Label("Click it\(listShortcut.map { " or press \($0)" } ?? "") to pick an app from a list",
                      systemImage: "list.bullet")
            }
            .labelStyle(Bullet())
            .font(.callout)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    /// Icon in a fixed-width column so the texts line up.
    private struct Bullet: LabelStyle {
        func makeBody(configuration: Configuration) -> some View {
            HStack(spacing: 8) {
                configuration.icon.frame(width: 18)
                configuration.title
            }
        }
    }
}
