import QtQuick

// Rövid értesítő kapszula alul középen.
Item {
    id: toast
    property Item source: null
    property string text: ""
    property string actionText: ""
    property var action: null
    width: Math.min(parent.width - 40, row.implicitWidth + 36)
    height: 44
    anchors.horizontalCenter: parent.horizontalCenter
    y: parent.height - (shown ? height + 22 : -10)
    opacity: shown ? 1 : 0
    visible: opacity > 0.01
    property bool shown: false
    Behavior on y { SpringAnimation { spring: 3; damping: 0.32; epsilon: 0.3 } }
    Behavior on opacity { NumberAnimation { duration: G.dur(180) } }

    function show(msg, actText, act) {
        text = msg; actionText = actText || ""; action = act || null
        shown = true; hide.restart()
    }
    Timer { id: hide; interval: 3200; onTriggered: toast.shown = false }

    Glass { anchors.fill: parent; source: toast.source; radius: height / 2 }
    Row {
        id: row
        anchors.centerIn: parent
        spacing: 14
        Text { text: toast.text; color: G.text; font.pixelSize: 14; anchors.verticalCenter: parent.verticalCenter; elide: Text.ElideRight; width: Math.min(implicitWidth, toast.parent.width - 200) }
        Text {
            visible: toast.actionText !== ""
            text: toast.actionText; color: G.accent; font.pixelSize: 14; font.weight: Font.DemiBold
            anchors.verticalCenter: parent.verticalCenter
            MouseArea { anchors.fill: parent; anchors.margins: -8; cursorShape: Qt.PointingHandCursor; onClicked: { toast.shown = false; if (toast.action) toast.action() } }
        }
    }
}
