import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons

Item {
    id: root
    property var shell: null
    property var manifest: null
    property bool opened: false
    property bool running: true
    property int phaseIndex: 0
    property int remaining: 4
    property int cycles: 0
    readonly property var phaseNames: ["INHALE", "HOLD", "EXHALE", "REST"]
    readonly property var phaseSeconds: [4, 4, 6, 2]
    readonly property real targetScale: phaseIndex === 0 || phaseIndex === 1 ? 1.35 : 0.72

    function open(payloadJson) {
        reset();
        opened = true;
        Qt.callLater(function () {
            keyCatcher.forceActiveFocus();
        });
    }
    function close() {
        opened = false;
        running = false;
    }
    function toggle() {
        if (opened)
            dismiss();
        else
            open("{}");
    }
    function dismiss() {
        if (shell && typeof shell.hide === "function")
            shell.hide((manifest && manifest.id) || "io.github.rookepoole.zen-breather");
        else
            close();
    }
    function reset() {
        phaseIndex = 0;
        remaining = phaseSeconds[0];
        cycles = 0;
        running = true;
    }
    function nextPhase() {
        phaseIndex = (phaseIndex + 1) % phaseNames.length;
        if (phaseIndex === 0)
            cycles++;
        remaining = phaseSeconds[phaseIndex];
    }

    Timer {
        interval: 1000
        running: root.opened && root.running
        repeat: true
        onTriggered: {
            if (root.remaining > 1)
                root.remaining--;
            else
                root.nextPhase();
        }
    }

    PanelWindow {
        id: window
        visible: root.opened
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        color: "transparent"
        WlrLayershell.namespace: "rookepoole-zen-breather"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        exclusionMode: ExclusionMode.Ignore

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0.015, 0.02, 0.035, 0.90)
        }
        MouseArea {
            anchors.fill: parent
            onClicked: root.dismiss()
        }

        Item {
            id: keyCatcher
            anchors.fill: parent
            focus: true
            Keys.onPressed: function (event) {
                if (event.key === Qt.Key_Escape) {
                    root.dismiss();
                    event.accepted = true;
                } else if (event.key === Qt.Key_Space) {
                    root.running = !root.running;
                    event.accepted = true;
                } else if (event.key === Qt.Key_R) {
                    root.reset();
                    event.accepted = true;
                }
            }

            MouseArea {
                anchors.fill: card
                onClicked: {}
            }

            Rectangle {
                id: card
                width: Math.min(Style.space(520), window.width - Style.space(40))
                height: Math.min(Style.space(620), window.height - Style.space(40))
                anchors.centerIn: parent
                radius: Style.cornerRadius * 2
                color: Qt.rgba(Color.background.r, Color.background.g, Color.background.b, 0.96)
                border.width: 1
                border.color: Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.36)

                Rectangle {
                    id: halo
                    width: Math.min(card.width * 0.55, card.height * 0.42)
                    height: width
                    radius: width / 2
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: Style.space(92)
                    color: Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.18)
                    scale: root.targetScale
                    Behavior on scale {
                        NumberAnimation {
                            duration: root.phaseSeconds[root.phaseIndex] * 1000
                            easing.type: Easing.InOutSine
                        }
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width * 0.72
                        height: width
                        radius: width / 2
                        color: Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.68)
                    }
                }

                Column {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.leftMargin: Style.space(28)
                    anchors.rightMargin: Style.space(28)
                    anchors.bottomMargin: Style.space(28)
                    spacing: Style.space(12)
                    Text {
                        width: parent.width
                        text: root.phaseNames[root.phaseIndex]
                        color: Color.foreground
                        font.family: Style.font.family
                        font.pixelSize: Style.font.displayLarge
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Text {
                        width: parent.width
                        text: root.remaining
                        color: Color.accent
                        font.family: Style.font.family
                        font.pixelSize: Style.font.displayLarge * 1.8
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Text {
                        width: parent.width
                        text: root.running ? "Follow the light. Let the shoulders fall." : "Paused"
                        color: Color.foreground
                        opacity: 0.65
                        font.family: Style.font.family
                        font.pixelSize: Style.font.body
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Text {
                        width: parent.width
                        text: root.cycles + (root.cycles === 1 ? " cycle" : " cycles") + "  ·  Space pause  ·  R reset  ·  Esc close"
                        color: Color.foreground
                        opacity: 0.48
                        font.family: Style.font.family
                        font.pixelSize: Style.font.caption
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
        }
    }
}
