import QtQuick

// Egy lap a felső sávban: ikon (vagy töltésjelző), cím, bezárás gomb.
Item {
    id: chip
    property string title: ""
    property string icon: ""
    property string url: ""
    property bool priv: false
    property bool current: false
    property bool loading: false
    signal activated()
    signal closeRequested()
    signal menuRequested(real x, real y)
    height: 32

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: height / 2
        color: chip.current ? (G.dark ? Qt.rgba(1, 1, 1, 0.17) : Qt.rgba(1, 1, 1, 0.75))
                            : (ma.containsMouse ? G.hover : "transparent")
        border.color: chip.current ? Qt.rgba(1, 1, 1, G.dark ? 0.22 : 0.9) : "transparent"
        Behavior on color { ColorAnimation { duration: G.dur(180) } }
        // privát lap: lila derengés
        Rectangle {
            anchors.fill: parent; radius: parent.radius
            visible: chip.priv
            color: Qt.rgba(0.58, 0.36, 1.0, chip.current ? 0.30 : 0.16)
        }
    }

    Item {
        id: iconBox
        x: 10; width: 16; height: 16
        anchors.verticalCenter: parent.verticalCenter
        Image {
            id: fav
            anchors.fill: parent
            source: chip.icon !== "" ? chip.icon : (chip.url !== "" ? G.faviconUrl(chip.url) : "")
            sourceSize: Qt.size(32, 32)
            smooth: true; asynchronous: true
            visible: !chip.loading && status === Image.Ready && !chip.priv
        }
        Ico {
            anchors.centerIn: parent
            size: 15
            name: chip.priv ? "mask" : "globe"
            color: chip.priv ? "#C5A8FF" : G.subtext
            visible: !chip.loading && (chip.priv || fav.status !== Image.Ready)
        }
        // töltésjelző ív
        Rectangle {
            anchors.fill: parent
            visible: chip.loading
            radius: width / 2
            color: "transparent"
            border.width: 2
            border.color: Qt.rgba(G.accent.r, G.accent.g, G.accent.b, 0.25)
            Rectangle {
                width: 5; height: 5; radius: 2.5; color: G.accent
                x: parent.width / 2 - 2.5 + Math.cos(spin.a) * 6
                y: parent.height / 2 - 2.5 + Math.sin(spin.a) * 6
            }
            FrameAnimation { id: spin; property real a: 0; running: chip.loading; onTriggered: a += frameTime * 7 }
        }
    }

    Text {
        anchors.left: iconBox.right; anchors.leftMargin: 8
        anchors.right: closeB.visible ? closeB.left : parent.right; anchors.rightMargin: closeB.visible ? 2 : 12
        anchors.verticalCenter: parent.verticalCenter
        text: chip.title !== "" ? chip.title : (chip.url !== "" ? G.prettyUrl(chip.url) : G.t("Új lap", "New tab"))
        elide: Text.ElideRight
        color: G.text
        opacity: chip.current ? 1 : 0.78
        font.pixelSize: 13
        font.weight: chip.current ? Font.DemiBold : Font.Normal
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        onClicked: function (m) {
            if (m.button === Qt.MiddleButton) chip.closeRequested()
            else if (m.button === Qt.RightButton) chip.menuRequested(m.x, m.y)
            else chip.activated()
        }
    }

    Item {
        id: closeB
        width: 24; height: 24
        anchors.right: parent.right; anchors.rightMargin: 5
        anchors.verticalCenter: parent.verticalCenter
        visible: (chip.current || ma.containsMouse || cma.containsMouse) && chip.width > 90
        Rectangle { anchors.fill: parent; radius: 12; color: cma.containsMouse ? G.hover : "transparent" }
        Ico { anchors.centerIn: parent; name: "close"; size: 13; stroke: 2 }
        MouseArea { id: cma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: chip.closeRequested() }
    }
}
