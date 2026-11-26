import QtQuick

// Összes lap: az egész ablak üveggé dermed, a lapok kártyákon (pillanatképpel) jelennek meg.
// Alul: "Összes bezárása" és "Új lap" kapszula.
Item {
    id: ov
    property var b
    property Item source: null
    property bool open: false
    property var thumbs: ({})
    anchors.fill: parent
    visible: fade > 0.005
    property real fade: open ? 1 : 0
    Behavior on fade { NumberAnimation { duration: G.dur(open ? 260 : 200); easing.type: Easing.OutCubic } }

    Keys.onEscapePressed: open = false
    focus: open

    Rectangle { anchors.fill: parent; color: G.tintColor; opacity: 0.55 * ov.fade }
    Glass {
        anchors.fill: parent
        source: ov.source
        radius: 0
        blur: 40
        refraction: 0
        tintAlpha: (G.dark ? 0.42 : 0.5) * ov.fade
        opacity: ov.fade
    }
    MouseArea { anchors.fill: parent; enabled: ov.open; onClicked: ov.open = false }

    Text {
        x: 32; y: 26
        text: G.t("Lapok", "Tabs") + "  ·  " + b.tabsModel.count
        color: G.text; font.pixelSize: 24; font.weight: Font.Bold
        opacity: ov.fade
    }
    GlassButton {
        anchors.right: parent.right; anchors.rightMargin: 24; y: 22
        icon: "close"; opacity: ov.fade
        onClicked: ov.open = false
    }

    GridView {
        id: grid
        anchors.fill: parent
        anchors.topMargin: 80; anchors.bottomMargin: 90
        anchors.leftMargin: Math.max(24, (parent.width - cols * cellWidth) / 2)
        anchors.rightMargin: 24
        readonly property int cols: Math.max(1, Math.floor((ov.width - 48) / 290))
        cellWidth: 290; cellHeight: 230
        clip: true
        model: b.tabsModel
        opacity: ov.fade
        scale: 0.94 + 0.06 * ov.fade
        boundsBehavior: Flickable.StopAtBounds
        delegate: Item {
            id: card
            required property int index
            required property string title
            required property string url
            required property string uid
            required property bool priv
            required property string icon
            width: 272; height: 212
            readonly property bool cur: index === b.currentIndex
            scale: cma.pressed ? 0.95 : (cma.containsMouse ? 1.025 : 1)
            Behavior on scale { SpringAnimation { spring: 4.5; damping: 0.32; epsilon: 0.002 } }

            Rectangle {
                anchors.fill: parent; anchors.margins: -3
                radius: 25
                color: "transparent"
                border.width: 2.5
                border.color: card.cur ? G.accent : "transparent"
            }
            Rectangle {
                id: frame
                anchors.fill: parent
                radius: 22
                color: G.dark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.6)
                border.color: card.priv ? Qt.rgba(0.6, 0.4, 1, 0.7) : Qt.rgba(1, 1, 1, G.dark ? 0.18 : 0.8)
                clip: true
                Image {
                    anchors.fill: parent; anchors.topMargin: 40
                    source: ov.thumbs[card.uid] ? ov.thumbs[card.uid] : ""
                    fillMode: Image.PreserveAspectCrop
                    verticalAlignment: Image.AlignTop
                    asynchronous: true; smooth: true; mipmap: true
                }
                Column {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: 20
                    visible: !ov.thumbs[card.uid]
                    spacing: 8
                    Ico { anchors.horizontalCenter: parent.horizontalCenter; name: card.priv ? "mask" : "globe"; size: 34; color: G.subtext }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: card.url === "" ? G.t("Kezdőlap", "Start page") : G.hostOf(card.url); color: G.subtext; font.pixelSize: 13 }
                }
                Rectangle {
                    width: parent.width; height: 40
                    color: G.dark ? Qt.rgba(0.08, 0.1, 0.16, 0.85) : Qt.rgba(1, 1, 1, 0.9)
                    Image {
                        id: cfav
                        x: 12; width: 16; height: 16; anchors.verticalCenter: parent.verticalCenter
                        source: card.icon !== "" ? card.icon : (card.url !== "" ? G.faviconUrl(card.url) : "")
                        sourceSize: Qt.size(32, 32); asynchronous: true
                        visible: status === Image.Ready && !card.priv
                    }
                    Ico { x: 12; anchors.verticalCenter: parent.verticalCenter; size: 15; name: card.priv ? "mask" : "globe"; color: card.priv ? "#C5A8FF" : G.subtext; visible: !cfav.visible }
                    Text {
                        x: 36; width: parent.width - 36 - 40; anchors.verticalCenter: parent.verticalCenter
                        text: card.title !== "" ? card.title : (card.url !== "" ? G.prettyUrl(card.url) : G.t("Új lap", "New tab"))
                        color: G.text; font.pixelSize: 13; font.weight: Font.DemiBold; elide: Text.ElideRight
                    }
                }
            }
            MouseArea {
                id: cma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                onClicked: function (m) {
                    if (m.button === Qt.MiddleButton) b.closeTab(card.index)
                    else { b.selectTab(card.index); ov.open = false }
                }
            }
            // üveg X
            Item {
                width: 30; height: 30
                anchors.right: parent.right; anchors.rightMargin: 5; y: 5
                Rectangle { anchors.fill: parent; radius: 15; color: xma.containsMouse ? "#E5484D" : (G.dark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08)); border.color: Qt.rgba(1, 1, 1, 0.25) }
                Ico { anchors.centerIn: parent; name: "close"; size: 13; stroke: 2.2; color: xma.containsMouse ? "white" : G.text }
                MouseArea { id: xma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: b.closeTab(card.index) }
            }
        }
        add: Transition { ParallelAnimation { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: G.dur(200) } NumberAnimation { property: "scale"; from: 0.8; to: 1; duration: G.dur(260); easing.type: Easing.OutBack } } }
        remove: Transition { ParallelAnimation { NumberAnimation { property: "opacity"; to: 0; duration: G.dur(180) } NumberAnimation { property: "scale"; to: 0.75; duration: G.dur(200) } } }
        displaced: Transition { NumberAnimation { properties: "x,y"; duration: G.dur(300); easing.type: Easing.OutCubic } }
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom; anchors.bottomMargin: 26
        spacing: 12
        opacity: ov.fade
        Capsule { text: G.t("Összes bezárása", "Close all"); ico: "trash"; danger: true; onClicked: { b.closeAllTabs(); ov.open = false } }
        Capsule { text: G.t("Új privát lap", "New private tab"); ico: "mask"; onClicked: { b.newTab("", true); ov.open = false } }
        Capsule { text: G.t("Új lap", "New tab"); ico: "plus"; onClicked: { b.newTab("", false); ov.open = false } }
    }

    component Capsule: Item {
        id: cap
        property string text: ""
        property string ico: ""
        property bool danger: false
        property Item glassSource: null
        signal clicked()
        width: crow.implicitWidth + 40; height: 46
        scale: kma.pressed ? 0.93 : (kma.containsMouse ? 1.04 : 1)
        Behavior on scale { SpringAnimation { spring: 5; damping: 0.32; epsilon: 0.002 } }
        Rectangle {
            anchors.fill: parent; radius: 23
            color: cap.danger ? (kma.containsMouse ? "#E5484D" : Qt.rgba(0.9, 0.28, 0.3, 0.30)) : (kma.containsMouse ? Qt.rgba(1, 1, 1, 0.24) : Qt.rgba(1, 1, 1, G.dark ? 0.14 : 0.6))
            border.color: Qt.rgba(1, 1, 1, G.dark ? 0.28 : 0.9)
            Behavior on color { ColorAnimation { duration: G.dur(150) } }
        }
        Row {
            id: crow; anchors.centerIn: parent; spacing: 8
            Ico { name: cap.ico; size: 16; color: cap.danger && kma.containsMouse ? "white" : G.text; anchors.verticalCenter: parent.verticalCenter }
            Text { text: cap.text; color: cap.danger && kma.containsMouse ? "white" : G.text; font.pixelSize: 14; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
        }
        MouseArea { id: kma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: cap.clicked() }
    }
}
