import QtQuick

// Kapszulás választó: a kijelölés mögött egy üvegcsepp úszik át.
Item {
    id: ch
    property string text: ""
    property var options: []   // [{ key, label }]
    property string current: ""
    signal picked(string key)
    width: parent ? parent.width : 300
    height: (text !== "" ? 26 : 0) + 40 + 8

    Text { visible: ch.text !== ""; text: ch.text; color: G.text; font.pixelSize: 14; anchors.top: parent.top; anchors.topMargin: 4 }
    Rectangle {
        id: box
        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.bottomMargin: 4
        height: 40; radius: 20
        color: G.dark ? Qt.rgba(1, 1, 1, 0.07) : Qt.rgba(0, 0, 0, 0.06)
        border.color: G.line
        readonly property real cell: (width - 8) / Math.max(1, ch.options.length)
        readonly property int idx: {
            for (var i = 0; i < ch.options.length; i++) if (ch.options[i].key === ch.current) return i
            return 0
        }
        Rectangle {
            x: 4 + box.idx * box.cell
            y: 4
            width: box.cell; height: 32; radius: 16
            color: G.dark ? Qt.rgba(1, 1, 1, 0.20) : "white"
            border.color: Qt.rgba(1, 1, 1, G.dark ? 0.3 : 0.9)
            Behavior on x { SpringAnimation { spring: 3.5; damping: 0.3; epsilon: 0.3 } }
        }
        Row {
            x: 4; y: 4
            Repeater {
                model: ch.options
                Item {
                    required property var modelData
                    width: box.cell; height: 32
                    Text {
                        anchors.centerIn: parent
                        width: parent.width - 8
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        text: modelData.label
                        color: G.text
                        font.pixelSize: 13
                        font.weight: modelData.key === ch.current ? Font.DemiBold : Font.Normal
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: ch.picked(modelData.key) }
                }
            }
        }
    }
}
