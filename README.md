# CleanLock v2

Lock your keyboard and/or mouse while you clean them.
Hold **F12** for **5 seconds** to unlock everything.

## Run

1. Install AutoHotkey v2.
2. Save `CleanLock.ahk` as **UTF-8** (no BOM is fine, ANSI is not).
3. Double-click it. The window appears.

## Use

1. Pick **Lock KEYBOARD**, **Lock MOUSE**, or **Lock BOTH**.
2. Wait out the 3-second pre-delay. Click **Cancel Pending** to abort.
3. Clean.
4. Hold **F12** for 5 seconds. A blue bar fills under the status text.
5. If you forget, the watchdog unlocks everything on its own (default 120s).

## If it fails to start

The error `Missing ")"` with a full-width `）` in it means the file picked up a
smart character somewhere, usually from copy-paste. Do not retype the script.
Download the file, open it in Notepad, and check that line 234 looks like:

```ahk
SetTimer(DoWatchdog, -sec * 1000)
```

If it contains any full-width bracket, quote, or asterisk, the file is corrupted.
Replace it with the downloaded version.

## Why v1 did not work

| Symptom in v1 ↕▾ | Cause ↕▾ | Fix in v2.1 ↕▾ |
|---|---|---|
| −`^!m` did not unlock the mouse | The M key is inside the `*vkXX` block list. If the keyboard was also locked, `^!m` could never fire | Removed. One universal escape: hold F12 |
| Triple right-click unlock did nothing | Right-click was blocked by the same list, so `~RButton` never got clean presses | Removed |
| `Ctrl+Alt+Del` did not unlock | Windows reserves it. No AHK script can block or hook it | Documented as impossible. Watchdog is the real fallback |
| Script crashed on start | Arrow functions assigned globals and silently created locals, so the watchdog timer never armed | All globals declared explicitly in every function |
⚙

## Known limits

- **Ctrl+Alt+Del** and **Win+L** cannot be blocked. Windows handles them in secure mode.
- **The physical power button** is unaffected.
- **Devices with their own drivers** (some gaming mice and touchpads) may pass input through AHK's hook.
- **Elevated windows** (Task Manager, UAC) do not receive blocked input from a non-elevated script. Run as admin if that matters.

## Customize

Top of `CleanLock.ahk`:

```
HOLD_KEY    := "F12"    ; any key name: "Pause", "CapsLock", "F9"
HOLD_SECS   := 5
PRE_SECS    := 3
DEFAULT_WD  := 120
```

If you change `HOLD_KEY`, the block list automatically skips its VK, so the
hold key keeps working.

## Not a security tool

Anyone can press Ctrl+Alt+Del, open Task Manager, and end the script.
This is a cleaning convenience tool, not access control.

## License

MIT

