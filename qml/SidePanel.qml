import QtQuick

// Jobbról beúszó üveg oldalpanel (beállítások, letöltések, előzmények, könyvjelzők).
Item {
    id: sp
    property Item source: null
    property string title: ""
    property bool open: false
    property real topInset: 8
    property alias tools: toolsRow.data
    default property alias content: body.data
    anchors.fill: parent
    visible: slide > 0.005
    property real slide: open ? 1 : 0
    Behavior on slide { SpringAnimation { spring: 3.2; damping: 0.34; epsilon: 0.002 } }

    MouseArea { anchors.fill: parent; enabled: sp.open; onClicked: sp.open = false }

    Item {
        id: card
        width: Math.min(440, parent.width - 32)
        anchors.top: parent.top; anchors.topMargin: sp.topInset
        anchors.bottom: parent.bottom; anchors.bottomMargin: 10
        x: parent.width - (width + 10) * sp.slide
        opacity: Math.min(1, sp.slide * 1.6)
        MouseArea { anchors.fill: parent; onWheel: function (w) { w.accepted = false } }
        Glass { anchors.fill: parent; source: sp.source; radius: 26; tintAlpha: G.dark ? 0.5 : 0.56 }
        Text {
            x: 22; y: 18
            text: sp.title; color: G.text
            font.pixelSize: 20; font.weight: Font.Bold
        }
        GlassButton { id: closeBtn; anchors.right: parent.right; anchors.rightMargin: 12; y: 12; icon: "close"; onClicked: sp.open = false }
        Row { id: toolsRow; anchors.right: closeBtn.left; anchors.rightMargin: 4; y: 12; spacing: 4 }
        Item {
            id: body
            anchors.fill: parent
            anchors.topMargin: 60
            anchors.leftMargin: 12; anchors.rightMargin: 12; anchors.bottomMargin: 12
            clip: true
        }
    }
}
