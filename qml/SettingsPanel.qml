import QtQuick

// Beállítások: megjelenés (téma, szín, üveg, átlátszóság), keresés, adatvédelem, Google, általános.
SidePanel {
    id: sp
    property var b
    title: G.t("Beállítások", "Settings")

    Flickable {
        anchors.fill: parent
        contentHeight: col.implicitHeight + 20
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        Column {
            id: col
            width: parent.width - 20
            x: 10
            spacing: 4

            Header { text: G.t("Megjelenés", "Appearance") }
            GChoice {
                text: G.t("Téma", "Theme")
                options: [{ key: "dark", label: G.t("Sötét", "Dark") }, { key: "light", label: G.t("Világos", "Light") }]
                current: G.s.tone
                onPicked: function (k) { G.s.tone = k }
            }
            Item {
                width: parent.width; height: 74
                Text { text: G.t("Kiemelőszín", "Accent color"); color: G.text; font.pixelSize: 14; y: 6 }
                Row {
                    y: 34; spacing: 10
                    Repeater {
                        model: ["#6EA8FF", "#8E7CFF", "#C084FC", "#FF6FAE", "#FF7A59", "#FFC94D", "#4ADE80", "#2DD4BF", "#A3ADC2"]
                        Rectangle {
                            required property string modelData
                            width: 30; height: 30; radius: 15
                            color: modelData
                            border.width: G.s.accent.toLowerCase() === modelData.toLowerCase() ? 3 : 1
                            border.color: G.s.accent.toLowerCase() === modelData.toLowerCase() ? G.text : Qt.rgba(1, 1, 1, 0.35)
                            scale: am.pressed ? 0.85 : (am.containsMouse ? 1.12 : 1)
                            Behavior on scale { SpringAnimation { spring: 5; damping: 0.3; epsilon: 0.002 } }
                            MouseArea { id: am; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: G.s.accent = modelData }
                        }
                    }
                }
            }
            GSlider { text: G.t("Üveg elmosás", "Glass blur"); from: 0; to: 40; step: 1; value: G.s.glassBlur; onMoved: function (v) { G.s.glassBlur = v } }
            GSlider { text: G.t("Fénytörés", "Refraction"); from: 0; to: 1.5; step: 0.05; value: G.s.refraction; decimals: 0; displayFactor: 100; suffix: "%"; onMoved: function (v) { G.s.refraction = v } }
            GSlider { text: G.t("Animáció sebesség", "Animation speed"); from: 0.5; to: 2.5; step: 0.05; value: G.s.animSpeed; decimals: 2; suffix: "×"; onMoved: function (v) { G.s.animSpeed = v } }
            GSwitch { text: G.t("Színes kezdőlap háttér", "Colorful start page"); checked: G.s.startBlobs; onToggled: function (on) { G.s.startBlobs = on } }

            Header { text: G.t("Átlátszóság", "Transparency") }
            GSlider {
                text: G.t("Böngésző háttér fedettsége", "Browser background opacity")
                from: 0; to: 1; step: 0.01; value: G.s.windowOpacity; displayFactor: 100; suffix: "%"
                onMoved: function (v) { G.s.windowOpacity = v }
            }
            GSwitch {
                text: G.t("Asztal elmosása az ablak mögött", "Blur desktop behind window")
                sub: Backend.blurAvailable ? G.t("KDE Plasma (KWin) elmosás", "KDE Plasma (KWin) blur") : G.t("Nem érhető el ezen a rendszeren", "Not available on this system")
                checked: G.s.blurBehind
                onToggled: function (on) { G.s.blurBehind = on }
            }
            GSwitch {
                text: G.t("Átlátszó weboldalak", "Transparent web pages")
                sub: G.t("A weboldalak háttere eltűnik, alatta az üveges ablak látszik (mint a Zen böngészőben)", "Page backgrounds disappear and the glass window shows through (like Zen browser)")
                checked: G.s.transparentPages
                onToggled: function (on) { G.s.transparentPages = on }
            }
            GSlider {
                visible: G.s.transparentPages
                text: G.t("Weboldal háttér fedettsége", "Page background opacity")
                from: 0; to: 0.9; step: 0.01; value: G.s.pageOpacity; displayFactor: 100; suffix: "%"
                onMoved: function (v) { G.s.pageOpacity = v }
            }

            Header { text: G.t("Keresés", "Search") }
            GChoice {
                options: [{ key: "google", label: "Google" }, { key: "duckduckgo", label: "DuckDuckGo" }, { key: "bing", label: "Bing" }, { key: "brave", label: "Brave" }, { key: "startpage", label: "Startpage" }]
                current: G.s.searchEngine
                onPicked: function (k) { G.s.searchEngine = k }
            }
            GSwitch { text: G.t("Keresési javaslatok", "Search suggestions"); checked: G.s.suggestions; onToggled: function (on) { G.s.suggestions = on } }

            Header { text: G.t("Adatvédelem és tartalom", "Privacy and content") }
            GSwitch {
                text: G.t("Reklám- és nyomkövetőszűrő", "Ad and tracker blocker")
                sub: G.t("Eddig letiltva: ", "Blocked so far: ") + sp.blocked
                checked: G.s.adblock
                onToggled: function (on) { G.s.adblock = on }
            }
            GSwitch {
                text: G.t("Sötét weboldalak kényszerítése", "Force dark web pages")
                checked: G.s.forceDark
                onToggled: function (on) { G.s.forceDark = on }
            }
            Flow {
                width: parent.width; spacing: 8
                topPadding: 6; bottomPadding: 6
                GlassButton { text: G.t("Előzmények törlése", "Clear history"); onClicked: { G.clearHistory(); sp.b.toast(G.t("Előzmények törölve", "History cleared")) } }
                GlassButton { text: G.t("Sütik törlése", "Clear cookies"); onClicked: { Backend.clearCookies(); sp.b.toast(G.t("Sütik törölve", "Cookies cleared")) } }
                GlassButton { text: G.t("Gyorsítótár ürítése", "Clear cache"); onClicked: { Backend.clearCache(); sp.b.toast(G.t("Gyorsítótár kiürítve", "Cache cleared")) } }
            }

            Header { text: "Google" }
            Flow {
                width: parent.width; spacing: 8
                bottomPadding: 6
                GlassButton { icon: "user"; text: G.t("Google fiók", "Google account"); onClicked: { sp.b.newTab("https://myaccount.google.com", false); sp.open = false } }
                GlassButton { icon: "key"; text: G.t("Jelszavak", "Passwords"); onClicked: { sp.b.newTab("https://passwords.google.com", false); sp.open = false } }
                GlassButton { icon: "history"; text: G.t("Tevékenységeim", "My Activity"); onClicked: { sp.b.newTab("https://myactivity.google.com", false); sp.open = false } }
                GlassButton { icon: "shield"; text: G.t("Biztonság", "Security"); onClicked: { sp.b.newTab("https://myaccount.google.com/security", false); sp.open = false } }
            }

            Header { text: G.t("Általános", "General") }
            GSwitch { text: G.t("Lapok visszaállítása induláskor", "Restore tabs on startup"); checked: G.s.restoreSession; onToggled: function (on) { G.s.restoreSession = on } }
            GChoice {
                text: G.t("Nyelv", "Language")
                options: [{ key: "", label: G.t("Rendszer", "System") }, { key: "hu", label: "Magyar" }, { key: "en", label: "English" }]
                current: G.s.language
                onPicked: function (k) { G.s.language = k }
            }
            Item { width: 1; height: 12 }
            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: "Glass Browser " + Backend.version + "  ·  Chromium (Qt WebEngine)"
                color: G.subtext; font.pixelSize: 12
            }
        }
    }

    property int blocked: 0
    Timer { interval: 1500; repeat: true; running: sp.open; triggeredOnStart: true; onTriggered: sp.blocked = Backend.blockedCount() }

    component Header: Text {
        topPadding: 16; bottomPadding: 4
        color: G.accent
        font.pixelSize: 12.5; font.weight: Font.Bold
        font.capitalization: Font.AllUppercase
        font.letterSpacing: 0.8
    }
}
