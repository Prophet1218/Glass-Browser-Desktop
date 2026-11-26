import QtQuick

// Kis üveg buborék tipp (rövid késleltetéssel jelenik meg a gomb alatt).
Item {
    id: tt
    property string text: ""
    property bool show: false
    anchors.top: parent.bottom
    anchors.topMargin: 8
    anchors.horizontalCenter: parent.horizontalCenter
    width: lbl.implicitWidth + 20
    height: 28
    z: 1000
    opacity: (show && delay.ok) ? 1 : 0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: G.dur(140) } }
    Timer { id: delay; property bool ok: false; interval: 600; running: tt.show; onTriggered: ok = true }
    onShowChanged: if (!show) delay.ok = false
    Rectangle {
        anchors.fill: parent
        radius: 14
        color: G.dark ? Qt.rgba(0.08, 0.1, 0.16, 0.92) : Qt.rgba(1, 1, 1, 0.95)
        border.color: G.line
    }
    Text { id: lbl; anchors.centerIn: parent; text: tt.text; color: G.text; font.pixelSize: 12 }
}
