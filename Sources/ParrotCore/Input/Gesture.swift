import Foundation

/// Turns hotkey edges into dictation actions (ADR-003). Pure, so the rules
/// are tested without an event tap.
///
/// The tap sees modifier changes only, so it cannot see the C in ⌘C. Two
/// rules keep a shortcut typed on the hotkey from producing text:
/// - A hold shorter than `minimumHold` is discarded without transcribing.
/// - A recording is cancelled if another modifier changes while the hotkey
///   is held, and a press while another modifier is already held does not
///   record. Either way the rest of that hold is ignored.
///
/// Recording still starts on key-down, so press latency is unchanged; a
/// discarded hold just throws its audio away.
///
/// In `HotkeyMode.toggle` the first tap starts recording and lets go of the
/// key; the next tap stops and transcribes. The chord rules still apply to
/// each tap. A second tap within `minimumHold` of the first discards the
/// recording, so a double-tap by accident says nothing.
public struct Gesture {
    /// Holds shorter than this are taps or shortcuts, not dictation.
    public static let minimumHold: TimeInterval = 0.3

    public enum Input: Equatable {
        /// The hotkey went down. `othersHeld`: another modifier was already
        /// down, so this is a chord.
        case hotkeyDown(othersHeld: Bool)
        /// The hotkey went up.
        case hotkeyUp
        /// Another modifier changed while the hotkey was down.
        case otherModifier
    }

    public enum Action: Equatable {
        /// Start recording.
        case start
        /// Stop recording and transcribe.
        case transcribe
        /// Stop recording and discard it.
        case cancel
    }

    private enum Phase: Equatable {
        case idle
        /// Recording since this time, the hotkey still down.
        case recording(since: TimeInterval)
        /// Toggle mode: recording since this time, the hotkey released. The
        /// next tap stops it.
        case latched(since: TimeInterval)
        /// The hotkey is down but this hold is a chord: ignore it until release.
        case ignoring
    }

    private var phase: Phase = .idle
    private var held = false

    /// How taps map to recording. Change it with `reset()` first, so a
    /// recording never changes mode halfway.
    public var mode: HotkeyMode

    public init(mode: HotkeyMode = .hold) {
        self.mode = mode
    }

    /// Whether the hotkey is down, as far as the edges seen so far say. In
    /// toggle mode a latched recording is not held: the key is up.
    public var isHeld: Bool { held }

    /// Feed one edge at `time` (seconds on a monotonic clock).
    public mutating func handle(_ input: Input, at time: TimeInterval) -> Action? {
        switch input {
        case .hotkeyDown: held = true
        case .hotkeyUp: held = false
        case .otherModifier: break
        }
        switch (phase, input) {
        case (.idle, .hotkeyDown(let othersHeld)):
            if othersHeld {
                phase = .ignoring
                return nil
            }
            phase = .recording(since: time)
            return .start
        case (.recording(let since), .hotkeyUp):
            if mode == .toggle {
                phase = .latched(since: since)
                return nil
            }
            phase = .idle
            return time - since < Self.minimumHold ? .cancel : .transcribe
        case (.recording, .otherModifier):
            phase = .ignoring
            return .cancel
        case (.latched(let since), .hotkeyDown(let othersHeld)):
            // A chord on the hotkey is not the tap that stops dictation.
            if othersHeld { return nil }
            phase = .ignoring
            return time - since < Self.minimumHold ? .cancel : .transcribe
        case (.ignoring, .hotkeyUp):
            phase = .idle
            return nil
        default:
            // A repeated down, an up with no down seen, or a modifier change
            // outside a recording.
            return nil
        }
    }

    /// Forget the current hold, for a switch to another key or mode. A
    /// recording in progress is cancelled.
    public mutating func reset() -> Action? {
        defer {
            phase = .idle
            held = false
        }
        switch phase {
        case .recording, .latched: return .cancel
        case .idle, .ignoring: return nil
        }
    }
}
