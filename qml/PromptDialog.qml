import QtQuick

// Üveg párbeszédablak: cím, szöveg, legfeljebb két beviteli mező, két gomb.
Item {
    id: dlg
    property Item source: null
    property string title: ""
    property string message: ""
    property string field1Hint: ""
    property string field2Hint: ""
    property bool showField1: false
    property bool showField2: false
    property string okText: "OK"
    property string cancelText: G.t("Mégse", "Cancel")
    property var onOk: null
    property var onCancel: null
    property bool open: false
    anchors.fill: parent
    visible: fade > 0.01
    property real fade: open ? 1 : 0
    Behavior on fade { NumberAnimation { duration: G.dur(200); easing.type: Easing.OutCubic } }

    function ask(o) {
        title = o.title || ""; message = o.message || ""
        showField1 = o.field1 !== undefined; showField2 = o.field2 !== undefined
        field1Hint = o.field1Hint || ""; field2Hint = o.field2Hint || ""
        f1.text = o.field1 || ""; f2.text = o.field2 || ""
        okText = o.okText || "OK"; cancelText = o.cancelText || G.t("Mégse", "Cancel")
        onOk = o.onOk || null; onCancel = o.onCancel || null
        open = true
        if (showField1) { f1.focusIn(); f1.selectAll() } else card.forceActiveFocus()
    }
    function accept() { open = false; if (onOk) onOk(f1.text, f2.text) }
    function reject() { open = false; if (onCancel) onCancel() }

    Rectangle { anchors.fill: parent; color: Qt.rgba(0, 0, 0, 0.32 * dlg.fade) }
    MouseArea { anchors.fill: parent; enabled: dlg.open; onClicked: dlg.reject(); onWheel: function (w) { w.accepted = true } }

    Item {
        id: card
        width: 420
        height: col.implicitHeight + 44
        anchors.centerIn: parent
        scale: 0.9 + 0.1 * dlg.fade
        opacity: dlg.fade
        focus: dlg.open
        Keys.onEscapePressed: dlg.reject()
        Keys.onReturnPressed: dlg.accept()
        Keys.onEnterPressed: dlg.accept()
        MouseArea { anchors.fill: parent }
        Glass { anchors.fill: parent; source: dlg.source; radius: 26; tintAlpha: G.dark ? 0.55 : 0.6 }
        Column {
            id: col
            x: 22; y: 22
            width: parent.width - 44
            spacing: 12
            Text { text: dlg.title; color: G.text; font.pixelSize: 18; font.weight: Font.DemiBold; width: parent.width; wrapMode: Text.WordWrap; visible: text !== "" }
            Text { text: dlg.message; color: G.subtext; font.pixelSize: 14; width: parent.width; wrapMode: Text.WordWrap; visible: text !== "" }
            Field { id: f1; visible: dlg.showField1; hint: dlg.field1Hint; onAccepted: dlg.showField2 ? f2.focusIn() : dlg.accept(); onEscape: dlg.reject() }
            Field { id: f2; visible: dlg.showField2; hint: dlg.field2Hint; onAccepted: dlg.accept(); onEscape: dlg.reject() }
            Item { width: 1; height: 4 }
            Row {
                anchors.right: parent.right
                spacing: 10
                GlassButton { text: dlg.cancelText; onClicked: dlg.reject(); visible: dlg.cancelText !== "" }
                GlassButton { text: dlg.okText; checked: true; onClicked: dlg.accept() }
            }
        }
    }

    component Field: Rectangle {
        id: fr
        property alias text: inp.text
        property string hint: ""
        signal accepted()
        function selectAll() { inp.selectAll() }
        function focusIn() { inp.forceActiveFocus() }
        signal escape()
        width: parent.width; height: 42; radius: 21
        color: G.dark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.06)
        border.color: inp.activeFocus ? G.accent : G.line
        TextInput {
            id: inp
            anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16
            verticalAlignment: TextInput.AlignVCenter
            color: G.text; font.pixelSize: 14; clip: true
            selectByMouse: true; selectionColor: G.accent
            onAccepted: fr.accepted()
            Keys.onEscapePressed: fr.escape()
        }
        Text { anchors.fill: inp; verticalAlignment: Text.AlignVCenter; text: fr.hint; color: G.subtext; font.pixelSize: 14; visible: inp.text === "" }
    }
}
