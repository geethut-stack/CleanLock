#Requires AutoHotkey v2.0
#SingleInstance Force
; Run as administrator for best results

kbLocked := false
mouseLocked := false
clickTimes := []

; ---------- GUI ----------
g := Gui("+AlwaysOnTop", "CleanLock")
g.SetFont("s10")
g.Add("Text",, "Lock for cleaning (3 sec delay after pressing):")
btnKb := g.Add("Button", "w220 h35", "Lock KEYBOARD")
btnMouse := g.Add("Button", "w220 h35", "Lock MOUSE")
g.Add("Text", "y+15", "Safety auto-unlock after (sec, 0 = off):")
edSafety := g.Add("Edit", "w60 Number", "120")
status := g.Add("Text", "w260 h45 y+15", "")
helpText := "Unlock macros:`nKeyboard: triple right-click (mouse must be unlocked)`nMouse: Ctrl+Alt+M (keyboard must be unlocked)`nEmergency: Ctrl+Alt+Del"
g.Add("Text", "w260 y+10 cGray", helpText)
btnKb.OnEvent("Click", (*) => ToggleKb(true))
btnMouse.OnEvent("Click", (*) => ToggleMouse(true))
g.OnEvent("Close", (*) => (SetKb(false), SetMouse(false), ExitApp()))
g.Show()
UpdateStatus()

; ---------- Keyboard blocking ----------
kbKeys := []
Loop 247 {
    vk := A_Index + 7
    key := "$*vk" Format("{:02X}", vk)
    try {
        Hotkey key, (*) => "", "Off"
        kbKeys.Push(key)
    }
}

; ---------- Mouse click blocking ----------
mouseKeys := ["$*LButton", "$*RButton", "$*MButton", "$*XButton1", "$*XButton2", "$*WheelUp", "$*WheelDown", "$*WheelLeft", "$*WheelRight"]
for k in mouseKeys
    Hotkey k, (*) => "", "Off"

; ---------- Unlock macros ----------
^!m:: SetMouse(false)                   ; Ctrl+Alt+M unlocks mouse

~RButton:: {                            ; triple right-click unlocks keyboard
    global clickTimes
    clickTimes.Push(A_TickCount)
    if clickTimes.Length > 3
        clickTimes.RemoveAt(1)
    if clickTimes.Length = 3 && (clickTimes[3] - clickTimes[1] < 1200) && kbLocked {
        clickTimes := []
        SetKb(false)
    }
}

; ---------- Functions ----------
ToggleKb(delay := false) {
    if kbLocked {
        SetKb(false)
        return
    }
    StartLock(delay, () => SetKb(true))
}

ToggleMouse(delay := false) {
    if mouseLocked {
        SetMouse(false)
        return
    }
    StartLock(delay, () => SetMouse(true))
}

StartLock(delay, fn) {
    if delay {
        status.Value := "Locking in 3 seconds..."
        SetTimer () => (fn(), ArmSafety()), -3000
    } else {
        fn()
        ArmSafety()
    }
}

ArmSafety() {
    secs := edSafety.Value = "" ? 0 : Integer(edSafety.Value)
    if secs > 0
        SetTimer SafetyUnlock, -secs * 1000
}

SafetyUnlock() {
    SetKb(false)
    SetMouse(false)
}

SetKb(state) {
    global kbLocked := state
    for key in kbKeys
        Hotkey key, state ? "On" : "Off"
    UpdateStatus()
}

SetMouse(state) {
    global mouseLocked := state
    for k in mouseKeys
        Hotkey k, state ? "On" : "Off"
    BlockInput state ? "MouseMove" : "MouseMoveOff"
    UpdateStatus()
}

UpdateStatus() {
    kbText := kbLocked ? "LOCKED" : "free"
    msText := mouseLocked ? "LOCKED" : "free"
    status.Value := Format("Keyboard: {1}`nMouse: {2}", kbText, msText)
    btnKb.Text := kbLocked ? "UNLOCK Keyboard" : "Lock KEYBOARD"
    btnMouse.Text := mouseLocked ? "UNLOCK Mouse" : "Lock MOUSE"
}