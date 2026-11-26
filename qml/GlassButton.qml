import QtQuick

// Kerek / kapszula üveggomb ikonnal vagy szöveggel; lenyomásra rugózva benyomódik.
Item {
    id: btn
    property string icon: ""        // az Ico egyik neve, vagy üres
    property string text: ""
    property bool glass: false      // saját üveg háttér
    property Item source: null
    property color tone: G.text
    property bool danger: false
    property bool checked: false
    property real iconSize: 17
    property string tip: ""
    signal clicked()
    signal rightClicked()
    implicitWidth: text !== "" ? row.implicitWidth + 28 : 36
    implicitHeight: 36

    scale: ma.pressed ? 0.88 : (ma.containsMouse ? 1.04 : 1.0)
    Behavior on scale { SpringAnimation { spring: 5; damping: 0.32; epsilon: 0.002 } }

    Glass {
        anchors.fill: parent
        visible: btn.glass
        source: btn.source
        radius: height / 2
        press: ma.pressed ? 1 : 0
    }
    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: btn.danger && ma.containsMouse ? "#E5484D"
             : btn.checked ? Qt.rgba(G.accent.r, G.accent.g, G.accent.b, 0.30)
             : (ma.containsMouse ? G.hover : "transparent")
        Behavior on color { ColorAnimation { duration: G.dur(160) } }
    }
    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8
        Ico {
            visible: btn.icon !== ""
            name: btn.icon
            size: btn.iconSize
            color: btn.danger && ma.containsMouse ? "white" : btn.tone
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            visible: btn.text !== ""
            text: btn.text
            color: btn.tone
            font.pixelSize: 14
            font.weight: Font.DemiBold
            anchors.verticalCenter: parent.verticalCenter
        }
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: function (m) { if (m.button === Qt.RightButton) btn.rightClicked(); else btn.clicked() }
    }
    ToolTipLite { text: btn.tip; show: ma.containsMouse && btn.tip !== "" }
}
