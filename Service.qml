import QtQuick
import Quickshell
import Quickshell.Io
import "Model.js" as Model

// HyprLogi state, read from `hyprlogi status --json`, and the actions that
// change it. Every action ends in a refresh, so the bar shows what the daemon
// really did rather than what we asked for.
Item {
  id: root

  property var settings: ({})

  property var status: Model.defaultStatus()
  property string actionStatus: ""
  property string lastError: ""

  // Optimistic pause state so the switch throws the instant you click it:
  // -1 follows the daemon, 0/1 while a toggle is catching up.
  property int _desiredPaused: -1
  readonly property bool paused: _desiredPaused === -1 ? status.paused : (_desiredPaused === 1)
  readonly property var view: Object.assign({}, status, { paused: paused })

  readonly property bool usable: status.installed && status.running
  readonly property bool busy: statusProcess.running || actionProcess.running
  readonly property int refreshIntervalSec: intSetting("refreshIntervalSec", 10, 2, 600)

  function setting(name, fallback) {
    var value = settings ? settings[name] : undefined
    return value === undefined || value === null ? fallback : value
  }

  function intSetting(name, fallback, min, max) {
    var n = parseInt(String(setting(name, fallback)), 10)
    if (!isFinite(n)) n = fallback
    return Math.max(min, Math.min(max, n))
  }

  // Exit and end-of-output have no guaranteed order; apply once both arrived.
  property var _statusExit: null
  property var _statusText: null

  function refresh() {
    if (statusProcess.running) return
    _statusExit = null
    _statusText = null
    statusProcess.running = true
  }

  function statusPartArrived() {
    if (_statusExit === null || _statusText === null) return
    applyStatus(_statusText, _statusExit)
  }

  function applyStatus(raw, exitCode) {
    var parsed = Model.parseStatus(raw, exitCode)
    status = parsed
    if (_desiredPaused !== -1 && parsed.paused === (_desiredPaused === 1)) _desiredPaused = -1
    lastError = parsed.ok ? "" : parsed.error
  }

  function run(command, label) {
    if (actionProcess.running || !status.installed) return
    actionStatus = label
    actionProcess.command = command
    actionProcess.running = true
  }

  function togglePaused() {
    if (!status.installed) return
    _desiredPaused = paused ? 0 : 1
    run(["hyprlogi", "toggle"], paused ? "Resuming…" : "Pausing…")
  }

  function setProfile(name) {
    if (!name || name === status.profile) return
    run(["hyprlogi", "profile", "set", name], "Switching to " + Model.profileLabel(name) + "…")
  }

  function testEffects() {
    run(["hyprlogi", "play", "1", "4", "8"], "Playing test effects…")
  }

  function restartService() {
    run(["systemctl", "--user", "restart", "hyprlogi.service"], "Restarting HyprLogi…")
  }

  Timer {
    interval: root.refreshIntervalSec * 1000
    repeat: true
    running: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  // A restarted daemon needs a moment before its socket answers.
  Timer {
    id: settleRefresh
    interval: 1500
    onTriggered: root.refresh()
  }

  Timer {
    id: actionStatusTimer
    interval: 2200
    onTriggered: root.actionStatus = ""
  }

  Process {
    id: statusProcess
    command: ["sh", "-c", "command -v hyprlogi >/dev/null || exit " + Model.EXIT_NOT_INSTALLED + "; exec hyprlogi status --json"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: { root._statusText = String(text || ""); root.statusPartArrived() }
    }
    onExited: function(exitCode) { root._statusExit = exitCode; root.statusPartArrived() }
  }

  Process {
    id: actionProcess
    stdout: StdioCollector { id: actionStdout; waitForEnd: true }
    stderr: StdioCollector { id: actionStderr; waitForEnd: true }
    onExited: function(exitCode) {
      if (exitCode !== 0) {
        root._desiredPaused = -1
        var message = String(actionStderr.text || actionStdout.text || "").trim()
        root.lastError = message.split("\n").pop() || "HyprLogi command failed"
        root.actionStatus = ""
      } else {
        root.lastError = ""
        actionStatusTimer.restart()
      }
      root.refresh()
      settleRefresh.restart()
    }
  }
}
