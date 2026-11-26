pragma Singleton
import QtQuick
import QtCore

// Közös állapot: beállítások, nyelv, színek, időzítések, mentett listák.
QtObject {
    id: g

    property Settings s: Settings {
        category: "general"
        property string language: ""
        property real glassBlur: 22
        property real refraction: 0.75
        property real windowOpacity: 0.62
        property bool transparentPages: false
        property real pageOpacity: 0.0
        property bool blurBehind: true
        property real animSpeed: 1.25
        property string searchEngine: "google"
        property bool suggestions: true
        property bool adblock: true
        property bool forceDark: false
        property string tone: "dark"
        property string accent: "#6EA8FF"
        property string closeAnim: "fade"
        property string tiles: ""
        property string history: "[]"
        property string bookmarks: "[]"
        property string session: "[]"
        property int sessionIndex: 0
        property string zooms: "{}"
        property bool restoreSession: true
        property string homeUrl: ""
        property bool startBlobs: true
        property string downloads: "[]"
    }

    // ---- nyelv
    readonly property bool en: (s.language !== "" ? s.language : (Backend.systemLanguage === "hu" ? "hu" : "en")) === "en"
    function t(hu, enText) { return en ? enText : hu }

    // ---- időzítés (az animáció sebesség csúszka szerint)
    function dur(ms) { return Math.round(ms / Math.max(0.3, s.animSpeed)) }

    // ---- színek
    readonly property bool dark: s.tone !== "light"
    readonly property color text: dark ? "#F1F4FB" : "#151A26"
    readonly property color subtext: dark ? "#A9B3C7" : "#4D5568"
    readonly property color tintColor: dark ? Qt.rgba(0.07, 0.09, 0.15, 1) : Qt.rgba(0.95, 0.96, 0.99, 1)
    readonly property color windowTint: dark ? Qt.rgba(0.05, 0.065, 0.11, s.windowOpacity) : Qt.rgba(0.93, 0.95, 0.98, s.windowOpacity)
    readonly property color accent: s.accent
    readonly property color hover: dark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.07)
    readonly property color line: dark ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(0, 0, 0, 0.10)

    // ---- keresés
    function searchUrl(q) {
        var e = encodeURIComponent(q)
        switch (s.searchEngine) {
        case "duckduckgo": return "https://duckduckgo.com/?q=" + e
        case "bing": return "https://www.bing.com/search?q=" + e
        case "brave": return "https://search.brave.com/search?q=" + e
        case "startpage": return "https://www.startpage.com/do/search?q=" + e
        default: return "https://www.google.com/search?q=" + e
        }
    }
    function resolveInput(raw) {
        var t = raw.trim()
        if (t === "") return ""
        if (/^[a-z]+:\/\//i.test(t) || t.startsWith("about:") || t.startsWith("file:")) return t
        if (/^localhost(:\d+)?(\/.*)?$/i.test(t)) return "http://" + t
        if (!/\s/.test(t) && /^[^\s]+\.[a-z]{2,}(:\d+)?(\/.*)?$/i.test(t)) return "https://" + t
        if (/^\d{1,3}(\.\d{1,3}){3}(:\d+)?(\/.*)?$/.test(t)) return "http://" + t
        return searchUrl(t)
    }
    function hostOf(u) {
        var m = /^[a-z]+:\/\/([^\/:?#]+)/i.exec(u || "")
        return m ? m[1].replace(/^www\./, "") : ""
    }
    function prettyUrl(u) {
        if (!u || u === "about:blank") return ""
        return u.replace(/^https?:\/\//, "").replace(/^www\./, "").replace(/\/$/, "")
    }
    function faviconUrl(u) {
        var h = hostOf(u)
        return h ? "https://www.google.com/s2/favicons?domain=" + h + "&sz=64" : ""
    }

    // ---- előzmények, könyvjelzők (JSON a beállításokban)
    property var historyList: JSON.parse(s.history || "[]")
    property var bookmarkList: JSON.parse(s.bookmarks || "[]")

    function addHistory(url, title) {
        if (!url || url.startsWith("about:") || url.startsWith("data:")) return
        var list = historyList.slice()
        var now = Date.now()
        var found = -1
        for (var i = 0; i < Math.min(list.length, 400); i++) if (list[i].url === url) { found = i; break }
        var visits = 1
        if (found >= 0) {
            visits = (list[found].n || 1) + ((now - list[found].t) > 60000 ? 1 : 0)
            if (!title) title = list[found].title
            list.splice(found, 1)
        }
        list.unshift({ url: url, title: title || "", t: now, n: visits })
        if (list.length > 3000) list.length = 3000
        historyList = list
        saveHistoryLater.restart()
    }
    function removeHistory(url) {
        historyList = historyList.filter(function (h) { return h.url !== url })
        s.history = JSON.stringify(historyList)
    }
    function clearHistory() { historyList = []; s.history = "[]" }
    property Timer saveHistoryLater: Timer { interval: 1500; onTriggered: g.s.history = JSON.stringify(g.historyList) }

    function isBookmarked(url) {
        for (var i = 0; i < bookmarkList.length; i++) if (bookmarkList[i].url === url) return true
        return false
    }
    function toggleBookmark(url, title) {
        if (!url) return false
        var on = isBookmarked(url)
        if (on) bookmarkList = bookmarkList.filter(function (b) { return b.url !== url })
        else bookmarkList = [{ url: url, title: title || g.prettyUrl(url), t: Date.now() }].concat(bookmarkList)
        s.bookmarks = JSON.stringify(bookmarkList)
        return !on
    }

    // gyakran látogatott webhelyek
    function frequentSites(limit) {
        var map = {}
        for (var i = 0; i < historyList.length; i++) {
            var h = historyList[i]
            var host = hostOf(h.url)
            if (!host) continue
            if (!map[host]) map[host] = { host: host, url: "https://" + host, title: host, n: 0 }
            map[host].n += (h.n || 1)
        }
        var arr = Object.keys(map).map(function (k) { return map[k] })
        arr.sort(function (a, b) { return b.n - a.n })
        return arr.slice(0, limit)
    }

    // ---- kezdőlap csempék
    readonly property var defaultTiles: [
        { title: "Google", url: "https://www.google.com" },
        { title: "YouTube", url: "https://www.youtube.com" },
        { title: "Reddit", url: "https://www.reddit.com" },
        { title: "GitHub", url: "https://github.com" },
        { title: "Gmail", url: "https://mail.google.com" },
        { title: "Wikipedia", url: "https://www.wikipedia.org" },
        { title: "Twitch", url: "https://www.twitch.tv" },
        { title: "Netflix", url: "https://www.netflix.com" }
    ]
    property var tileList: s.tiles ? JSON.parse(s.tiles) : defaultTiles
    function saveTiles(list) { tileList = list; s.tiles = JSON.stringify(list) }

    // ---- oldalankénti nagyítás
    property var zoomMap: JSON.parse(s.zooms || "{}")
    function zoomFor(url) { var h = hostOf(url); return (h && zoomMap[h]) ? zoomMap[h] : 1.0 }
    function setZoom(url, z) {
        var h = hostOf(url); if (!h) return
        var m = Object.assign({}, zoomMap)
        if (Math.abs(z - 1.0) < 0.01) delete m[h]; else m[h] = z
        zoomMap = m; s.zooms = JSON.stringify(m)
    }
}
