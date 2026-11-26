import QtQuick

// Felugró üvegmenü (főmenü és jobb gombos menü). popup(x, y, elemek, kezelő, jobbra igazítva)
// Elem: { key, icon, text, hint, sep: true, zoom: true, enabled }
Item {
    id: menu
    property Item source: null
    property var items: []
    property var handler: null
    property bool open: false
    property real px: 0
    property real py: 0
    property bool alignRight: false
    property real zoomValue: 1.0
    anchors.fill: parent
    visible: fade > 0.005
    property real fade: open ? 1 : 0
    Behavior on fade { NumberAnimation { duration: G.dur(open ? 190 : 140); easing.type: Easing.OutCubic } }

    function popup(x, y, list, h, right) {
        items = list; handler = h; alignRight = !!right
        px = x; py = y
        open = true
        card.forceActiveFocus()
    }
    function close() { open = false }
    function trigger(key) {
        if (key !== "zoomIn" && key !== "zoomOut" && key !== "zoomReset") open = false
        if (handler) handler(key)
    }

    MouseArea {
        anchors.fill: parent
        enabled: menu.open
        acceptedButtons: Qt.AllButtons
        onPressed: menu.close()
        onWheel: function (w) { menu.close(); w.accepted = false }
    }

    Item {
        id: card
        width: 268
        height: col.implicitHeight + 12
        x: Math.max(8, Math.min(menu.width - width - 8, menu.alignRight ? menu.px - width : menu.px))
        y: Math.max(8, Math.min(menu.height - height - 8, menu.py))
        opacity: menu.fade
        scale: 0.86 + 0.14 * menu.fade
        transformOrigin: menu.alignRight ? Item.TopRight : Item.TopLeft
        focus: menu.open
        Keys.onEscapePressed: menu.close()
        MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }
        Glass { anchors.fill: parent; source: menu.source; radius: 20; tintAlpha: G.dark ? 0.48 : 0.55 }
        Column {
            id: col
            x: 6; y: 6
            width: parent.width - 12
            Repeater {
                model: menu.items
                Loader {
                    required property var modelData
                    width: col.width
                    sourceComponent: modelData.sep ? sepC : (modelData.zoom ? zoomC : itemC)
                    property var d: modelData
                }
            }
        }
    }

    Component {
        id: sepC
        Item { height: 9; Rectangle { anchors.centerIn: parent; width: parent.width - 20; height: 1; color: G.line } }
    }
    Component {
        id: itemC
        Rectangle {
            id: it
            readonly property var dd: parent ? parent.d : ({})
            readonly property bool en: dd.enabled === undefined || dd.enabled
            height: 36; radius: 12
            color: ima.containsMouse && en ? G.hover : "transparent"
            Ico { name: it.dd.icon || ""; size: 16; x: 12; anchors.verticalCenter: parent.verticalCenter; color: it.dd.danger ? "#FF6B6B" : G.text; opacity: it.en ? 0.9 : 0.35 }
            Text {
                x: 40; anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 40 - hintT.implicitWidth - 18
                text: it.dd.text || ""; elide: Text.ElideRight
                color: it.dd.danger ? "#FF6B6B" : G.text; opacity: it.en ? 1 : 0.4; font.pixelSize: 14
            }
            Text { id: hintT; anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter; text: it.dd.hint || ""; color: G.subtext; font.pixelSize: 12 }
            MouseArea { id: ima; anchors.fill: parent; hoverEnabled: true; enabled: it.en; cursorShape: Qt.PointingHandCursor; onClicked: menu.trigger(it.dd.key) }
        }
    }
    Component {
        id: zoomC
        Item {
            height: 40
            Ico { name: "zoom"; size: 16; x: 12; anchors.verticalCenter: parent.verticalCenter; opacity: 0.9 }
            Text { x: 40; anchors.verticalCenter: parent.verticalCenter; text: G.t("Nagyítás", "Zoom"); color: G.text; font.pixelSize: 14 }
            Row {
                anchors.right: parent.right; anchors.rightMargin: 4; anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                GlassButton { icon: "minus"; width: 32; height: 32; onClicked: menu.trigger("zoomOut") }
                Text {
                    width: 46; height: 32; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                    text: Math.round(menu.zoomValue * 100) + "%"; color: G.text; font.pixelSize: 13
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: menu.trigger("zoomReset") }
                }
                GlassButton { icon: "plus"; width: 32; height: 32; onClicked: menu.trigger("zoomIn") }
            }
        }
    }
}
