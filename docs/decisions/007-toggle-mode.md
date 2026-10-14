# ADR-007 :: Toggle mode as a hotkey setting

Last updated: `2026.10.14`

> The hotkey can run in two modes: hold to talk (the default) or tap to start and tap to stop. The mode is `hotkey.mode` in `settings.json`, and `--toggle` sets it for one run. The event tap and its rules do not change. Amends [ADR-003](003-push-to-talk-on-a-modifier.md), which had no toggle mode.

## 1. Decision

- **Two modes.** `hold` is the default and behaves as ADR-003 describes. `toggle` starts recording on the first tap and stops and transcribes on the next.
- **The mode lives in `Gesture`.** `Gesture` has a `latched` phase for a toggle recording whose key is up. Nothing else in the loop knows about the mode.
- **The tap stays `flagsChanged`-only and listen-only.** Toggle uses the same edges as hold, so Parrot still never sees a keystroke.
- **The chord rules apply to every tap.** A press with another modifier already down does not record. Another modifier changing during the first tap cancels it. A chord press on a latched recording does not stop it.
- **A second tap within 0.3 s of the first discards the recording.** An accidental double tap says nothing.
- **A key or mode change cancels a recording in progress,** latched or not.
- **The mode is a setting, like the key.** The Settings window has a **Mode** row. `--toggle` overrides it for one foreground run and is not saved.

## 2. Rationale

ADR-003 rejected toggle to keep one interaction that cannot be left recording by accident. This fork wants hands-free dictation for long passages, where holding a key is tiring. The cost ADR-003 named is real, so toggle is off by default and one setting away.

Acting on key-down edges only makes a missed key-up harmless in toggle mode: a latched recording does not wait for one. The tap-recovery resync still sees the key as up, so it emits nothing.

## 3. Design Implications

- Rule: toggle and hold share one `Gesture`; a new mode is a new `HotkeyMode` case, not a branch in the loop.
- `Gesture.isHeld` means the key is physically down. A latched recording is not held.

## 4. When to Revisit

- **Length cap.** A latched recording has no maximum length, so one forgotten recording keeps the microphone open until the next tap. Add a cap, such as stopping after a few minutes, if that happens in practice.
- If upstream adds its own hands-free mode, drop this one.
