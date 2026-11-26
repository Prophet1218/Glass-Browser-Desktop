import QtQuick

// Folyékony üveg felület: a [source] elem (a weboldalak rétege) ide eső részét valós időben
// elmossa és a szélein megtöri (lens.frag). Forrás nélkül csak dér.
Item {
    id: root
    property Item source: null
    property real radius: height / 2
    property real blur: G.s.glassBlur
    property real refraction: G.s.refraction
    property real tintAlpha: G.dark ? 0.34 : 0.42
    property color tint: G.tintColor
    property real press: 0
    property bool live: visible && opacity > 0.01
    readonly property real pad: Math.ceil(blur * 1.5 + 24)

    Behavior on press { NumberAnimation { duration: G.dur(220); easing.type: Easing.OutCubic } }

    ShaderEffectSource {
        id: src
        sourceItem: root.source
        live: root.live && root.source !== null
        hideSource: false
        visible: false
        mipmap: false
        smooth: true
        recursive: false
        // erősebb elmosásnál kisebb felbontásban készül a háttér: olcsóbb és simább
        readonly property real k: root.blur > 2 ? Math.max(0.16, Math.min(0.8, 7 / root.blur)) : 1
        textureSize: Qt.size(Math.max(1, Math.round((root.width + 2 * root.pad) * k)),
                             Math.max(1, Math.round((root.height + 2 * root.pad) * k)))
    }

    // a forrás téglalap minden képkockán követi a felület helyét (mozgás, animáció közben is)
    FrameAnimation {
        running: root.live && root.source !== null
        onTriggered: root.syncRect()
    }
    function syncRect() {
        if (!source) return
        var p = root.mapToItem(source, -pad, -pad)
        src.sourceRect = Qt.rect(p.x, p.y, width + 2 * pad, height + 2 * pad)
    }
    Component.onCompleted: syncRect()

    ShaderEffect {
        anchors.fill: parent
        visible: root.source !== null
        property var src: src
        property size size: Qt.size(root.width, root.height)
        property real radius: root.radius
        property real pad: root.pad
        property real blur: root.blur
        property real refraction: root.refraction
        property real dark: G.dark ? 1.0 : 0.0
        property real tintAlpha: root.tintAlpha
        property color tint: root.tint
        property real press: root.press
        fragmentShader: "qrc:/shaders/lens.frag.qsb"
    }

    // forrás nélkül (pl. a kezdőlap fölött): egyszerű dér
    Rectangle {
        anchors.fill: parent
        visible: root.source === null
        radius: root.radius
        color: Qt.rgba(root.tint.r, root.tint.g, root.tint.b, 0.55)
        border.color: Qt.rgba(1, 1, 1, G.dark ? 0.22 : 0.6)
        border.width: 1
    }
}
