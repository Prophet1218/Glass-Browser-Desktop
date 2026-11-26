import QtQuick
import QtQuick.Window

// Lebegő folyékony üveg sáv: fent a lapok és jobb oldalt az ablakgombok, alatta a navigáció,
// a címsáv kapszula és az eszközök. Az üres részen fogva az ablak mozgatható.
Item {
    id: bar
    property var b                       // a böngésző (Main)
    property Item source: null
    readonly property alias urlInput: urlInput
    readonly property bool editing: urlInput.activeFocus
    readonly property real ctrlW: controls.width
    height: 92

    Glass {
        id: glass
        anchors.fill: parent
        source: bar.source
        radius: b.maximized ? 18 : 22
        tintAlpha: G.dark ? 0.30 : 0.38
    }

    // ablak mozgatása / dupla kattintás: teljes méret
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onPressed: function (m) { if (m.button === Qt.LeftButton) b.win.startSystemMove() }
        onDoubleClicked: b.toggleMaximize()
    }

    // ---------------------------------------------------------------- 1. sor: lapok
    readonly property real tabsAvail: width - 16 - newTab.width - 6 - controls.width - 56
    readonly property real chipW: Math.max(72, Math.min(232, (tabsAvail - (tabsList.count - 1) * 4) / Math.max(1, tabsList.count)))

    ListView {
        id: tabsList
        x: 8; y: 7
        height: 32
        width: Math.min(contentWidth, bar.tabsAvail)
        orientation: ListView.Horizontal
        spacing: 4
        clip: true
        interactive: contentWidth > width
        boundsBehavior: Flickable.StopAtBounds
        model: b.tabsModel
        currentIndex: b.currentIndex
        highlightMoveDuration: G.dur(260)
        highlightFollowsCurrentItem: false
        Behavior on width { NumberAnimation { duration: G.dur(240); easing.type: Easing.OutCubic } }
        onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

        delegate: TabChip {
            required property int index
            required title
            required icon
            required url
            required priv
            required loading
            width: bar.chipW
            Behavior on width { NumberAnimation { duration: G.dur(240); easing.type: Easing.OutCubic } }
            current: index === b.currentIndex
            onActivated: b.selectTab(index)
            onCloseRequested: b.closeTab(index)
            onMenuRequested: function (mx, my) { var p = mapToItem(b.contentItem, mx, my); b.showTabMenu(index, p.x, p.y) }
        }
        add: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: G.dur(220) }
                NumberAnimation { property: "scale"; from: 0.7; to: 1; duration: G.dur(320); easing.type: Easing.OutBack; easing.overshoot: 1.6 }
            }
        }
        remove: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; to: 0; duration: G.dur(160) }
                NumberAnimation { property: "scale"; to: 0.7; duration: G.dur(180) }
            }
        }
        displaced: Transition { NumberAnimation { properties: "x"; duration: G.dur(260); easing.type: Easing.OutCubic } }
    }

    GlassButton {
        id: newTab
        x: tabsList.x + tabsList.width + 6
        y: 5
        width: 34; height: 34
        icon: "plus"; iconSize: 16
        tip: G.t("Új lap (Ctrl+T)", "New tab (Ctrl+T)")
        onClicked: b.newTab("", false)
        onRightClicked: b.newTab("", true)
    }

    // ablakgombok a jobb felső sarokban
    Row {
        id: controls
        anchors.right: parent.right; anchors.rightMargin: 8
        y: 5
        spacing: 2
        GlassButton { width: 34; height: 34; icon: "minus"; iconSize: 15; tip: G.t("Kis méret", "Minimize"); onClicked: b.win.showMinimized() }
        GlassButton { width: 34; height: 34; icon: b.maximized ? "restore" : "max"; iconSize: 14; tip: b.maximized ? G.t("Visszaállítás", "Restore") : G.t("Teljes méret", "Maximize"); onClicked: b.toggleMaximize() }
        GlassButton { width: 34; height: 34; icon: "close"; iconSize: 15; danger: true; tip: G.t("Bezárás", "Close"); onClicked: b.win.close() }
    }

    // ---------------------------------------------------------------- 2. sor: navigáció
    Row {
        id: nav
        x: 8; y: 46
        spacing: 2
        GlassButton { width: 38; height: 38; icon: "back"; tip: G.t("Vissza (Alt+←)", "Back (Alt+←)"); opacity: b.canBack ? 1 : 0.38; onClicked: b.goBack() }
        GlassButton { width: 38; height: 38; icon: "forward"; tip: G.t("Előre (Alt+→)", "Forward (Alt+→)"); opacity: b.canForward ? 1 : 0.38; onClicked: b.goForward() }
        GlassButton { width: 38; height: 38; icon: b.curLoading ? "stop" : "reload"; tip: G.t("Újratöltés (F5)", "Reload (F5)"); onClicked: b.curLoading ? b.stopLoad() : b.reload() }
        GlassButton { width: 38; height: 38; icon: "home"; tip: G.t("Kezdőlap", "Home"); onClicked: b.goHome() }
    }

    Row {
        id: tools
        anchors.right: parent.right; anchors.rightMargin: 8
        y: 46
        spacing: 2
        Item {
            width: 38; height: 38
            GlassButton { anchors.fill: parent; icon: "download"; tip: G.t("Letöltések (Ctrl+J)", "Downloads (Ctrl+J)"); onClicked: b.openPanel("downloads") }
            // folyamatban lévő letöltés: gyűrű
            Canvas {
                id: ring
                anchors.fill: parent; anchors.margins: 3
                visible: b.dlActive
                property real p: b.dlProgress
                onPChanged: requestPaint()
                onVisibleChanged: requestPaint()
                onPaint: {
                    var c = getContext("2d"); c.reset()
                    c.lineWidth = 2.5; c.lineCap = "round"
                    c.strokeStyle = Qt.rgba(G.accent.r, G.accent.g, G.accent.b, 0.25)
                    c.beginPath(); c.arc(width / 2, height / 2, width / 2 - 2, 0, Math.PI * 2); c.stroke()
                    c.strokeStyle = G.accent
                    c.beginPath(); c.arc(width / 2, height / 2, width / 2 - 2, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * Math.max(0.03, p)); c.stroke()
                }
            }
            Rectangle {
                width: 9; height: 9; radius: 4.5; color: G.accent
                anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 6
                visible: b.dlUnseen && !b.dlActive
            }
        }
        Item {
            width: 38; height: 38
            GlassButton { anchors.fill: parent; tip: G.t("Összes lap (Ctrl+Shift+A)", "All tabs (Ctrl+Shift+A)"); onClicked: b.openOverview() }
            Rectangle {
                anchors.centerIn: parent
                width: 22; height: 20; radius: 6
                color: "transparent"; border.color: G.text; border.width: 1.6
                Text { anchors.centerIn: parent; text: b.tabsModel.count; color: G.text; font.pixelSize: 11; font.weight: Font.Bold }
            }
        }
        GlassButton { id: menuBtn; width: 38; height: 38; icon: "dots"; iconSize: 20; tip: G.t("Menü", "Menu"); onClicked: { var p = mapToItem(b.contentItem, width, height + 6); b.showMainMenu(p.x, p.y) } }
    }

    // címsáv kapszula
    Rectangle {
        id: capsule
        anchors.left: nav.right; anchors.leftMargin: 8
        anchors.right: tools.left; anchors.rightMargin: 8
        y: 46; height: 38; radius: 19
        color: urlInput.activeFocus ? (G.dark ? Qt.rgba(0, 0, 0, 0.30) : Qt.rgba(1, 1, 1, 0.75))
                                    : (G.dark ? Qt.rgba(1, 1, 1, 0.07) : Qt.rgba(1, 1, 1, 0.45))
        border.color: urlInput.activeFocus ? Qt.rgba(G.accent.r, G.accent.g, G.accent.b, 0.8) : G.line
        border.width: urlInput.activeFocus ? 1.5 : 1
        Behavior on color { ColorAnimation { duration: G.dur(180) } }

        Ico {
            id: lockIco
            x: 14; anchors.verticalCenter: parent.verticalCenter
            size: 15
            name: urlInput.activeFocus || b.curUrl === "" ? "search" : (b.curPriv ? "mask" : (b.curUrl.indexOf("https://") === 0 ? "lock" : "globe"))
            color: b.curPriv ? "#C5A8FF" : G.subtext
        }
        TextInput {
            id: urlInput
            anchors.left: lockIco.right; anchors.leftMargin: 10
            anchors.right: starB.left; anchors.rightMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            color: G.text
            font.pixelSize: 14
            clip: true
            selectByMouse: true
            selectionColor: Qt.rgba(G.accent.r, G.accent.g, G.accent.b, 0.55)
            selectedTextColor: G.text
            horizontalAlignment: activeFocus || text === "" ? TextInput.AlignLeft : TextInput.AlignHCenter
            text: G.prettyUrl(b.curUrl)
            onActiveFocusChanged: {
                if (activeFocus) { text = b.curUrl; selectAll(); b.searchText = "" }
                else { text = Qt.binding(function () { return G.prettyUrl(b.curUrl) }); b.searchText = "" }
            }
            onTextEdited: b.searchText = text
            Keys.onDownPressed: b.searchMove(1)
            Keys.onUpPressed: b.searchMove(-1)
            Keys.onEscapePressed: b.focusPage()
            Keys.onReturnPressed: function (e) { b.submitInput(text, (e.modifiers & Qt.AltModifier) !== 0) }
            Keys.onEnterPressed: function (e) { b.submitInput(text, (e.modifiers & Qt.AltModifier) !== 0) }
            Keys.onTabPressed: b.searchComplete()
        }
        Text {
            anchors.fill: urlInput
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: urlInput.activeFocus ? Text.AlignLeft : Text.AlignHCenter
            text: G.t("Keress vagy írj be egy címet", "Search or enter address")
            color: G.subtext; font.pixelSize: 14
            visible: urlInput.text === ""
        }
        GlassButton {
            id: starB
            anchors.right: parent.right; anchors.rightMargin: 2
            anchors.verticalCenter: parent.verticalCenter
            width: 34; height: 34
            visible: b.curUrl !== ""
            icon: "star"; iconSize: 16
            tone: b.curBookmarked ? "#FFC94D" : G.subtext
            tip: G.t("Könyvjelző (Ctrl+D)", "Bookmark (Ctrl+D)")
            onClicked: b.toggleBookmark()
        }
        // töltési csík
        Rectangle {
            anchors.bottom: parent.bottom; anchors.bottomMargin: 1
            x: parent.radius * 0.6
            height: 2.5; radius: 1.25
            width: (parent.width - parent.radius * 1.2) * b.curProgress
            color: G.accent
            opacity: b.curLoading ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: G.dur(400) } }
            Behavior on width { NumberAnimation { duration: G.dur(260); easing.type: Easing.OutCubic } }
        }
    }
}
