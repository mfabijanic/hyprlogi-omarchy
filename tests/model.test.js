// Run with: node --test tests/
const test = require("node:test")
const assert = require("node:assert/strict")
const Model = require("../Model.js")

const RUNNING = JSON.stringify({
  version: "0.3.0", running: true, paused: false, profile: "omarchy",
  profiles: ["default", "omarchy", "my_profile"], backend: "hidpp",
  device: "Logitech MX Master 4 (/dev/hidraw1)"
})

test("parses a running daemon", () => {
  const s = Model.parseStatus(RUNNING, 0)
  assert.equal(s.ok, true)
  assert.equal(s.running, true)
  assert.deepEqual(s.profiles, ["default", "omarchy", "my_profile"])
  assert.equal(Model.barState(s), "ok")
  assert.equal(Model.barGlyph(s), Model.GLYPH_MOUSE)
  assert.equal(Model.heroMeta(s), "Logitech MX Master 4 · Omarchy")
  assert.equal(Model.tooltip(s), "Haptics: Omarchy")
})

test("paused and stopped states", () => {
  const paused = Model.parseStatus(RUNNING.replace('"paused":false', '"paused":true'), 0)
  assert.equal(Model.barState(paused), "paused")
  assert.equal(Model.barGlyph(paused), Model.GLYPH_MOUSE_OFF)
  assert.equal(Model.heroMeta(paused), "Paused")

  const stopped = Model.parseStatus('{"running": false, "paused": false, "profile": "default", "profiles": []}', 0)
  assert.equal(Model.barState(stopped), "problem")
  assert.equal(Model.heroMeta(stopped), "Daemon not running")
})

test("missing hyprlogi and garbage output", () => {
  const missing = Model.parseStatus("", Model.EXIT_NOT_INSTALLED)
  assert.equal(missing.installed, false)
  assert.equal(Model.barState(missing), "problem")
  assert.equal(Model.heroMeta(missing), "hyprlogi is not installed")

  const garbage = Model.parseStatus("Traceback ...", 1)
  assert.equal(garbage.ok, false)
  assert.equal(Model.heroMeta(garbage), "Could not read HyprLogi status")
})

test("labels", () => {
  assert.equal(Model.profileLabel("my_profile"), "My Profile")
  assert.equal(Model.profileLabel("omarchy"), "Omarchy")
  assert.equal(Model.deviceName("MX Master 4 (/dev/hidraw1)"), "MX Master 4")
})
