// Pure helpers for the HyprLogi bar widget; no QML types, so node can test them.

// Nerd Font (Material Design) glyphs
var GLYPH_MOUSE = "󰍽"
var GLYPH_MOUSE_OFF = "󰍾"
var GLYPH_ALERT = "󰀦"
var GLYPH_CHECK = "󰄬"
var GLYPH_PLAY = "󰐊"
var GLYPH_RESTART = "󰑓"

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
    version: ""
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
  } catch (e) {
    status.ok = false
    status.error = "Could not read HyprLogi status"
  }
  return status
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
    EXIT_NOT_INSTALLED: EXIT_NOT_INSTALLED,
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
