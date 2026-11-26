import QtQuick
import QtQuick.Window
import QtQuick.Effects
import QtWebEngine
import "Js.js" as Js

// Glass Browser asztali változat: keret nélküli, átlátszó ablak; a weboldalak a teljes ablakot
// kitöltik, fölöttük lebeg a folyékony üveg sáv (fénytöréssel), az ablakgombok jobb felül.
Window {
    id: root
    width: 1360
    height: 860
    minimumWidth: 640
    minimumHeight: 420
    visible: true
    color: "transparent"
    flags: Qt.Window | Qt.FramelessWindowHint
    title: (curTitle !== "" ? curTitle + " — " : "") + "Glass Browser"

    readonly property var win: root
    readonly property bool maximized: visibility === Window.Maximized || visibility === Window.FullScreen

    // ---------------------------------------------------------------- lapok
    ListModel { id: tabModel }
    property alias tabsModel: tabModel
    property int currentIndex: 0
    property Item cur: null
    property var closedTabs: []
    property var thumbResults: ({})

    readonly property bool curStarted: cur !== null && cur.started
    readonly property string curUrl: curStarted ? cur.view.url.toString() : ""
    readonly property string curTitle: curStarted ? cur.view.title : ""
    readonly property bool curPriv: cur !== null && cur.priv
    readonly property bool curLoading: curStarted && cur.view.loading
    readonly property real curProgress: curStarted ? cur.view.loadProgress / 100 : 0
    readonly property bool canBack: cur !== null && (curStarted ? cur.view.canGoBack : cur.view.url.toString() !== "")
    readonly property bool canForward: curStarted && cur.view.canGoForward
    readonly property bool curBookmarked: { var l = G.bookmarkList; return curUrl !== "" && G.isBookmarked(curUrl) }

    property bool videoFull: false
    property int prevVisibility: Window.Windowed
    readonly property real barMargin: maximized ? 6 : 8
    readonly property real contentInset: videoFull ? 0 : topBar.y + topBar.height + 4
    property string searchText: ""
    property string hoverUrl: ""

    readonly property Item menu: glassMenu
    readonly property Item prompt: promptDlg

    // ---------------------------------------------------------------- letöltések
    ListModel { id: dlModel }
    property alias downloadsModel: dlModel
    property var dlObjects: ({})
    property bool dlActive: false
    property real dlProgress: 0
    property bool dlUnseen: false

    onCurrentIndexChanged: updateCur()
    function updateCur() {
        var it = (currentIndex >= 0 && currentIndex < pagesRep.count) ? pagesRep.itemAt(currentIndex) : null
        cur = it
        hoverUrl = ""
        if (findBar.open) findBar.hide()
        if (cur) glassMenu.zoomValue = cur.pageZoom
        saveSessionLater.restart()
    }
    function pageAt(i) { return (i >= 0 && i < pagesRep.count) ? pagesRep.itemAt(i) : null }

    function makeUid() { return "t" + Date.now().toString(36) + Math.floor(Math.random() * 1e6).toString(36) }

    // új lap a jelenlegi mögé; visszaadja az indexét
    function insertTab(url, priv, background, title, lazy) {
        var pos = tabsModel.count === 0 ? 0 : currentIndex + 1
        tabsModel.insert(pos, { uid: makeUid(), url: url || "", title: title || "", icon: "", priv: !!priv,
                                loading: false, progress: 0, audible: false, lazy: !!lazy })
        if (!background) { currentIndex = pos; updateCur() }
        return pos
    }
    function newTab(url, priv, background) {
        var p = insertTab(url, priv, background)
        if (!background) {
            if (!url) Qt.callLater(focusUrlBar)
            else Qt.callLater(focusPage)
        } else {
            toast(G.t("Megnyitva a háttérben", "Opened in background"), G.t("Váltás", "Switch"), function () { selectTab(p) })
        }
        return pageAt(p)
    }
    function selectTab(i) {
        if (i < 0 || i >= tabsModel.count) return
        if (i === currentIndex) { overview.open = false; return }
        grabThumb(cur)
        currentIndex = i
        Qt.callLater(focusPage)
    }
    function closeTab(i) {
        if (i < 0 || i >= tabsModel.count) return
        var t = tabsModel.get(i)
        if (t.url !== "" && !t.priv) {
            closedTabs.push({ url: t.url, title: t.title })
            if (closedTabs.length > 25) closedTabs.shift()
        }
        if (tabsModel.count === 1) {
            tabsModel.insert(1, { uid: makeUid(), url: "", title: "", icon: "", priv: false, loading: false, progress: 0, audible: false, lazy: false })
            tabsModel.remove(0)
            currentIndex = 0
            updateCur()
            Qt.callLater(focusUrlBar)
            afterClose()
            return
        }
        var wasCur = i === currentIndex
        tabsModel.remove(i)
        if (i < currentIndex) currentIndex--
        else if (wasCur) currentIndex = Math.min(i, tabsModel.count - 1)
        updateCur()
        afterClose()
    }
    function afterClose() {
        var anyPriv = false
        for (var i = 0; i < tabsModel.count; i++) if (tabsModel.get(i).priv) anyPriv = true
        if (!anyPriv) Backend.resetPrivateProfile()
        saveSessionLater.restart()
    }
    function closeAllTabs() {
        tabsModel.clear()
        overview.thumbs = ({})
        thumbResults = ({})
        insertTab("", false, false)
        afterClose()
        Qt.callLater(focusUrlBar)
    }
    function closeOthers(i) {
        var keep = tabsModel.get(i).uid
        for (var k = tabsModel.count - 1; k >= 0; k--) if (tabsModel.get(k).uid !== keep) tabsModel.remove(k)
        currentIndex = 0; updateCur(); afterClose()
    }
    function closeRight(i) {
        for (var k = tabsModel.count - 1; k > i; k--) tabsModel.remove(k)
        if (currentIndex > i) currentIndex = i
        updateCur(); afterClose()
    }
    function reopenClosed() {
        if (closedTabs.length === 0) return
        var t = closedTabs.pop()
        newTab(t.url, false)
    }
    function duplicateTab(i) {
        var t = tabsModel.get(i)
        selectTab(i)
        newTab(t.url, t.priv)
    }

    function grabThumb(page) {
        if (!page || !page.visible || page.width < 10) return
        var uid = page.uid
        page.grabToImage(function (r) {
            var m = Object.assign({}, overview.thumbs)
            m[uid] = r.url
            var keep = Object.assign({}, thumbResults)
            keep[uid] = r
            thumbResults = keep
            overview.thumbs = m
        }, Qt.size(Math.round(page.width / 2.2), Math.round(page.height / 2.2)))
    }

    // ---------------------------------------------------------------- navigáció
    function navigate(u) {
        if (!u) return
        if (!cur) { newTab(u, false); return }
        cur.load(u)
        overview.open = false
    }
    function submitInput(text, inNewTab) {
        var s = searchPanel.selected()
        var u = s ? s.url : G.resolveInput(text)
        if (!u) return
        if (inNewTab) newTab(u, curPriv)
        else navigate(u)
        focusPage()
    }
    function openSuggestion(item, inNewTab) {
        if (inNewTab) newTab(item.url, curPriv, true)
        else { navigate(item.url); focusPage() }
    }
    function searchMove(d) { searchPanel.move(d) }
    function searchComplete() {
        var c = searchPanel.completion()
        if (c !== "") { topBar.urlInput.text = c; searchText = c; topBar.urlInput.cursorPosition = c.length }
    }
    function focusUrlBar() { topBar.urlInput.forceActiveFocus(); topBar.urlInput.selectAll() }
    function focusPage() {
        if (cur && cur.started) cur.view.forceActiveFocus()
        else keyCatcher.forceActiveFocus()
    }
    function goBack() {
        if (!cur) return
        if (!cur.started && cur.view.url.toString() !== "") { cur.view.opened = true; return }
        if (cur.view.canGoBack) cur.view.goBack()
    }
    function goForward() { if (cur && cur.started) cur.view.goForward() }
    function reload(hard) {
        if (!cur || !cur.started) return
        if (hard) cur.view.reloadAndBypassCache(); else cur.view.reload()
    }
    function stopLoad() { if (cur && cur.started) cur.view.stop() }
    function goHome() {
        if (!cur) return
        if (G.s.homeUrl !== "") navigate(G.s.homeUrl)
        else { cur.view.stop(); cur.showStart() }
    }
    function toggleBookmark() {
        if (curUrl === "") return
        var on = G.toggleBookmark(curUrl, curTitle)
        toast(on ? G.t("Könyvjelző hozzáadva", "Bookmark added") : G.t("Könyvjelző eltávolítva", "Bookmark removed"))
    }
    function translatePage() {
        if (curUrl === "") return
        navigate("https://translate.google.com/translate?sl=auto&tl=" + (G.en ? "en" : "hu") + "&u=" + encodeURIComponent(curUrl))
    }
    function setZoomCur(z) {
        if (!cur || !cur.started) return
        z = Math.max(0.3, Math.min(5, Math.round(z * 100) / 100))
        cur.pageZoom = z
        G.setZoom(curUrl, z)
        glassMenu.zoomValue = z
        if (!glassMenu.open) toast(G.t("Nagyítás: ", "Zoom: ") + Math.round(z * 100) + "%")
    }
    readonly property var zoomSteps: [0.3, 0.5, 0.67, 0.75, 0.8, 0.9, 1.0, 1.1, 1.25, 1.5, 1.75, 2.0, 2.5, 3.0, 4.0, 5.0]
    function zoomStep(d) {
        if (!cur) return
        var z = cur.pageZoom
        var i = 0
        if (d > 0) { for (i = 0; i < zoomSteps.length; i++) if (zoomSteps[i] > z + 0.01) { setZoomCur(zoomSteps[i]); return } }
        else { for (i = zoomSteps.length - 1; i >= 0; i--) if (zoomSteps[i] < z - 0.01) { setZoomCur(zoomSteps[i]); return } }
    }
    function toggleMaximize() { if (visibility === Window.Maximized) showNormal(); else showMaximized() }
    function toggleFullScreen() {
        if (visibility === Window.FullScreen) { if (prevVisibility === Window.Maximized) showMaximized(); else showNormal() }
        else { prevVisibility = visibility; showFullScreen() }
    }
    function setVideoFullScreen(on) {
        videoFull = on
        if (on) { if (visibility !== Window.FullScreen) { prevVisibility = visibility; showFullScreen() } }
        else if (visibility === Window.FullScreen) { if (prevVisibility === Window.Maximized) showMaximized(); else showNormal() }
    }
    function openDevTools() {
        if (!cur || !cur.started) return
        var inspected = cur.view
        var p = newTab("", cur.priv, false)
        if (!p) return
        p.view.opened = true
        inspected.devToolsView = p.view
    }

    // ---------------------------------------------------------------- panelek és menük
    function closeOverlays() {
        var any = glassMenu.open || settingsPanel.open || downloadsPanel.open || listPanel.open || overview.open || findBar.open
        glassMenu.close()
        settingsPanel.open = false; downloadsPanel.open = false; listPanel.open = false
        overview.open = false
        if (findBar.open) findBar.hide()
        return any
    }
    function openPanel(name) {
        glassMenu.close()
        settingsPanel.open = name === "settings"
        downloadsPanel.open = name === "downloads"
        listPanel.open = name === "history" || name === "bookmarks"
        if (name === "history" || name === "bookmarks") listPanel.mode = name
        if (name === "downloads") dlUnseen = false
    }
    function openOverview() {
        closeOverlays()
        grabThumb(cur)
        overview.open = true
        overview.forceActiveFocus()
    }
    function openFind() {
        if (!cur || !cur.started) return
        findBar.show()
    }
    function doFind(text, backward) {
        if (!cur || !cur.started) return
        if (text === "") { cur.view.findText(""); findBar.matches = 0; return }
        cur.view.findText(text, backward ? WebEngineView.FindBackward : 0)
    }
    function findResult(page, result) {
        if (page !== cur) return
        findBar.matches = result.numberOfMatches
        findBar.active = result.activeMatch
    }

    function showMainMenu(x, y) {
        glassMenu.zoomValue = cur ? cur.pageZoom : 1
        var started = curStarted
        glassMenu.popup(x, y, [
            { key: "newtab", icon: "plus", text: G.t("Új lap", "New tab"), hint: "Ctrl+T" },
            { key: "newpriv", icon: "mask", text: G.t("Új privát lap", "New private tab"), hint: "Ctrl+Shift+N" },
            { key: "reopen", icon: "history", text: G.t("Bezárt lap újranyitása", "Reopen closed tab"), hint: "Ctrl+Shift+T", enabled: closedTabs.length > 0 },
            { sep: true },
            { key: "history", icon: "history", text: G.t("Előzmények", "History"), hint: "Ctrl+H" },
            { key: "bookmarks", icon: "bookmark", text: G.t("Könyvjelzők", "Bookmarks"), hint: "Ctrl+Shift+O" },
            { key: "downloads", icon: "download", text: G.t("Letöltések", "Downloads"), hint: "Ctrl+J" },
            { sep: true },
            { key: "find", icon: "search", text: G.t("Keresés az oldalon", "Find in page"), hint: "Ctrl+F", enabled: started },
            { key: "translate", icon: "translate", text: G.t("Oldal fordítása", "Translate page"), enabled: started },
            { zoom: true },
            { key: "fullscreen", icon: "fullscreen", text: G.t("Teljes képernyő", "Full screen"), hint: "F11" },
            { sep: true },
            { key: "gaccount", icon: "user", text: G.t("Google fiók", "Google account") },
            { key: "gpass", icon: "key", text: G.t("Google jelszavak", "Google passwords") },
            { key: "gactivity", icon: "history", text: G.t("Google tevékenységeim", "Google My Activity") },
            { sep: true },
            { key: "devtools", icon: "settings", text: G.t("Fejlesztői eszközök", "Developer tools"), hint: "F12", enabled: started },
            { key: "settings", icon: "settings", text: G.t("Beállítások", "Settings"), hint: "Ctrl+," }
        ], mainAction, true)
    }
    function mainAction(k) {
        switch (k) {
        case "newtab": newTab("", false); break
        case "newpriv": newTab("", true); break
        case "reopen": reopenClosed(); break
        case "history": openPanel("history"); break
        case "bookmarks": openPanel("bookmarks"); break
        case "downloads": openPanel("downloads"); break
        case "find": openFind(); break
        case "translate": translatePage(); break
        case "zoomIn": zoomStep(1); break
        case "zoomOut": zoomStep(-1); break
        case "zoomReset": setZoomCur(1.0); break
        case "fullscreen": toggleFullScreen(); break
        case "gaccount": newTab("https://myaccount.google.com", false); break
        case "gpass": newTab("https://passwords.google.com", false); break
        case "gactivity": newTab("https://myactivity.google.com", false); break
        case "devtools": openDevTools(); break
        case "settings": openPanel("settings"); break
        }
    }
    function showTabMenu(i, x, y) {
        var t = tabsModel.get(i)
        glassMenu.popup(x, y, [
            { key: "reload", icon: "reload", text: G.t("Újratöltés", "Reload") },
            { key: "dup", icon: "copy", text: G.t("Lap duplikálása", "Duplicate tab") },
            { key: "copy", icon: "copy", text: G.t("Cím másolása", "Copy address"), enabled: t.url !== "" },
            { sep: true },
            { key: "close", icon: "close", text: G.t("Lap bezárása", "Close tab"), hint: "Ctrl+W" },
            { key: "others", icon: "close", text: G.t("Többi lap bezárása", "Close other tabs"), enabled: tabsModel.count > 1 },
            { key: "right", icon: "forward", text: G.t("Jobbra lévők bezárása", "Close tabs to the right"), enabled: i < tabsModel.count - 1 },
            { sep: true },
            { key: "reopen", icon: "history", text: G.t("Bezárt lap újranyitása", "Reopen closed tab"), hint: "Ctrl+Shift+T", enabled: closedTabs.length > 0 }
        ], function (k) {
            var p = pageAt(i)
            if (k === "reload") { if (p && p.started) p.view.reload() }
            else if (k === "dup") duplicateTab(i)
            else if (k === "copy") Backend.copyText(t.url)
            else if (k === "close") closeTab(i)
            else if (k === "others") closeOthers(i)
            else if (k === "right") closeRight(i)
            else if (k === "reopen") reopenClosed()
        }, false)
    }
    function showContextMenu(page, req) {
        var link = req.linkUrl.toString()
        var media = req.mediaUrl.toString()
        var sel = req.selectedText
        var editable = req.isContentEditable
        var isImage = req.mediaType === 1
        var v = page.view
        var p = v.mapToItem(root.contentItem, req.x, req.y)
        var it = []
        if (link !== "") {
            it.push({ key: "linkTab", icon: "plus", text: G.t("Link megnyitása új lapon", "Open link in new tab") })
            if (!page.priv) it.push({ key: "linkPriv", icon: "mask", text: G.t("Link megnyitása privát lapon", "Open link in private tab") })
            it.push({ key: "linkCopy", icon: "copy", text: G.t("Link címének másolása", "Copy link address") })
            it.push({ key: "linkSave", icon: "download", text: G.t("Link mentése", "Save link") })
            it.push({ sep: true })
        }
        if (isImage && media !== "") {
            it.push({ key: "imgTab", icon: "image", text: G.t("Kép megnyitása új lapon", "Open image in new tab") })
            it.push({ key: "imgSave", icon: "download", text: G.t("Kép mentése", "Save image") })
            it.push({ key: "imgCopy", icon: "copy", text: G.t("Kép másolása", "Copy image") })
            it.push({ key: "imgUrl", icon: "copy", text: G.t("Kép címének másolása", "Copy image address") })
            it.push({ sep: true })
        }
        if (editable) {
            it.push({ key: "undo", icon: "back", text: G.t("Visszavonás", "Undo"), hint: "Ctrl+Z" })
            it.push({ key: "cut", icon: "copy", text: G.t("Kivágás", "Cut"), hint: "Ctrl+X", enabled: sel !== "" })
            it.push({ key: "copy", icon: "copy", text: G.t("Másolás", "Copy"), hint: "Ctrl+C", enabled: sel !== "" })
            it.push({ key: "paste", icon: "copy", text: G.t("Beillesztés", "Paste"), hint: "Ctrl+V" })
            it.push({ key: "selall", icon: "check", text: G.t("Összes kijelölése", "Select all"), hint: "Ctrl+A" })
            it.push({ sep: true })
        } else if (sel !== "") {
            var short = sel.length > 22 ? sel.substring(0, 22) + "…" : sel
            it.push({ key: "copy", icon: "copy", text: G.t("Másolás", "Copy"), hint: "Ctrl+C" })
            it.push({ key: "searchSel", icon: "search", text: G.t("Keresés: „", "Search for “") + short + G.t("”", "”") })
            it.push({ key: "translateSel", icon: "translate", text: G.t("Kijelölés fordítása", "Translate selection") })
            it.push({ sep: true })
        }
        it.push({ key: "back", icon: "back", text: G.t("Vissza", "Back"), enabled: v.canGoBack })
        it.push({ key: "forward", icon: "forward", text: G.t("Előre", "Forward"), enabled: v.canGoForward })
        it.push({ key: "reload", icon: "reload", text: G.t("Újratöltés", "Reload"), hint: "F5" })
        it.push({ sep: true })
        it.push({ key: "translate", icon: "translate", text: G.t("Oldal fordítása", "Translate page") })
        it.push({ key: "source", icon: "external", text: G.t("Oldal forrása", "View page source"), hint: "Ctrl+U" })
        it.push({ key: "inspect", icon: "settings", text: G.t("Vizsgálat", "Inspect"), hint: "F12" })

        glassMenu.popup(p.x, p.y, it, function (k) {
            switch (k) {
            case "linkTab": newTab(link, page.priv, true); break
            case "linkPriv": newTab(link, true, true); break
            case "linkCopy": Backend.copyText(link); toast(G.t("Link másolva", "Link copied")); break
            case "linkSave": v.triggerWebAction(WebEngineView.DownloadLinkToDisk); break
            case "imgTab": newTab(media, page.priv, true); break
            case "imgSave": v.triggerWebAction(WebEngineView.DownloadImageToDisk); break
            case "imgCopy": v.triggerWebAction(WebEngineView.CopyImageToClipboard); break
            case "imgUrl": Backend.copyText(media); break
            case "undo": v.triggerWebAction(WebEngineView.Undo); break
            case "cut": v.triggerWebAction(WebEngineView.Cut); break
            case "copy": v.triggerWebAction(WebEngineView.Copy); break
            case "paste": v.triggerWebAction(WebEngineView.Paste); break
            case "selall": v.triggerWebAction(WebEngineView.SelectAll); break
            case "searchSel": newTab(G.searchUrl(sel), page.priv); break
            case "translateSel": newTab("https://translate.google.com/?sl=auto&tl=" + (G.en ? "en" : "hu") + "&text=" + encodeURIComponent(sel) + "&op=translate", page.priv); break
            case "back": v.goBack(); break
            case "forward": v.goForward(); break
            case "reload": v.reload(); break
            case "translate": translatePage(); break
            case "source": newTab("view-source:" + v.url.toString(), page.priv); break
            case "inspect": openDevTools(); break
            }
        }, false)
    }

    function handleNewWindow(page, request) {
        // InNewWindow 0, InNewTab 1, InNewDialog 2, InNewBackgroundTab 3
        var bg = request.destination === 3
        var i = insertTab("", page.priv, bg)
        var p = pageAt(i)
        if (!p) return
        p.view.opened = true
        request.openIn(p.view)
        if (bg) toast(G.t("Megnyitva a háttérben", "Opened in background"), G.t("Váltás", "Switch"), function () { selectTab(i) })
    }

    // engedélykérések sorban
    property var permQueue: []
    function permLabel(t) {
        switch (t) {
        case 1: return G.t("a mikrofon használata", "use your microphone")
        case 2: return G.t("a kamera használata", "use your camera")
        case 3: return G.t("a kamera és a mikrofon használata", "use your camera and microphone")
        case 4: return G.t("a képernyő megosztása", "share your screen")
        case 5: return G.t("a képernyő és a hang megosztása", "share your screen and audio")
        case 6: return G.t("az egérmutató rögzítése", "lock your mouse pointer")
        case 7: return G.t("értesítések küldése", "show notifications")
        case 8: return G.t("a tartózkodási hely elérése", "know your location")
        case 9: return G.t("a vágólap olvasása", "read your clipboard")
        case 10: return G.t("a helyi betűtípusok elérése", "access local fonts")
        default: return G.t("egy funkció használata", "use a feature")
        }
    }
    function askPermission(page, perm) {
        permQueue.push(perm)
        if (permQueue.length === 1) nextPermission()
    }
    function nextPermission() {
        if (permQueue.length === 0) return
        var perm = permQueue[0]
        var host = G.hostOf(perm.origin.toString()) || perm.origin.toString()
        promptDlg.ask({
            title: host,
            message: G.t("Ez az oldal engedélyt kér: ", "This site wants to ") + permLabel(perm.permissionType),
            okText: G.t("Engedélyezés", "Allow"),
            cancelText: G.t("Tiltás", "Block"),
            onOk: function () { perm.grant(); permQueue.shift(); Qt.callLater(nextPermission) },
            onCancel: function () { perm.deny(); permQueue.shift(); Qt.callLater(nextPermission) }
        })
    }

    function toast(msg, act, fn) { toastItem.show(msg, act, fn) }

    // ---------------------------------------------------------------- letöltések
    function startDownload(d) {
        d.accept()
        var id = d.id
        var objs = dlObjects; objs[id] = d; dlObjects = objs
        downloadsModel.insert(0, { did: id, name: d.downloadFileName, path: d.downloadDirectory + "/" + d.downloadFileName,
                                   received: 0, total: Math.max(0, d.totalBytes), st: "progress", t: Date.now() })
        dlUnseen = true
        dlPoll.start()
        toast(G.t("Letöltés: ", "Downloading: ") + d.downloadFileName, G.t("Letöltések", "Downloads"), function () { openPanel("downloads") })
    }
    function pollDownloads() {
        var active = false, rec = 0, tot = 0
        for (var i = 0; i < downloadsModel.count; i++) {
            var row = downloadsModel.get(i)
            if (row.st !== "progress") continue
            var d = dlObjects[row.did]
            if (!d) { downloadsModel.setProperty(i, "st", "failed"); continue }
            downloadsModel.setProperty(i, "received", d.receivedBytes)
            downloadsModel.setProperty(i, "total", Math.max(0, d.totalBytes))
            downloadsModel.setProperty(i, "name", d.downloadFileName)
            downloadsModel.setProperty(i, "path", d.downloadDirectory + "/" + d.downloadFileName)
            if (d.state === 2) {
                downloadsModel.setProperty(i, "st", "done")
                var path = d.downloadDirectory + "/" + d.downloadFileName
                toast(G.t("Letöltve: ", "Downloaded: ") + d.downloadFileName, G.t("Megnyitás", "Open"), function () { Backend.openPath(path) })
                saveDownloads()
            } else if (d.state === 3) { downloadsModel.setProperty(i, "st", "cancelled"); saveDownloads() }
            else if (d.state === 4) { downloadsModel.setProperty(i, "st", "failed"); saveDownloads() }
            else { active = true; rec += d.receivedBytes; tot += Math.max(d.totalBytes, d.receivedBytes) }
        }
        dlActive = active
        dlProgress = tot > 0 ? rec / tot : 0
        if (!active) dlPoll.stop()
    }
    function saveDownloads() {
        var out = []
        for (var i = 0; i < downloadsModel.count && out.length < 200; i++) {
            var r = downloadsModel.get(i)
            if (r.st === "progress") continue
            out.push({ name: r.name, path: r.path, received: r.received, total: r.total, st: r.st, t: r.t })
        }
        G.s.downloads = JSON.stringify(out)
    }
    function loadDownloads() {
        var list = []
        try { list = JSON.parse(G.s.downloads || "[]") } catch (e) {}
        for (var i = 0; i < list.length; i++) {
            var r = list[i]
            downloadsModel.append({ did: -1, name: r.name, path: r.path, received: r.received, total: r.total, st: r.st, t: r.t })
        }
    }
    function cancelDownload(i) { var d = dlObjects[downloadsModel.get(i).did]; if (d) d.cancel() }
    function removeDownload(i) { downloadsModel.remove(i); saveDownloads() }
    function clearDownloads() {
        for (var i = downloadsModel.count - 1; i >= 0; i--) if (downloadsModel.get(i).st !== "progress") downloadsModel.remove(i)
        saveDownloads()
    }
    Timer { id: dlPoll; interval: 250; repeat: true; onTriggered: root.pollDownloads() }
    Connections {
        target: Backend.normalProfile
        function onDownloadRequested(download) { root.startDownload(download) }
        function onPresentNotification(notification) { root.toast(notification.title + (notification.message ? " — " + notification.message : "")) }
    }
    Connections {
        target: Backend
        function onUrlsReceived(urls) {
            var opened = false
            for (var i = 0; i < urls.length; i++) { var u = G.resolveInput(urls[i]); if (u) { root.newTab(u, false); opened = true } }
            if (!opened) root.newTab("", false)
            if (root.visibility === Window.Minimized) root.showNormal()
            root.raise(); root.requestActivate()
        }
    }
    Connections {
        target: Backend.privateProfile
        function onDownloadRequested(download) { root.startDownload(download) }
    }

    // ---------------------------------------------------------------- munkamenet
    function saveSession() {
        var out = []
        var idx = 0
        for (var i = 0; i < tabsModel.count; i++) {
            var t = tabsModel.get(i)
            if (t.priv || t.url === "") { if (i < currentIndex) idx--; continue }
            out.push({ url: t.url, title: t.title })
        }
        G.s.session = JSON.stringify(out)
        G.s.sessionIndex = Math.max(0, Math.min(out.length - 1, currentIndex + idx))
    }
    Timer { id: saveSessionLater; interval: 1200; onTriggered: root.saveSession() }
    Connections {
        target: tabModel
        function onDataChanged() { saveSessionLater.restart() }
        function onCountChanged() { saveSessionLater.restart() }
    }
    onClosing: { saveSession(); saveDownloads() }

    function applyBlur() { Backend.setBlurBehind(root, G.s.blurBehind && G.s.windowOpacity < 0.995, 14) }
    Connections {
        target: G.s
        function onBlurBehindChanged() { root.applyBlur() }
        function onWindowOpacityChanged() { root.applyBlur() }
        function onAdblockChanged() { Backend.setAdblock(G.s.adblock) }
    }

    Component.onCompleted: {
        Backend.setAdblock(G.s.adblock)
        loadDownloads()
        var restored = false
        if (G.s.restoreSession) {
            var list = []
            try { list = JSON.parse(G.s.session || "[]") } catch (e) {}
            var want = Math.max(0, Math.min(list.length - 1, G.s.sessionIndex))
            for (var i = 0; i < list.length; i++) {
                tabsModel.append({ uid: makeUid(), url: list[i].url, title: list[i].title || "", icon: "", priv: false,
                                   loading: false, progress: 0, audible: false, lazy: i !== want })
            }
            if (list.length > 0) { currentIndex = want; restored = true }
        }
        for (var k = 0; k < StartupUrls.length; k++) {
            var u = G.resolveInput(StartupUrls[k])
            if (u) { insertTab(u, false, false); restored = true }
        }
        if (!restored) insertTab("", false, false)
        updateCur()
        Qt.callLater(applyBlur)
        blurRetry.start()
        if (Backend.screenshotPath() !== "") shot.start()
    }
    Timer { id: blurRetry; interval: 400; onTriggered: root.applyBlur() }

    // ---------------------------------------------------------------- jelenet
    Item {
        id: windowContent
        anchors.fill: parent
        layer.enabled: !root.maximized
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: windowMask
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1.0
        }

        // a weboldalak rétege – ezt töri meg az üveg
        Item {
            id: contentLayer
            anchors.fill: parent
            Rectangle { anchors.fill: parent; color: G.windowTint }
            Item {
                id: pages
                anchors.fill: parent
                Repeater {
                    id: pagesRep
                    model: tabModel
                    delegate: TabPage {
                        required property bool lazy
                        anchors.fill: parent
                        b: root
                        deferred: lazy
                    }
                    onItemAdded: Qt.callLater(root.updateCur)
                }
            }
        }

        Item { id: keyCatcher; focus: true }

        TopBar {
            id: topBar
            b: root
            source: contentLayer
            x: root.barMargin
            y: root.barMargin
            width: parent.width - 2 * root.barMargin
            opacity: root.videoFull ? 0 : 1
            visible: opacity > 0.01
            Behavior on opacity { NumberAnimation { duration: G.dur(200) } }
        }

        SearchPanel {
            id: searchPanel
            b: root
            source: contentLayer
            x: topBar.x + 176
            width: Math.max(380, topBar.width - 176 - 140)
            y: topBar.y + topBar.height + 6
            open: topBar.editing
            query: root.searchText
        }

        FindBar {
            id: findBar
            source: contentLayer
            anchors.right: parent.right
            anchors.rightMargin: root.barMargin + 6
            y: topBar.y + topBar.height + 8
            onSearch: function (text, backward) { root.doFind(text, backward) }
            onClosed: root.focusPage()
        }

        // a link címe, amire az egér mutat
        Item {
            id: hoverPill
            x: 12
            height: 30
            width: Math.min(hoverText.implicitWidth + 28, parent.width * 0.5)
            y: parent.height - height - 12
            opacity: root.hoverUrl !== "" && !overview.open ? 1 : 0
            visible: opacity > 0.01
            Behavior on opacity { NumberAnimation { duration: G.dur(root.hoverUrl !== "" ? 120 : 260) } }
            Glass { anchors.fill: parent; source: contentLayer; radius: 15; tintAlpha: G.dark ? 0.5 : 0.6 }
            Text {
                id: hoverText
                anchors.verticalCenter: parent.verticalCenter
                x: 14; width: parent.width - 28
                text: root.hoverUrl
                color: G.text; font.pixelSize: 12; elide: Text.ElideMiddle
            }
        }

        Overview { id: overview; b: root; source: contentLayer; onOpenChanged: if (!open) root.focusPage() }
        SettingsPanel { id: settingsPanel; b: root; source: contentLayer; topInset: root.contentInset }
        DownloadsPanel { id: downloadsPanel; b: root; source: contentLayer; topInset: root.contentInset }
        ListPanel { id: listPanel; b: root; source: contentLayer; topInset: root.contentInset }
        Toast { id: toastItem; source: contentLayer }
        GlassMenu { id: glassMenu; source: contentLayer }
        PromptDialog { id: promptDlg; source: contentLayer }

        // vékony fényes keret
        Rectangle {
            anchors.fill: parent
            visible: !root.maximized
            radius: 14
            color: "transparent"
            border.width: 1
            border.color: G.dark ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(0, 0, 0, 0.14)
        }
    }

    Item {
        id: windowMask
        anchors.fill: parent
        visible: false
        layer.enabled: true
        Rectangle { anchors.fill: parent; radius: 14; color: "black" }
    }

    // egér vissza / előre gombok
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.BackButton | Qt.ForwardButton
        onPressed: function (m) { if (m.button === Qt.BackButton) root.goBack(); else root.goForward() }
    }

    // átméretezés a széleknél (keret nélküli ablak)
    component Edge: MouseArea {
        property int edges: 0
        enabled: !root.maximized
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        onPressed: root.startSystemResize(edges)
    }
    Edge { edges: Qt.LeftEdge; x: 0; y: 10; width: 5; height: parent.height - 20; cursorShape: Qt.SizeHorCursor }
    Edge { edges: Qt.RightEdge; x: parent.width - 5; y: 10; width: 5; height: parent.height - 20; cursorShape: Qt.SizeHorCursor }
    Edge { edges: Qt.TopEdge; x: 10; y: 0; width: parent.width - 20; height: 4; cursorShape: Qt.SizeVerCursor }
    Edge { edges: Qt.BottomEdge; x: 10; y: parent.height - 5; width: parent.width - 20; height: 5; cursorShape: Qt.SizeVerCursor }
    Edge { edges: Qt.LeftEdge | Qt.TopEdge; x: 0; y: 0; width: 10; height: 10; cursorShape: Qt.SizeFDiagCursor }
    Edge { edges: Qt.RightEdge | Qt.BottomEdge; x: parent.width - 10; y: parent.height - 10; width: 10; height: 10; cursorShape: Qt.SizeFDiagCursor }
    Edge { edges: Qt.RightEdge | Qt.TopEdge; x: parent.width - 10; y: 0; width: 10; height: 10; cursorShape: Qt.SizeBDiagCursor }
    Edge { edges: Qt.LeftEdge | Qt.BottomEdge; x: 0; y: parent.height - 10; width: 10; height: 10; cursorShape: Qt.SizeBDiagCursor }

    // ---------------------------------------------------------------- billentyűparancsok
    component Sc: Shortcut { context: Qt.ApplicationShortcut }
    Sc { sequence: "Ctrl+T"; onActivated: root.newTab("", false) }
    Sc { sequence: "Ctrl+Shift+N"; onActivated: root.newTab("", true) }
    Sc { sequence: "Ctrl+Shift+T"; onActivated: root.reopenClosed() }
    Sc { sequences: ["Ctrl+W", "Ctrl+F4"]; onActivated: root.closeTab(root.currentIndex) }
    Sc { sequences: ["Ctrl+L", "Alt+D", "F6"]; onActivated: root.focusUrlBar() }
    Sc { sequences: ["Ctrl+Tab", "Ctrl+PgDown"]; onActivated: root.selectTab((root.currentIndex + 1) % tabsModel.count) }
    Sc { sequences: ["Ctrl+Shift+Tab", "Ctrl+PgUp"]; onActivated: root.selectTab((root.currentIndex - 1 + tabsModel.count) % tabsModel.count) }
    Sc { sequences: ["Ctrl+R", "F5"]; onActivated: root.reload(false) }
    Sc { sequences: ["Ctrl+Shift+R", "Ctrl+F5", "Shift+F5"]; onActivated: root.reload(true) }
    Sc { sequence: "Ctrl+F"; onActivated: root.openFind() }
    Sc { sequence: "Ctrl+D"; onActivated: root.toggleBookmark() }
    Sc { sequence: "Ctrl+H"; onActivated: root.openPanel("history") }
    Sc { sequence: "Ctrl+Shift+O"; onActivated: root.openPanel("bookmarks") }
    Sc { sequence: "Ctrl+J"; onActivated: root.openPanel("downloads") }
    Sc { sequence: "Ctrl+,"; onActivated: root.openPanel("settings") }
    Sc { sequence: "Ctrl+Shift+A"; onActivated: { if (overview.open) overview.open = false; else root.openOverview() } }
    Sc { sequences: ["Ctrl++", "Ctrl+="]; onActivated: root.zoomStep(1) }
    Sc { sequence: "Ctrl+-"; onActivated: root.zoomStep(-1) }
    Sc { sequence: "Ctrl+0"; onActivated: root.setZoomCur(1.0) }
    Sc { sequence: "F11"; onActivated: root.toggleFullScreen() }
    Sc { sequence: "F12"; onActivated: root.openDevTools() }
    Sc { sequence: "Ctrl+U"; onActivated: if (root.curUrl !== "") root.newTab("view-source:" + root.curUrl, root.curPriv) }
    Sc { sequence: "Alt+Left"; onActivated: root.goBack() }
    Sc { sequence: "Alt+Right"; onActivated: root.goForward() }
    Sc { sequence: "Alt+Home"; onActivated: root.goHome() }
    Sc {
        sequence: "Escape"
        enabled: root.videoFull || promptDlg.open || glassMenu.open || settingsPanel.open || downloadsPanel.open || listPanel.open || overview.open || topBar.editing
        onActivated: {
            if (root.videoFull && root.cur) { root.cur.view.triggerWebAction(WebEngineView.ExitFullScreen); return }
            if (promptDlg.open) { promptDlg.reject(); return }
            if (root.closeOverlays()) return
            if (topBar.editing) { root.focusPage(); return }
            if (root.curLoading) root.stopLoad()
        }
    }
    Repeater {
        model: 9
        Item {
            required property int index
            Shortcut {
                context: Qt.ApplicationShortcut
                sequence: "Ctrl+" + (index + 1)
                onActivated: root.selectTab(index === 8 ? tabsModel.count - 1 : index)
            }
        }
    }

    // ---------------------------------------------------------------- automatikus képernyőkép (CI)
    Timer {
        id: shot
        property int step: 0
        interval: 3500
        repeat: true
        onTriggered: {
            var base = Backend.screenshotPath()
            var stem = base.replace(/\.png$/, "")
            if (step === 0) { Backend.saveScreenshot(root, base); root.openPanel("settings") }
            else if (step === 1) { Backend.saveScreenshot(root, stem + "-settings.png"); root.openPanel(""); root.showMainMenu(root.width - 20, 100) }
            else if (step === 2) { Backend.saveScreenshot(root, stem + "-menu.png"); glassMenu.close(); root.openOverview() }
            else if (step === 3) { Backend.saveScreenshot(root, stem + "-overview.png"); overview.open = false; root.navigate("https://example.com") }
            else if (step === 4) { Backend.saveScreenshot(root, stem + "-page.png"); G.s.transparentPages = true }
            else if (step === 5) { Backend.saveScreenshot(root, stem + "-transparent.png"); G.s.transparentPages = false; Backend.quitLater(300); stop() }
            step++
        }
    }
}
