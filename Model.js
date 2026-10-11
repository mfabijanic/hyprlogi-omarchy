// Pure helpers for the HyprLogi bar widget; no QML types, so node can test them.

// Nerd Font (Material Design) glyphs
var GLYPH_MOUSE = "󰍽"
var GLYPH_MOUSE_OFF = "󰍾"
var GLYPH_ALERT = "󰀦"
var GLYPH_CHECK = "󰄬"
var GLYPH_PLAY = "󰐊"
var GLYPH_RESTART = "󰑓"
var GLYPH_EDIT = "󰏫"

// Exit code of `sh -c 'command -v hyprlogi || exit 127; …'` when hyprlogi is missing
var EXIT_NOT_INSTALLED = 127

function defaultStatus() {
  return {
    ok: true,
    installed: true,
    running: false,
    paused: false,
    profile: "",
    profiles: [],
    backend: "",
    device: "",
    version: "",
    gui: false
  }
}

// Parses `hyprlogi status --json` output.
function parseStatus(raw, exitCode) {
  var status = defaultStatus()
  if (exitCode === EXIT_NOT_INSTALLED) {
    status.installed = false
    return status
  }
  var text = String(raw || "").trim()
  try {
    var parsed = JSON.parse(text)
    if (!parsed || typeof parsed !== "object") throw new Error("not an object")
    status.running = parsed.running === true
    status.paused = parsed.paused === true
    status.profile = String(parsed.profile || "")
    status.profiles = Array.isArray(parsed.profiles) ? parsed.profiles.map(String) : []
    status.backend = String(parsed.backend || "")
    status.device = String(parsed.device || "")
    status.version = String(parsed.version || "")
    // HyprLogi 0.4.1+ reports whether its profile editor can start
    status.gui = parsed.gui === true
  } catch (e) {
    status.ok = false
    status.error = "Could not read HyprLogi status"
  }
  return status
}

// The first HyprLogi whose profile editor bounds pasted text (see editorAvailable)
var EDITOR_MIN_VERSION = "0.4.2"

// "0.4.10" >= "0.4.2": compares numeric parts; a missing or odd version is never new enough
function versionAtLeast(version, minimum) {
  var a = String(version || "").split(".")
  var b = String(minimum).split(".")
  for (var i = 0; i < b.length; i++) {
    var x = parseInt(a[i], 10)
    var y = parseInt(b[i], 10)
    if (!isFinite(x)) return false
    if (x !== y) return x > y
  }
  return true
}

// The panel offers the profile editor only when HyprLogi says it can start, and only from the
// version that caps clipboard pastes into its fields.
function editorAvailable(status) {
  return status.installed && status.gui === true && versionAtLeast(status.version, EDITOR_MIN_VERSION)
}

// "omarchy" -> "Omarchy", "my_profile" -> "My Profile"
function profileLabel(name) {
  return String(name || "").split(/[-_ ]+/).filter(function(part) { return part }).map(function(part) {
    return part.charAt(0).toUpperCase() + part.slice(1)
  }).join(" ")
}

// "Logitech MX Master 4 (/dev/hidraw1)" -> "MX Master 4": the panel subtitle is short
function deviceName(device) {
  return String(device || "").replace(/\s*\([^)]*\)\s*$/, "").replace(/^Logitech\s+/i, "")
}

function barGlyph(status) {
  if (!status.installed || !status.running) return GLYPH_ALERT
  return status.paused ? GLYPH_MOUSE_OFF : GLYPH_MOUSE
}

// "ok" | "paused" | "problem": the bar paints problem urgent and paused dim.
function barState(status) {
  if (!status.installed || !status.running) return "problem"
  return status.paused ? "paused" : "ok"
}

// One line under the panel title.
function heroMeta(status) {
  if (!status.installed) return "hyprlogi is not installed"
  if (!status.ok) return status.error || "Could not read HyprLogi status"
  if (!status.running) return "Daemon not running"
  if (status.paused) return "Paused"
  var device = deviceName(status.device)
  return device ? device + " · " + profileLabel(status.profile) : profileLabel(status.profile)
}

function tooltip(status) {
  if (barState(status) === "ok") return "Haptics: " + profileLabel(status.profile)
  return "Haptics: " + heroMeta(status)
}

if (typeof module !== "undefined") {
  module.exports = {
    GLYPH_MOUSE: GLYPH_MOUSE,
    GLYPH_MOUSE_OFF: GLYPH_MOUSE_OFF,
    GLYPH_ALERT: GLYPH_ALERT,
    GLYPH_EDIT: GLYPH_EDIT,
    EXIT_NOT_INSTALLED: EXIT_NOT_INSTALLED,
    EDITOR_MIN_VERSION: EDITOR_MIN_VERSION,
    versionAtLeast: versionAtLeast,
    editorAvailable: editorAvailable,
    defaultStatus: defaultStatus,
    parseStatus: parseStatus,
    profileLabel: profileLabel,
    deviceName: deviceName,
    barGlyph: barGlyph,
    barState: barState,
    heroMeta: heroMeta,
    tooltip: tooltip
  }
}
