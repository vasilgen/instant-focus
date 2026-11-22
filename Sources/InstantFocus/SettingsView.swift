import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: Store

    var body: some View {
        Form {
            Section {
                AboutView(style: store.iconStyle,
                          listShortcut: store.menuKeyCode.map { KeyNames.describe($0, store.menuModifiers) })
            }

            if !store.tapsReady {
                Section {
                    Label("Allow InstantFocus under Accessibility so your shortcuts work.",
                          systemImage: "exclamationmark.triangle.fill")
                    Button("Open Accessibility Settings") { Permissions.openSettings() }
                }
            }

            Section {
                ForEach(store.shortcuts) { item in
                    HStack {
                        VStack(spacing: 0) {
                            Button { store.move(item.id, by: -1) } label: { Image(systemName: "chevron.up") }
                                .disabled(item.id == store.shortcuts.first?.id)
                            Button { store.move(item.id, by: 1) } label: { Image(systemName: "chevron.down") }
                                .disabled(item.id == store.shortcuts.last?.id)
                        }
                        .buttonStyle(.borderless)
                        .font(.caption2.weight(.semibold))
                        .help("Move \(item.name) up or down")
                        Image(nsImage: NSWorkspace.shared.icon(forFile: item.path))
                            .resizable()
                            .frame(width: 20, height: 20)
                        Text(item.name)
                        Spacer()
                        ShortcutRecorder(keyCode: item.keyCode, modifiers: item.modifiers) {
                            store.setShortcut(item.id, keyCode: $0, modifiers: $1)
                        }
                        Button { store.remove(item.id) } label: {
                            Image(systemName: "minus.circle.fill")
                        }
                        .buttonStyle(.borderless)
                        .foregroundStyle(.secondary)
                        .help("Remove \(item.name)")
                    }
                }
                Button("Add App…") { store.addApps() }
            } header: {
                Text("Apps")
            } footer: {
                Text("The app list shows them in this order.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                LabeledContent("Show app list") {
                    ShortcutRecorder(keyCode: store.menuKeyCode, modifiers: store.menuModifiers) {
                        store.setShortcut(nil, keyCode: $0, modifiers: $1)
                    }
                }
                Picker("Menu bar icon", selection: $store.iconStyle) {
                    ForEach(IconStyle.allCases) { Text($0.title).tag($0) }
                }
                Toggle("Launch at login", isOn: $store.launchAtLogin)
            }
        }
        .formStyle(.grouped)
        .frame(width: 460, height: 600)
    }
}
