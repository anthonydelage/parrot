import SwiftUI
import ParrotCore

/// The push-to-talk key (#42) and whether it is held or tapped, two rows in
/// the General section.
struct HotkeyRow: View {
    @ObservedObject var store: SettingsStore

    var body: some View {
        keyRow
        modeRow
    }

    private var keyRow: some View {
        PillRow("Hotkey") {
            PillMenu(title: store.current.hotkey.key.displayName) {
                ForEach(HotkeyKey.allCases, id: \.self) { key in
                    Toggle(key.displayName, isOn: Binding(
                        get: { store.current.hotkey.key == key },
                        set: { on in if on { store.update { $0.hotkey.key = key } } }
                    ))
                }
            }
        }
    }

    private var modeRow: some View {
        PillRow("Mode") {
            PillMenu(title: store.current.hotkey.mode.displayName) {
                ForEach(HotkeyMode.allCases, id: \.self) { mode in
                    Toggle(mode.displayName, isOn: Binding(
                        get: { store.current.hotkey.mode == mode },
                        set: { on in if on { store.update { $0.hotkey.mode = mode } } }
                    ))
                }
            }
        }
    }
}
