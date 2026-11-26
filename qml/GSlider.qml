import QtQuick

// Beállítás sor csúszkával; a fogantyú lenyomva üveggömbbé nő.
Item {
    id: sl
    property string text: ""
    property real from: 0
    property real to: 1
    property real value: 0
    property real step: 0
    property string suffix: ""
    property int decimals: 0
    property real displayFactor: 1
    signal moved(real v)
    width: parent ? parent.width : 300
    height: 62

    Text { text: sl.text; color: G.text; font.pixelSize: 14; anchors.left: parent.left; anchors.top: parent.top; anchors.topMargin: 6 }
    Text {
        anchors.right: parent.right; anchors.top: parent.top; anchors.topMargin: 6
        text: (sl.value * sl.displayFactor).toFixed(sl.decimals) + sl.suffix
        color: G.subtext; font.pixelSize: 13
    }
    Item {
        id: track
        anchors.left: parent.left; anchors.right: parent.right
        anchors.bottom: parent.bottom; anchors.bottomMargin: 8
        height: 24
        readonly property real frac: Math.max(0, Math.min(1, (sl.value - sl.from) / (sl.to - sl.from)))
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width; height: 6; radius: 3
            color: G.dark ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(0, 0, 0, 0.12)
        }
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: knob.x + knob.width / 2; height: 6; radius: 3
            color: G.accent
        }
        Rectangle {
            id: knob
            width: ma.pressed ? 34 : 24; height: ma.pressed ? 26 : 24; radius: height / 2
            anchors.verticalCenter: parent.verticalCenter
            x: track.frac * (track.width - 24) - (width - 24) / 2
            color: ma.pressed ? Qt.rgba(1, 1, 1, 0.55) : "white"
            border.color: ma.pressed ? Qt.rgba(1, 1, 1, 0.9) : "transparent"
            border.width: 1
            Behavior on width { SpringAnimation { spring: 5; damping: 0.4 } }
            Behavior on height { SpringAnimation { spring: 5; damping: 0.4 } }
        }
        MouseArea {
            id: ma
            anchors.fill: parent
            anchors.margins: -8
            cursorShape: Qt.PointingHandCursor
            preventStealing: true
            function upd(mx) {
                var f = Math.max(0, Math.min(1, (mx - 8 - 12) / (track.width - 24)))
                var v = sl.from + f * (sl.to - sl.from)
                if (sl.step > 0) v = Math.round(v / sl.step) * sl.step
                sl.moved(v)
            }
            onPressed: function (m) { upd(m.x) }
            onPositionChanged: function (m) { if (pressed) upd(m.x) }
        }
    }
}
