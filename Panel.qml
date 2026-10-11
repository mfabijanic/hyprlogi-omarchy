import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Ui
import "Model.js" as Model

// HyprLogi bar widget: a mouse icon showing whether haptics run, and a panel
// to pause them, switch profiles and test effects. Everything goes through the
// `hyprlogi` CLI (see Service.qml).
Panel {
  id: root
  moduleName: "mfabijanic.hyprlogi"
  ipcTarget: "mfabijanic.hyprlogi"

  // Keyboard cursor over one flat list: the switch, each profile, then the actions.
  property int cursorIndex: 0
  property bool cursorActive: false
  readonly property var profiles: haptics.status.profiles
  readonly property int profileBase: 1
  readonly property int actionBase: profileBase + profiles.length
  readonly property var actions: [
    { glyph: Model.GLYPH_PLAY, label: "Test effects", detail: "Play effects 1, 4 and 8" },
    { glyph: Model.GLYPH_RESTART, label: "Restart service", detail: "systemctl --user restart hyprlogi" }
  ]
  readonly property int cursorCount: actionBase + actions.length

  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color urgent: bar ? bar.urgent : Color.urgent
  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property string barState: Model.barState(haptics.view)

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onOpenedChanged: if (opened) {
    cursorActive = false
    haptics.refresh()
    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }

  function moveCursor(dy) {
    cursorIndex = Math.max(0, Math.min(cursorCount - 1, cursorIndex + dy))
  }

  function activateCursor() {
    if (cursorIndex === 0) haptics.togglePaused()
    else if (cursorIndex < actionBase) haptics.setProfile(profiles[cursorIndex - profileBase])
    else activateAction(cursorIndex - actionBase)
  }

  function activateAction(index) {
    if (index === 0) haptics.testEffects()
    else haptics.restartService()
  }

  function hover(index) {
    cursorActive = true
    cursorIndex = index
  }

  Service {
    id: haptics
    settings: root.settings
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: Model.barGlyph(haptics.view)
    dimmed: root.barState === "paused"
    active: root.barState === "problem"
    tooltipText: Model.tooltip(haptics.view)
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.MiddleButton) haptics.togglePaused()
      else if (buttonCode === Qt.RightButton) haptics.refresh()
      else root.toggle()
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(340))
    contentHeight: panel.fittedContentHeight(column.implicitHeight, Style.space(520))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onMoveRequested: function(dx, dy) {
        if (!root.cursorActive) { root.cursorActive = true; return }
        root.moveCursor(dy)
      }
      onActivateRequested: if (root.cursorActive) root.activateCursor()
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onTextKey: function(t) {
        if (t === "p" || t === "P") haptics.togglePaused()
        else if (t === "t" || t === "T") haptics.testEffects()
        else if (t === "r" || t === "R") haptics.refresh()
      }

      Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: column.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        Column {
          id: column
          width: parent.width
          spacing: Style.space(12)

          Item {
            id: header
            width: parent.width
            implicitHeight: hero.implicitHeight
            readonly property bool ringVisible: root.cursorActive && root.cursorIndex === 0

            PanelHero {
              id: hero
              width: parent.width
              title: "Haptics"
              meta: Model.heroMeta(haptics.view)
              foreground: root.foreground
              fontFamily: root.fontFamily
              iconOpacity: root.barState === "ok" ? 1.0 : 0.5
              iconComponent: Component {
                Text {
                  text: Model.barGlyph(haptics.view)
                  color: root.barState === "problem" ? root.urgent : root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.display
                }
              }
              // On = haptics play; the service flips it optimistically.
              trailingControl: Component {
                ToggleSwitch {
                  id: hapticsSwitch
                  visible: haptics.status.installed
                  checked: !haptics.paused
                  busy: haptics.busy
                  hasCursor: header.ringVisible
                  foreground: hero.foreground
                  onHovered: function(on) { if (on) root.hover(0) }
                  onToggled: haptics.togglePaused()

                  PanelToolTip {
                    visible: hapticsSwitch.containsMouse
                    text: haptics.paused ? "Resume haptics (P)" : "Pause haptics (P)"
                    fontFamily: hero.fontFamily
                  }
                }
              }
            }
          }

          Text {
            textFormat: Text.PlainText
            visible: haptics.actionStatus !== "" || haptics.lastError !== ""
            width: parent.width
            text: haptics.lastError !== "" ? haptics.lastError : haptics.actionStatus
            color: haptics.lastError !== "" ? root.urgent : root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
            wrapMode: Text.WordWrap
          }

          Text {
            textFormat: Text.PlainText
            visible: !haptics.status.installed
            width: parent.width
            text: "Install HyprLogi 0.3.0 or newer from github.com/mfabijanic/hyprlogi/releases"
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
            wrapMode: Text.WordWrap
          }

          Column {
            visible: haptics.status.installed && root.profiles.length > 0
            width: parent.width
            spacing: Style.space(6)

            PanelSectionHeader {
              text: "PROFILE"
              foreground: root.foreground
              fontFamily: root.fontFamily
            }

            Repeater {
              model: root.profiles
              ActionRow {
                required property var modelData
                required property int index
                width: parent.width
                cursorIndex: root.profileBase + index
                glyph: modelData === haptics.status.profile ? Model.GLYPH_CHECK : ""
                label: Model.profileLabel(modelData)
                current: modelData === haptics.status.profile
                onActivated: haptics.setProfile(modelData)
              }
            }
          }

          PanelSeparator {
            visible: haptics.status.installed
            foreground: root.foreground
          }

          Column {
            visible: haptics.status.installed
            width: parent.width
            spacing: Style.space(6)

            Repeater {
              model: root.actions
              ActionRow {
                required property var modelData
                required property int index
                width: parent.width
                cursorIndex: root.actionBase + index
                glyph: modelData.glyph
                label: modelData.label
                detail: modelData.detail
                onActivated: root.activateAction(index)
              }
            }
          }
        }
      }
    }
  }

  // A clickable panel row with a leading glyph, a label and an optional detail line.
  component ActionRow: CursorSurface {
    id: row
    property int cursorIndex: 0
    property string glyph: ""
    property string label: ""
    property string detail: ""
    signal activated()

    hasCursor: root.cursorActive && root.cursorIndex === cursorIndex
    foreground: root.foreground
    opacity: enabled ? 1.0 : 0.5
    implicitHeight: rowContent.implicitHeight + Style.spacing.rowPaddingX

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      enabled: row.enabled && !haptics.busy
      cursorShape: Qt.PointingHandCursor
      onEntered: root.hover(row.cursorIndex)
      onClicked: row.activated()
    }

    RowLayout {
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      anchors.leftMargin: Style.space(10)
      anchors.rightMargin: Style.space(10)
      spacing: Style.space(8)

      Text {
        textFormat: Text.PlainText
        text: row.glyph
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.icon
        Layout.preferredWidth: Style.font.icon * 1.4
        Layout.alignment: Qt.AlignVCenter
      }

      ColumnLayout {
        id: rowContent
        Layout.fillWidth: true
        spacing: Style.space(1)

        Text {
          textFormat: Text.PlainText
          Layout.fillWidth: true
          text: row.label
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.body
          elide: Text.ElideRight
        }

        Text {
          textFormat: Text.PlainText
          Layout.fillWidth: true
          visible: row.detail !== ""
          text: row.detail
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          elide: Text.ElideRight
        }
      }
    }
  }
}
