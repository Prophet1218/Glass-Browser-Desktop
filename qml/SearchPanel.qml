import QtQuick

// A címsáv alá lenyíló javaslatok: keresés, könyvjelzők, előzmények, Google javaslatok.
Item {
    id: panel
    property var b
    property Item source: null
    property bool open: false
    property string query: ""
    property var suggestions: []
    property var items: []
    property int sel: -1
    height: Math.min(list.contentHeight + 16, 460)
    visible: fade > 0.01
    property real fade: open && items.length > 0 ? 1 : 0
    Behavior on fade { NumberAnimation { duration: G.dur(160); easing.type: Easing.OutCubic } }
    opacity: fade
    transform: Translate { y: (1 - panel.fade) * -10 }

    onQueryChanged: { sel = -1; rebuild(); if (query.trim() !== "") suggestTimer.restart(); else suggestions = [] }
    onOpenChanged: { if (open) { sel = -1; rebuild() } }

    function move(d) {
        if (items.length === 0) return
        sel = Math.max(-1, Math.min(items.length - 1, sel + d))
        if (sel >= 0) list.positionViewAtIndex(sel, ListView.Contain)
    }
    function selected() { return sel >= 0 && sel < items.length ? items[sel] : null }
    function completion() {
        var q = query.trim().toLowerCase()
        if (q === "") return ""
        for (var i = 0; i < items.length; i++) {
            var it = items[i]
            if (it.url) { var p = G.prettyUrl(it.url); if (p.toLowerCase().indexOf(q) === 0) return p }
        }
        return ""
    }

    function rebuild() {
        var q = query.trim()
        var ql = q.toLowerCase()
        var out = []
        var seen = {}
        if (q === "") {
            var fr = G.frequentSites(4)
            for (var f = 0; f < fr.length; f++) { out.push({ type: "history", text: fr[f].host, url: fr[f].url, sub: "" }); seen[fr[f].url] = true }
            var h0 = G.historyList
            for (var j = 0; j < h0.length && out.length < 8; j++) {
                if (seen[h0[j].url]) continue
                seen[h0[j].url] = true
                out.push({ type: "history", text: h0[j].title || G.prettyUrl(h0[j].url), url: h0[j].url, sub: G.prettyUrl(h0[j].url) })
            }
            items = out
            return
        }
        var resolved = G.resolveInput(q)
        var isUrl = resolved.indexOf(G.searchUrl("")) !== 0
        if (isUrl) out.push({ type: "url", text: G.prettyUrl(resolved), url: resolved, sub: G.t("Ugrás", "Go to") })
        out.push({ type: "search", text: q, url: G.searchUrl(q), sub: G.t("Keresés", "Search") })
        var bm = G.bookmarkList
        for (var k = 0; k < bm.length && out.length < 5; k++) {
            if ((bm[k].title || "").toLowerCase().indexOf(ql) >= 0 || bm[k].url.toLowerCase().indexOf(ql) >= 0) {
                seen[bm[k].url] = true
                out.push({ type: "bookmark", text: bm[k].title || G.prettyUrl(bm[k].url), url: bm[k].url, sub: G.prettyUrl(bm[k].url) })
            }
        }
        var hl = G.historyList
        var nh = 0
        for (var m = 0; m < hl.length && nh < 4; m++) {
            if (seen[hl[m].url]) continue
            if ((hl[m].title || "").toLowerCase().indexOf(ql) >= 0 || hl[m].url.toLowerCase().indexOf(ql) >= 0) {
                seen[hl[m].url] = true; nh++
                out.push({ type: "history", text: hl[m].title || G.prettyUrl(hl[m].url), url: hl[m].url, sub: G.prettyUrl(hl[m].url) })
            }
        }
        for (var s = 0; s < suggestions.length && s < 6; s++) {
            if (suggestions[s].toLowerCase() === ql) continue
            out.push({ type: "suggest", text: suggestions[s], url: G.searchUrl(suggestions[s]), sub: "" })
        }
        items = out
    }

    Timer {
        id: suggestTimer
        interval: 110
        onTriggered: {
            if (!G.s.suggestions || panel.b.curPriv) return
            var q = panel.query.trim()
            if (q === "") return
            var xhr = new XMLHttpRequest()
            xhr.onreadystatechange = function () {
                if (xhr.readyState !== XMLHttpRequest.DONE || xhr.status !== 200) return
                if (panel.query.trim() !== q) return
                try {
                    var arr = JSON.parse(xhr.responseText)
                    panel.suggestions = arr[1] || []
                    panel.rebuild()
                } catch (e) {}
            }
            xhr.open("GET", "https://suggestqueries.google.com/complete/search?client=firefox&hl=" + (G.en ? "en" : "hu") + "&q=" + encodeURIComponent(q))
            xhr.send()
        }
    }

    Glass { anchors.fill: parent; source: panel.source; radius: 22; tintAlpha: G.dark ? 0.5 : 0.58 }
    ListView {
        id: list
        anchors.fill: parent; anchors.margins: 8
        clip: true
        interactive: contentHeight > height
        model: panel.items
        boundsBehavior: Flickable.StopAtBounds
        delegate: Rectangle {
            required property var modelData
            required property int index
            width: list.width; height: 44; radius: 14
            color: index === panel.sel ? Qt.rgba(G.accent.r, G.accent.g, G.accent.b, 0.28) : (ima.containsMouse ? G.hover : "transparent")
            Behavior on color { ColorAnimation { duration: G.dur(110) } }
            Item {
                id: ic
                x: 12; width: 20; height: 20; anchors.verticalCenter: parent.verticalCenter
                Image {
                    id: fav
                    anchors.fill: parent; anchors.margins: 1
                    readonly property bool site: modelData.type === "history" || modelData.type === "bookmark" || modelData.type === "url"
                    visible: site && status === Image.Ready
                    source: site ? G.faviconUrl(modelData.url) : ""
                    sourceSize: Qt.size(32, 32); asynchronous: true
                }
                Ico {
                    anchors.centerIn: parent; size: 17
                    visible: !fav.visible
                    name: modelData.type === "search" || modelData.type === "suggest" ? "search" : (modelData.type === "bookmark" ? "star" : (modelData.type === "url" ? "globe" : "history"))
                    color: G.subtext
                }
            }
            Text {
                id: t1
                x: 44; anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth, parent.width - 60 - (t2.visible ? 140 : 0))
                text: modelData.text; color: G.text; font.pixelSize: 14; elide: Text.ElideRight
            }
            Text {
                id: t2
                visible: modelData.sub !== ""
                anchors.left: t1.right; anchors.leftMargin: 10; anchors.right: parent.right; anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                text: "— " + modelData.sub; color: G.subtext; font.pixelSize: 13; elide: Text.ElideRight
            }
            MouseArea {
                id: ima; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                onClicked: function (m) { panel.b.openSuggestion(modelData, m.button === Qt.MiddleButton) }
            }
        }
    }
}
