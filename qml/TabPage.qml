import QtQuick
import QtWebEngine
import "Js.js" as Js

// Egy lap: Chromium nézet (a teljes ablak alatt, a lebegő sáv alá görgethető tartalommal),
// új / üres lapon a kezdőlap.
Item {
    id: page
    required property int index
    required property string uid
    required property string url
    required property bool priv
    property var b
    readonly property bool isCurrent: index === b.currentIndex
    property real topInset: b.contentInset
    readonly property alias view: web
    readonly property bool started: web.opened
    property real pageZoom: 1.0
    property bool injectedTransparent: false
    property bool deferred: false
    property string pendingUrl: ""

    opacity: isCurrent ? 1 : 0
    visible: opacity > 0.001
    Behavior on opacity { NumberAnimation { duration: G.dur(170); easing.type: Easing.OutCubic } }

    function setP(k, v) {
        if (index >= 0 && index < b.tabsModel.count) b.tabsModel.setProperty(index, k, v)
    }
    function load(u) {
        if (!u) return
        web.opened = true
        web.url = u
        if (isCurrent) web.forceActiveFocus()
    }
    function showStart() { web.opened = false; setP("title", ""); setP("icon", ""); setP("url", "") }
    function inject() {
        if (!web.opened) return
        web.runJavaScript(Js.topPadJs(page.topInset))
        if (G.s.transparentPages || injectedTransparent)
            web.runJavaScript(Js.transparentCss(G.s.transparentPages, G.s.pageOpacity, G.dark))
        injectedTransparent = G.s.transparentPages
        if (G.s.adblock) web.runJavaScript(Js.adCss)
    }

    Component.onCompleted: {
        if (url === "") return
        if (deferred) pendingUrl = url      // visszaállított háttérlap: csak megnyitáskor töltődik be
        else load(url)
    }
    onIsCurrentChanged: if (isCurrent && pendingUrl !== "") { var u = pendingUrl; pendingUrl = ""; load(u) }
    onTopInsetChanged: inject()
    Connections {
        target: G.s
        function onTransparentPagesChanged() { page.inject() }
        function onPageOpacityChanged() { page.inject() }
        function onToneChanged() { page.inject() }
    }
    Timer { id: injectSoon; interval: 120; onTriggered: page.inject() }
    Timer { id: injectLate; interval: 900; onTriggered: page.inject() }
    Timer { id: reloadLater; interval: 600; onTriggered: web.reload() }

    WebEngineView {
        id: web
        anchors.fill: parent
        property bool opened: false
        visible: opened
        profile: page.priv ? Backend.privateProfile : Backend.normalProfile
        backgroundColor: G.s.transparentPages ? "transparent" : (G.dark ? "#15171d" : "#ffffff")
        zoomFactor: page.pageZoom
        settings.forceDarkMode: G.s.forceDark
        settings.scrollAnimatorEnabled: true
        settings.fullScreenSupportEnabled: true
        settings.playbackRequiresUserGesture: false
        settings.focusOnNavigationEnabled: true
        settings.screenCaptureEnabled: true
        settings.javascriptCanAccessClipboard: true
        settings.pdfViewerEnabled: true
        settings.dnsPrefetchEnabled: true

        onTitleChanged: {
            page.setP("title", title)
            if (!page.priv && !loading && title !== "") G.addHistory(url.toString(), title)
        }
        onIconChanged: page.setP("icon", icon.toString())
        onUrlChanged: {
            var u = url.toString()
            page.setP("url", u)
            page.pageZoom = G.zoomFor(u)
        }
        onLoadingChanged: function (info) {
            page.setP("loading", loading)
            if (info.status === 0) {           // elindult
                opened = true
                injectSoon.restart()
            } else if (info.status === 2) {    // kész
                page.inject()
                injectLate.restart()
                if (!page.priv) G.addHistory(url.toString(), title)
            }
        }
        onLoadProgressChanged: {
            page.setP("progress", loadProgress / 100)
            if (loadProgress > 15 && !injectSoon.running) injectSoon.start()
        }
        onNewWindowRequested: function (request) { page.b.handleNewWindow(page, request) }
        onContextMenuRequested: function (request) { request.accepted = true; page.b.showContextMenu(page, request) }
        onFullScreenRequested: function (request) { request.accept(); page.b.setVideoFullScreen(request.toggleOn) }
        onPermissionRequested: function (permission) { page.b.askPermission(page, permission) }
        onFindTextFinished: function (result) { page.b.findResult(page, result) }
        onLinkHovered: function (hoveredUrl) { if (page.isCurrent) page.b.hoverUrl = hoveredUrl.toString() }
        onRenderProcessTerminated: function (status, code) { if (status !== 0) reloadLater.start() }
        onRecentlyAudibleChanged: page.setP("audible", recentlyAudible)
    }

    StartPage {
        anchors.fill: parent
        visible: !web.opened
        b: page.b
        topInset: page.topInset
        active: page.isCurrent && !web.opened
    }
}
