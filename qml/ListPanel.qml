import QtQuick

// Előzmények és könyvjelzők (kereshető lista).
SidePanel {
    id: lp
    property var b
    property string mode: "history"      // "history" | "bookmarks"
    property string filter: ""
    title: mode === "history" ? G.t("Előzmények", "History") : G.t("Könyvjelzők", "Bookmarks")
    tools: [
        GlassButton {
            icon: lp.mode === "history" ? "star" : "history"
            tip: lp.mode === "history" ? G.t("Könyvjelzők", "Bookmarks") : G.t("Előzmények", "History")
            onClicked: lp.mode = lp.mode === "history" ? "bookmarks" : "history"
        },
        GlassButton {
            visible: lp.mode === "history"
            icon: "trash"; tip: G.t("Előzmények törlése", "Clear history")
            onClicked: lp.b.prompt.ask({ title: G.t("Törlöd az összes előzményt?", "Clear all history?"), okText: G.t("Törlés", "Clear"), onOk: function () { G.clearHistory() } })
        }
    ]
    onOpenChanged: if (open) { search.text = ""; search.forceActiveFocus() }

    readonly property var rows: {
        var src = mode === "history" ? G.historyList : G.bookmarkList
        var f = filter.trim().toLowerCase()
        var out = []
        var lastDay = ""
        for (var i = 0; i < src.length && out.length < 600; i++) {
            var it = src[i]
            if (f !== "" && (it.title || "").toLowerCase().indexOf(f) < 0 && it.url.toLowerCase().indexOf(f) < 0) continue
            if (mode === "history") {
                var d = new Date(it.t)
                var day = d.toLocaleDateString(Qt.locale(G.en ? "en_US" : "hu_HU"), "yyyy. MMMM d., dddd")
                if (day !== lastDay) { out.push({ header: true, text: day }); lastDay = day }
            }
            out.push({ header: false, url: it.url, title: it.title || G.prettyUrl(it.url), t: it.t })
        }
        return out
    }

    Rectangle {
        id: sbox
        width: parent.width; height: 40; radius: 20
        color: G.dark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.06)
        border.color: search.activeFocus ? G.accent : G.line
        Ico { name: "search"; size: 15; x: 14; anchors.verticalCenter: parent.verticalCenter; color: G.subtext }
        TextInput {
            id: search
            x: 40; width: parent.width - 54
            anchors.verticalCenter: parent.verticalCenter
            color: G.text; font.pixelSize: 14; clip: true; selectByMouse: true
            onTextChanged: lp.filter = text
            Keys.onEscapePressed: lp.open = false
            Text { anchors.fill: parent; text: G.t("Keresés", "Search"); color: G.subtext; font.pixelSize: 14; visible: parent.text === "" }
        }
    }
    Text {
        anchors.centerIn: parent
        visible: lp.rows.length === 0
        text: lp.mode === "history" ? G.t("Nincsenek előzmények", "No history") : G.t("Nincsenek könyvjelzők", "No bookmarks")
        color: G.subtext; font.pixelSize: 14
    }
    ListView {
        anchors.fill: parent; anchors.topMargin: 50
        clip: true
        model: lp.rows
        boundsBehavior: Flickable.StopAtBounds
        reuseItems: true
        delegate: Item {
            id: r
            required property var modelData
            width: ListView.view.width
            height: modelData.header ? 34 : 50
            Text {
                visible: r.modelData.header
                x: 8; anchors.bottom: parent.bottom; anchors.bottomMargin: 6
                text: r.modelData.header ? r.modelData.text : ""
                color: G.accent; font.pixelSize: 12; font.weight: Font.Bold
            }
            Rectangle {
                visible: !r.modelData.header
                anchors.fill: parent; anchors.topMargin: 2; anchors.bottomMargin: 2
                radius: 14
                color: hm.containsMouse ? G.hover : "transparent"
                Image {
                    id: hf
                    x: 12; width: 18; height: 18; anchors.verticalCenter: parent.verticalCenter
                    source: r.modelData.header ? "" : G.faviconUrl(r.modelData.url)
                    sourceSize: Qt.size(32, 32); asynchronous: true
                }
                Column {
                    x: 42; width: parent.width - 42 - 50
                    anchors.verticalCenter: parent.verticalCenter
                    Text { width: parent.width; text: r.modelData.title || ""; color: G.text; font.pixelSize: 13.5; elide: Text.ElideRight }
                    Text {
                        width: parent.width; elide: Text.ElideRight; color: G.subtext; font.pixelSize: 11.5
                        text: r.modelData.header ? "" : (lp.mode === "history" ? Qt.formatTime(new Date(r.modelData.t), "HH:mm") + "  ·  " : "") + G.prettyUrl(r.modelData.url)
                    }
                }
                MouseArea {
                    id: hm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                    onClicked: function (m) {
                        if (m.button === Qt.MiddleButton) lp.b.newTab(r.modelData.url, false, true)
                        else { lp.b.navigate(r.modelData.url); lp.open = false }
                    }
                }
                GlassButton {
                    anchors.right: parent.right; anchors.rightMargin: 6; anchors.verticalCenter: parent.verticalCenter
                    width: 32; height: 32; icon: "close"; iconSize: 14
                    opacity: hm.containsMouse ? 1 : 0.3
                    onClicked: {
                        if (lp.mode === "history") G.removeHistory(r.modelData.url)
                        else G.toggleBookmark(r.modelData.url, "")
                    }
                }
            }
        }
    }
}
