import QtQuick

// Beállítás sor kapcsolóval (rugós gombbal).
Item {
    id: sw
    property string text: ""
    property string sub: ""
    property bool checked: false
    signal toggled(bool on)
    width: parent ? parent.width : 300
    height: Math.max(48, col.implicitHeight + 16)

    Column {
        id: col
        anchors.left: parent.left
        anchors.right: track.left
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2
        Text { text: sw.text; color: G.text; font.pixelSize: 14; width: parent.width; wrapMode: Text.WordWrap }
        Text { visible: sw.sub !== ""; text: sw.sub; color: G.subtext; font.pixelSize: 12; width: parent.width; wrapMode: Text.WordWrap }
    }
    Rectangle {
        id: track
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 46; height: 28; radius: 14
        color: sw.checked ? G.accent : (G.dark ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(0, 0, 0, 0.14))
        Behavior on color { ColorAnimation { duration: G.dur(200) } }
        Rectangle {
            width: ma.pressed ? 28 : 22; height: 22; radius: 11
            y: 3
            x: sw.checked ? track.width - width - 3 : 3
            color: "white"
            Behavior on x { SpringAnimation { spring: 4.5; damping: 0.36; epsilon: 0.2 } }
            Behavior on width { NumberAnimation { duration: G.dur(140) } }
        }
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: sw.toggled(!sw.checked)
    }
}
