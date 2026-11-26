import QtQuick
import "Js.js" as Js

// Letöltések: folyamatban lévők haladással, a kész fájlok megnyithatók / megmutathatók a mappában.
SidePanel {
    id: dp
    property var b
    title: G.t("Letöltések", "Downloads")
    tools: [
        GlassButton { icon: "folder"; tip: G.t("Letöltések mappa", "Downloads folder"); onClicked: Backend.openPath(Backend.downloadsDir()) },
        GlassButton { icon: "trash"; tip: G.t("Lista törlése", "Clear list"); onClicked: dp.b.clearDownloads() }
    ]

    Text {
        anchors.centerIn: parent
        visible: dp.b.downloadsModel.count === 0
        text: G.t("Még nincs letöltés", "No downloads yet")
        color: G.subtext; font.pixelSize: 14
    }
    ListView {
        anchors.fill: parent
        clip: true
        spacing: 6
        model: dp.b.downloadsModel
        boundsBehavior: Flickable.StopAtBounds
        delegate: Rectangle {
            id: row
            required property int index
            required property string name
            required property string path
            required property real received
            required property real total
            required property string st
            width: ListView.view.width; height: 66; radius: 16
            color: rma.containsMouse ? G.hover : (G.dark ? Qt.rgba(1, 1, 1, 0.05) : Qt.rgba(1, 1, 1, 0.4))
            readonly property bool done: st === "done"
            readonly property bool active: st === "progress"
            MouseArea { id: rma; anchors.fill: parent; hoverEnabled: true; cursorShape: row.done ? Qt.PointingHandCursor : Qt.ArrowCursor; onClicked: if (row.done) Backend.openPath(row.path) }
            Rectangle {
                x: 12; width: 40; height: 40; radius: 12
                anchors.verticalCenter: parent.verticalCenter
                color: Qt.rgba(G.accent.r, G.accent.g, G.accent.b, 0.22)
                Text {
                    anchors.centerIn: parent
                    text: { var m = /\.([a-z0-9]{1,4})$/i.exec(row.name); return m ? m[1].toUpperCase() : "?" }
                    color: G.text; font.pixelSize: 11; font.weight: Font.Bold
                }
            }
            Column {
                x: 64; width: parent.width - 64 - btns.width - 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4
                Text { width: parent.width; text: row.name; color: G.text; font.pixelSize: 13.5; elide: Text.ElideMiddle }
                Rectangle {
                    visible: row.active
                    width: parent.width; height: 4; radius: 2
                    color: G.dark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.1)
                    Rectangle {
                        height: parent.height; radius: 2; color: G.accent
                        width: row.total > 0 ? parent.width * Math.min(1, row.received / row.total) : parent.width * 0.3
                        Behavior on width { NumberAnimation { duration: 300 } }
                    }
                }
                Text {
                    width: parent.width
                    color: row.st === "failed" ? "#FF6B6B" : G.subtext; font.pixelSize: 12
                    text: row.active ? (Js.formatBytes(row.received) + (row.total > 0 ? " / " + Js.formatBytes(row.total) : ""))
                        : row.done ? Js.formatBytes(row.total > 0 ? row.total : row.received)
                        : row.st === "cancelled" ? G.t("Megszakítva", "Cancelled") : G.t("Sikertelen", "Failed")
                }
            }
            Row {
                id: btns
                anchors.right: parent.right; anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                GlassButton { visible: row.done; icon: "folder"; tip: G.t("Megjelenítés a mappában", "Show in folder"); onClicked: Backend.showInFolder(row.path) }
                GlassButton { visible: row.active; icon: "stop"; tip: G.t("Megszakítás", "Cancel"); onClicked: dp.b.cancelDownload(row.index) }
                GlassButton { visible: !row.active; icon: "close"; tip: G.t("Eltávolítás a listából", "Remove from list"); onClicked: dp.b.removeDownload(row.index) }
            }
        }
    }
}
