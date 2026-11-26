import QtQuick
import QtQuick.Shapes

// Kezdőlap: lassan úszó színfoltok (az üveg ezeket töri meg), óra, keresőkapszula,
// szerkeszthető csempék és a gyakran látogatott oldalak.
Item {
    id: sp
    property var b
    property real topInset: 0
    property bool active: false

    // ---- háttér színfoltok (átlátszó ablaknál az asztal is átdereng)
    Item {
        id: wall
        anchors.fill: parent
        visible: G.s.startBlobs
        Blob { pw: sp.width; phh: sp.height; t: sp.time; size: sp.width * 0.55; col: Qt.rgba(G.accent.r, G.accent.g, G.accent.b, 0.55); bx: 0.12; by: 0.22; ph: 0 }
        Blob { pw: sp.width; phh: sp.height; t: sp.time; size: sp.width * 0.48; col: Qt.rgba(0.62, 0.38, 1.0, 0.45); bx: 0.78; by: 0.30; ph: 2.1 }
        Blob { pw: sp.width; phh: sp.height; t: sp.time; size: sp.width * 0.50; col: Qt.rgba(0.20, 0.85, 0.80, 0.32); bx: 0.50; by: 0.86; ph: 4.2 }
        Blob { pw: sp.width; phh: sp.height; t: sp.time; size: sp.width * 0.32; col: Qt.rgba(1.0, 0.55, 0.45, 0.28); bx: 0.92; by: 0.92; ph: 1.3 }
    }
    property real time: 0
    FrameAnimation { running: sp.active && G.s.startBlobs; onTriggered: sp.time += frameTime * 0.18 * G.s.animSpeed }

    component Blob: Shape {
        id: bl
        property real size: 400
        property color col: "white"
        property real bx: 0.5
        property real by: 0.5
        property real ph: 0
        property real pw: 100
        property real phh: 100
        property real t: 0
        width: size; height: size
        x: pw * bx - size / 2 + Math.sin(t + ph) * pw * 0.06
        y: phh * by - size / 2 + Math.cos(t * 0.8 + ph) * phh * 0.07
        preferredRendererType: Shape.GeometryRenderer
        ShapePath {
            strokeColor: "transparent"
            strokeWidth: 0
            fillGradient: RadialGradient {
                centerX: bl.size / 2; centerY: bl.size / 2; centerRadius: bl.size / 2
                focalX: bl.size / 2; focalY: bl.size / 2
                GradientStop { position: 0.0; color: bl.col }
                GradientStop { position: 0.55; color: Qt.rgba(bl.col.r, bl.col.g, bl.col.b, bl.col.a * 0.35) }
                GradientStop { position: 1.0; color: Qt.rgba(bl.col.r, bl.col.g, bl.col.b, 0) }
            }
            PathAngleArc { centerX: bl.size / 2; centerY: bl.size / 2; radiusX: bl.size / 2; radiusY: bl.size / 2; startAngle: 0; sweepAngle: 360 }
        }
    }

    // ---- tartalom
    Flickable {
        anchors.fill: parent
        anchors.topMargin: sp.topInset
        contentHeight: Math.max(height, col.implicitHeight + 80)
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        Column {
            id: col
            width: Math.min(820, sp.width - 60)
            anchors.horizontalCenter: parent.horizontalCenter
            y: Math.max(30, (parent.height - implicitHeight) * 0.38)
            spacing: 22

            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 2
                Text {
                    id: clock
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: G.text
                    font.pixelSize: 76; font.weight: Font.Light
                    text: Qt.formatTime(new Date(), "HH:mm")
                }
                Text {
                    id: dateT
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: G.subtext; font.pixelSize: 15
                    text: new Date().toLocaleDateString(Qt.locale(G.en ? "en_US" : "hu_HU"), "yyyy. MMMM d., dddd")
                }
                Timer {
                    interval: 5000; repeat: true; running: sp.visible
                    onTriggered: { clock.text = Qt.formatTime(new Date(), "HH:mm"); dateT.text = new Date().toLocaleDateString(Qt.locale(G.en ? "en_US" : "hu_HU"), "yyyy. MMMM d., dddd") }
                }
            }

            // keresőkapszula
            Item {
                width: Math.min(620, col.width)
                height: 54
                anchors.horizontalCenter: parent.horizontalCenter
                scale: sma.pressed ? 0.97 : (sma.containsMouse ? 1.015 : 1)
                Behavior on scale { SpringAnimation { spring: 4; damping: 0.32; epsilon: 0.002 } }
                Glass { anchors.fill: parent; source: wall; radius: 27; tintAlpha: G.dark ? 0.32 : 0.40 }
                Ico { name: "search"; x: 20; anchors.verticalCenter: parent.verticalCenter; size: 18; color: G.subtext }
                Text {
                    x: 52; anchors.verticalCenter: parent.verticalCenter
                    text: G.t("Keress a weben vagy írj be egy címet", "Search the web or type an address")
                    color: G.subtext; font.pixelSize: 15
                }
                MouseArea { id: sma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.IBeamCursor; onClicked: sp.b.focusUrlBar() }
            }

            // csempék
            Flow {
                id: tiles
                width: Math.min(col.width, 8 * 98)
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 10
                Repeater {
                    model: G.tileList
                    Tile {
                        required property var modelData
                        required property int index
                        title: modelData.title
                        url: modelData.url
                        glassSource: wall
                        onOpen: function (bg) { if (bg) sp.b.newTab(url, false, true); else sp.b.navigate(url) }
                        onMenu: function (mx, my) {
                            var i = index
                            sp.b.menu.popup(mx, my, [
                                { key: "open", icon: "external", text: G.t("Megnyitás", "Open") },
                                { key: "newtab", icon: "plus", text: G.t("Megnyitás új lapon", "Open in new tab") },
                                { key: "priv", icon: "mask", text: G.t("Megnyitás privát lapon", "Open in private tab") },
                                { sep: true },
                                { key: "edit", icon: "settings", text: G.t("Szerkesztés", "Edit") },
                                { key: "left", icon: "back", text: G.t("Mozgatás balra", "Move left"), enabled: i > 0 },
                                { key: "right", icon: "forward", text: G.t("Mozgatás jobbra", "Move right"), enabled: i < G.tileList.length - 1 },
                                { key: "remove", icon: "trash", text: G.t("Eltávolítás", "Remove"), danger: true }
                            ], function (k) { sp.tileAction(k, i) })
                        }
                    }
                }
                Tile {
                    title: G.t("Hozzáadás", "Add")
                    url: ""
                    adder: true
                    glassSource: wall
                    onOpen: sp.addTile()
                }
            }

            // gyakran látogatott
            Column {
                width: col.width
                spacing: 10
                visible: freq.count > 0
                Text { text: G.t("Gyakran látogatott", "Frequently visited"); color: G.subtext; font.pixelSize: 13; font.weight: Font.DemiBold; anchors.horizontalCenter: parent.horizontalCenter }
                Flow {
                    width: parent.width
                    spacing: 8
                    layoutDirection: Qt.LeftToRight
                    Repeater {
                        id: freq
                        model: sp.visible ? sp.frequent() : []
                        Item {
                            required property var modelData
                            width: fr.implicitWidth + 44; height: 36
                            scale: fma.pressed ? 0.94 : 1
                            Behavior on scale { SpringAnimation { spring: 5; damping: 0.35; epsilon: 0.002 } }
                            Glass { anchors.fill: parent; source: wall; radius: 18; tintAlpha: G.dark ? 0.28 : 0.36 }
                            Rectangle { anchors.fill: parent; radius: 18; color: fma.containsMouse ? G.hover : "transparent" }
                            Image { x: 12; width: 16; height: 16; anchors.verticalCenter: parent.verticalCenter; source: G.faviconUrl(modelData.url); sourceSize: Qt.size(32, 32); asynchronous: true }
                            Text { id: fr; x: 34; anchors.verticalCenter: parent.verticalCenter; text: modelData.host; color: G.text; font.pixelSize: 13 }
                            MouseArea { id: fma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                                onClicked: function (m) { if (m.button === Qt.MiddleButton) sp.b.newTab(modelData.url, false, true); else sp.b.navigate(modelData.url) } }
                        }
                    }
                }
            }
        }
    }

    function frequent() {
        var tileHosts = {}
        for (var i = 0; i < G.tileList.length; i++) tileHosts[G.hostOf(G.tileList[i].url)] = true
        return G.frequentSites(16).filter(function (f) { return !tileHosts[f.host] }).slice(0, 8)
    }

    function tileAction(k, i) {
        var list = G.tileList.slice()
        var t = list[i]
        if (k === "open") b.navigate(t.url)
        else if (k === "newtab") b.newTab(t.url, false)
        else if (k === "priv") b.newTab(t.url, true)
        else if (k === "remove") { list.splice(i, 1); G.saveTiles(list) }
        else if (k === "left" && i > 0) { list.splice(i, 1); list.splice(i - 1, 0, t); G.saveTiles(list) }
        else if (k === "right" && i < list.length - 1) { list.splice(i, 1); list.splice(i + 1, 0, t); G.saveTiles(list) }
        else if (k === "edit") {
            b.prompt.ask({
                title: G.t("Csempe szerkesztése", "Edit tile"),
                field1: t.title, field1Hint: G.t("Név", "Name"),
                field2: t.url, field2Hint: G.t("Cím", "Address"),
                okText: G.t("Mentés", "Save"),
                onOk: function (n, u) {
                    var l = G.tileList.slice()
                    var url = G.resolveInput(u)
                    l[i] = { title: n.trim() !== "" ? n.trim() : G.hostOf(url), url: url }
                    G.saveTiles(l)
                }
            })
        }
    }
    function addTile() {
        var cu = b.curUrl
        b.prompt.ask({
            title: G.t("Új csempe", "New tile"),
            field1: "", field1Hint: G.t("Név (nem kötelező)", "Name (optional)"),
            field2: "", field2Hint: G.t("Cím, pl. youtube.com", "Address, e.g. youtube.com"),
            okText: G.t("Hozzáadás", "Add"),
            onOk: function (n, u) {
                if (u.trim() === "") return
                var url = G.resolveInput(u)
                var l = G.tileList.slice()
                l.push({ title: n.trim() !== "" ? n.trim() : G.hostOf(url), url: url })
                G.saveTiles(l)
            }
        })
    }

    component Tile: Item {
        id: tl
        property string title: ""
        property string url: ""
        property bool adder: false
        property Item glassSource: null
        signal open(bool background)
        signal menu(real x, real y)
        width: 88; height: 98
        Item {
            id: sq
            width: 64; height: 64
            anchors.horizontalCenter: parent.horizontalCenter
            scale: tma.pressed ? 0.88 : (tma.containsMouse ? 1.07 : 1)
            Behavior on scale { SpringAnimation { spring: 5; damping: 0.3; epsilon: 0.002 } }
            Glass { anchors.fill: parent; source: tl.glassSource; radius: 20; tintAlpha: G.dark ? 0.30 : 0.40; press: tma.pressed ? 1 : 0 }
            Image {
                id: tileImg
                anchors.centerIn: parent
                width: 30; height: 30
                visible: !tl.adder && status === Image.Ready
                source: tl.adder ? "" : G.faviconUrl(tl.url)
                sourceSize: Qt.size(64, 64)
                asynchronous: true; smooth: true
            }
            Text {
                anchors.centerIn: parent
                visible: !tl.adder && tileImg.status !== Image.Ready
                text: tl.title.length > 0 ? tl.title.charAt(0).toUpperCase() : "?"
                color: G.text; font.pixelSize: 24; font.weight: Font.DemiBold
            }
            Ico { anchors.centerIn: parent; visible: tl.adder; name: "plus"; size: 24; color: G.subtext }
        }
        Text {
            anchors.top: sq.bottom; anchors.topMargin: 8
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: tl.title
            color: G.text; font.pixelSize: 13
        }
        MouseArea {
            id: tma
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
            onClicked: function (m) {
                if (m.button === Qt.RightButton) { if (!tl.adder) { var p = mapToItem(null, m.x, m.y); tl.menu(p.x, p.y) } }
                else tl.open(m.button === Qt.MiddleButton)
            }
        }
    }
}
