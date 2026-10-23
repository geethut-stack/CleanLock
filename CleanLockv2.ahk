#Requires AutoHotkey v2.0
#SingleInstance Force
#UseHook

; ============================================================
;  CleanLock v2.1
;
;  Hold F12 for 5 seconds to unlock everything.
;  Works whether keyboard, mouse, or both are locked.
;
;  Fixes vs v2.0:
;   - No arrow functions touching globals (they silently
;     created locals and broke the watchdog / pending timer).
;   - Every global is declared inside each function.
;   - F12 hotkey is only active while something is locked,
;     so F12 behaves normally the rest of the time.
;   - Hold UI value is rounded so Progress never gets a float.
;   - Watchdog auto-cancels when you unlock by hand.
; ============================================================

; ---------------- Config ----------------
HOLD_KEY    := "F12"
HOLD_SECS   := 5
HOLD_MS     := HOLD_SECS * 1000
PRE_SECS    := 3
DEFAULT_WD  := 120

; ---------------- State ----------------
kbLocked      := false
mouseLocked   := false
pendingActive := false
pendingTarget := ""
wdActive      := false
holdRunning   := false
holdArmed     := true
holdStart     := 0
kbHooks       := []
mouseHooks    := []

; ---------------- GUI ----------------
g := Gui("+AlwaysOnTop", "CleanLock v2.1")
g.SetFont("s10")
g.Add("Text",, "Lock devices while cleaning.`nHold " HOLD_KEY " for " HOLD_SECS "s to unlock everything.")

btnKb     := g.Add("Button", "w300 h36", "Lock KEYBOARD")
btnMouse  := g.Add("Button", "w300 h36", "Lock MOUSE")
btnBoth   := g.Add("Button", "w300 h36", "Lock BOTH")
btnCancel := g.Add("Button", "w300 h28 Disabled", "Cancel Pending")

g.Add("Text", "y+12", "Watchdog auto-unlock (sec, 0 = off):")
edW := g.Add("Edit", "w60 Number", String(DEFAULT_WD))

status  := g.Add("Text", "w300 h56 y+10", "")
holdBar := g.Add("Progress", "w300 h12 Range0-100", 0)
holdTxt := g.Add("Text", "w300 cBlue", "")

g.Add("Text", "w300 cGray y+8",
    "Ctrl+Alt+Del, Win+L and the power button cannot be`n"
  . "blocked by any AHK script. The watchdog unlocks`n"
  . "automatically if you forget, or if the GUI closes.")

btnKb.OnEvent("Click",     ToggleKb)
btnMouse.OnEvent("Click",  ToggleMouse)
btnBoth.OnEvent("Click",   ToggleBoth)
btnCancel.OnEvent("Click", CancelPending)
g.OnEvent("Close",         CloseApp)
g.Show()

; ---------------- Keyboard block list ----------------
; Register every VK 0x08..0xFE as a swallowing no-op, except
; the VK that belongs to HOLD_KEY. That keeps F12 available.
skipVK := GetKeyVK(HOLD_KEY)
Loop 0xFE - 0x08 + 1 {
    vk := 0x07 + A_Index
    if (vk = skipVK)
        continue
    name := Format("*vk{:02X}", vk)
    try {
        Hotkey(name, Noop, "Off")
        kbHooks.Push(name)
    }
}

; ---------------- Mouse block list ----------------
mouseHooks := ["$*LButton", "$*RButton", "$*MButton",
               "$*WheelUp", "$*WheelDown", "$*WheelLeft", "$*WheelRight",
               "$*XButton1", "$*XButton2"]
for k in mouseHooks
    try Hotkey(k, Noop, "Off")

; ---------------- Hold-to-unlock hotkeys (registered, off) ----------------
try Hotkey("*" HOLD_KEY, HoldDown, "Off")
try Hotkey("*" HOLD_KEY " Up", HoldUp, "Off")

; ---------------- Exit handling ----------------
OnExit(OnExitHandler)

; ---------------- Initial UI ----------------
UpdateStatus()
UpdateHoldHotkeys()

; ============================================================
;  Functions
; ============================================================

Noop(*) {
}

ToggleKb(*) {
    global kbLocked
    if (kbLocked)
        SetKb(false)
    else
        BeginPending("kb")
}

ToggleMouse(*) {
    global mouseLocked
    if (mouseLocked)
        SetMouse(false)
    else
        BeginPending("mouse")
}

ToggleBoth(*) {
    global kbLocked, mouseLocked
    if (kbLocked && mouseLocked)
        UnlockAll()
    else
        BeginPending("both")
}

BeginPending(target) {
    global pendingActive, pendingTarget, btnCancel, status, PRE_SECS
    if (pendingActive)
        SetTimer(DoPendingLock, 0)
    pendingActive := true
    pendingTarget := target
    btnCancel.Enabled := true
    status.Value := "Locking in " PRE_SECS "s. Click Cancel to abort."
    SetTimer(DoPendingLock, -PRE_SECS * 1000)
}

CancelPending(*) {
    global pendingActive, btnCancel, status
    if (!pendingActive)
        return
    SetTimer(DoPendingLock, 0)
    pendingActive := false
    btnCancel.Enabled := false
    status.Value := "Cancelled."
}

DoPendingLock() {
    global pendingActive, pendingTarget, btnCancel
    pendingActive := false
    btnCancel.Enabled := false
    if (pendingTarget = "kb")
        SetKb(true)
    else if (pendingTarget = "mouse")
        SetMouse(true)
    else if (pendingTarget = "both") {
        SetKb(true)
        SetMouse(true)
    }
    ArmWatchdog()
}

ArmWatchdog() {
    global wdActive, edW
    if (wdActive) {
        SetTimer(DoWatchdog, 0)
        wdActive := false
    }
    sec := 0
    try sec := Integer(Trim(edW.Value))
    if (sec > 0) {
        wdActive := true
        SetTimer(DoWatchdog, -sec * 1000)
    }
}

DoWatchdog() {
    global wdActive
    wdActive := false
    UnlockAll()
}

SetKb(state) {
    global kbLocked, kbHooks
    kbLocked := state
    for k in kbHooks
        try Hotkey(k, state ? "On" : "Off")
    UpdateStatus()
    UpdateHoldHotkeys()
    CheckWatchdogState()
}

SetMouse(state) {
    global mouseLocked, mouseHooks
    mouseLocked := state
    for k in mouseHooks
        try Hotkey(k, state ? "On" : "Off")
    try {
        if (state)
            BlockInput("MouseMove")
        else
            BlockInput("MouseMoveOff")
    }
    UpdateStatus()
    UpdateHoldHotkeys()
    CheckWatchdogState()
}

UnlockAll(*) {
    global pendingActive, btnCancel
    if (pendingActive) {
        SetTimer(DoPendingLock, 0)
        pendingActive := false
        btnCancel.Enabled := false
    }
    SetKb(false)
    SetMouse(false)
    ResetHoldUI()
}

CheckWatchdogState() {
    global kbLocked, mouseLocked, wdActive
    if (!(kbLocked || mouseLocked) && wdActive) {
        SetTimer(DoWatchdog, 0)
        wdActive := false
    }
}

UpdateHoldHotkeys() {
    global kbLocked, mouseLocked, HOLD_KEY
    if (kbLocked || mouseLocked) {
        try Hotkey("*" HOLD_KEY, HoldDown, "On")
        try Hotkey("*" HOLD_KEY " Up", HoldUp, "On")
    } else {
        try Hotkey("*" HOLD_KEY, "Off")
        try Hotkey("*" HOLD_KEY " Up", "Off")
    }
}

HoldDown(*) {
    global kbLocked, mouseLocked, holdRunning, holdArmed, holdStart
    if (!(kbLocked || mouseLocked))
        return
    if (!holdArmed)
        return
    holdArmed := false
    holdRunning := true
    holdStart := A_TickCount
    SetTimer(TickHold, 50)
}

HoldUp(*) {
    global holdRunning, holdArmed
    holdArmed := true
    if (!holdRunning)
        return
    holdRunning := false
    SetTimer(TickHold, 0)
    ResetHoldUI()
}

TickHold() {
    global holdRunning, holdStart, holdBar, holdTxt, HOLD_SECS, HOLD_MS
    if (!holdRunning)
        return
    el := A_TickCount - holdStart
    if (el >= HOLD_MS) {
        holdRunning := false
        SetTimer(TickHold, 0)
        holdBar.Value := 100
        holdTxt.Value := "Unlocking..."
        SetTimer(UnlockAll, -150)
        return
    }
    holdBar.Value := Round(el / HOLD_MS * 100)
    holdTxt.Value := Format("Hold: {:.1f}s / {}s", el / 1000, HOLD_SECS)
}

ResetHoldUI() {
    global holdBar, holdTxt
    holdBar.Value := 0
    holdTxt.Value := ""
}

UpdateStatus() {
    global kbLocked, mouseLocked, status, btnKb, btnMouse, btnBoth
    kt := kbLocked ? "LOCKED" : "free"
    mt := mouseLocked ? "LOCKED" : "free"
    status.Value := Format("Keyboard: {1}`nMouse: {2}", kt, mt)
    btnKb.Text    := kbLocked ? "Unlock Keyboard" : "Lock KEYBOARD"
    btnMouse.Text := mouseLocked ? "Unlock Mouse" : "Lock MOUSE"
    btnBoth.Text  := (kbLocked && mouseLocked) ? "Unlock BOTH" : "Lock BOTH"
}

CloseApp(*) {
    ExitApp()
}

OnExitHandler(*) {
    global kbHooks, mouseHooks
    try SetTimer(DoPendingLock, 0)
    try SetTimer(DoWatchdog, 0)
    try SetTimer(TickHold, 0)
    for k in kbHooks
        try Hotkey(k, "Off")
    for k in mouseHooks
        try Hotkey(k, "Off")
    try BlockInput("MouseMoveOff")
    try BlockInput("Off")
    return 0
}
