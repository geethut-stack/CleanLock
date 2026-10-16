# CleanLock

A small AutoHotkey v2 tool with a GUI that locks your **keyboard** and **mouse** independently, so you can wipe them down while your PC stays on.

Because you can lock one device and keep the other free, each device can unlock the other with a macro.

## Features

- Separate lock buttons for keyboard and mouse
- 3-second delay after clicking, so you can get your hands ready
- Cross-device unlock macros (no need to touch the locked device)
- Safety auto-unlock timer (default 120 seconds, set to 0 to disable)
- Live status display and button labels
- Closing the window always releases both locks

## Requirements

- Windows
- [AutoHotkey v2](https://www.autohotkey.com/)
- Running as administrator is recommended for best results

## Usage

1. Install AutoHotkey v2.
2. Download `cleanlock.ahk` and double-click it (or right-click and choose *Run as administrator*).
3. Click **Lock KEYBOARD** or **Lock MOUSE**. Locking starts after 3 seconds.
4. Clean your device, then unlock using the macros below.

## Unlock macros

| Locked device | How to unlock | Notes |
|---------------|---------------|-------|
| Keyboard | Triple right-click (within ~1.2 s), or click the GUI button | Mouse must be unlocked |
| Mouse | `Ctrl + Alt + M` | Keyboard must be unlocked |
| Both | Wait for the safety timer, or press `Ctrl + Alt + Del` | Emergency exit |

> **Tip:** Avoid locking both at once. If you do, the safety auto-unlock timer is your way out, so leave it enabled.

## Limitations

- `Ctrl + Alt + Del` and `Win + L` cannot be blocked by any script.
- Some touchpads and gaming mice with their own drivers may not be fully blocked.
- Physical power buttons and laptop lid switches are not affected.
- Windows may restrict input hooks in some elevated apps unless CleanLock runs as administrator.

## Cleaning safety

Dampen your cloth rather than spraying liquid directly onto keys or the screen.

## Troubleshooting

- **Script won't start:** Make sure it opens with AutoHotkey **v2**, not v1.
- **Syntax or "Missing quote" errors:** Save the file as UTF-8 and make sure it uses straight quotes (`"`), not curly ones.
- **Lock doesn't seem to work:** Run as administrator.

## License

MIT
