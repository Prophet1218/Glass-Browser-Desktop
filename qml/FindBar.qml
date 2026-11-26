import QtQuick

// Keresés az oldalon: kis üvegkapszula a sáv alatt jobbra.
Item {
    id: fb
    property Item source: null
    property bool open: false
    property int matches: 0
    property int active: 0
    signal search(string text, bool backward)
    signal closed()
    width: 380; height: 46
    opacity: open ? 1 : 0
    visible: opacity > 0.01
    scale: open ? 1 : 0.92
    transformOrigin: Item.TopRight
    Behavior on opacity { NumberAnimation { duration: G.dur(160) } }
    Behavior on scale { SpringAnimation { spring: 4; damping: 0.35; epsilon: 0.002 } }

    function show() { open = true; inp.forceActiveFocus(); inp.selectAll() }
    function hide() { if (!open) return; open = false; inp.text = ""; search("", false); closed() }
    readonly property string text: inp.text

    Glass { anchors.fill: parent; source: fb.source; radius: height / 2 }
    Ico { name: "search"; size: 16; color: G.subtext; x: 16; anchors.verticalCenter: parent.verticalCenter }
    TextInput {
        id: inp
        x: 42; width: parent.width - 42 - btns.width - 70
        anchors.verticalCenter: parent.verticalCenter
        color: G.text; font.pixelSize: 14; clip: true
        selectByMouse: true; selectionColor: G.accent
        onTextChanged: fb.search(text, false)
        Keys.onReturnPressed: function (e) { fb.search(text, (e.modifiers & Qt.ShiftModifier) !== 0) }
        Keys.onEscapePressed: fb.hide()
        Text { anchors.fill: parent; text: G.t("Keresés az oldalon", "Find in page"); color: G.subtext; font.pixelSize: 14; visible: parent.text === "" }
    }
    Text {
        anchors.right: btns.left; anchors.rightMargin: 8; anchors.verticalCenter: parent.verticalCenter
        text: inp.text === "" ? "" : (fb.matches > 0 ? fb.active + "/" + fb.matches : "0/0")
        color: G.subtext; font.pixelSize: 12
    }
    Row {
        id: btns
        anchors.right: parent.right; anchors.rightMargin: 5; anchors.verticalCenter: parent.verticalCenter
        GlassButton { icon: "chevron"; rotation: 180; width: 34; height: 34; onClicked: fb.search(inp.text, true) }
        GlassButton { icon: "chevron"; width: 34; height: 34; onClicked: fb.search(inp.text, false) }
        GlassButton { icon: "close"; width: 34; height: 34; onClicked: fb.hide() }
    }
}
