import QtQuick
import QtQuick.Shapes

// Vonalas ikonok (24×24-es rácson rajzolva, tetszőleges méretre skálázva).
Item {
    id: ico
    property string name: ""
    property color color: G.text
    property real size: 18
    property real stroke: 1.8
    width: size
    height: size

    readonly property var paths: ({
        "back": "M15 18L9 12L15 6",
        "forward": "M9 18L15 12L9 6",
        "reload": "M20 11A8 8 0 1 0 17.7 17.7 M20 4V10H14",
        "stop": "M18 6L6 18 M6 6L18 18",
        "close": "M17 7L7 17 M7 7L17 17",
        "plus": "M12 5V19 M5 12H19",
        "minus": "M5 12H19",
        "max": "M6 6H18V18H6Z",
        "restore": "M8 9H17V18H8Z M6 15V6H15",
        "star": "M12 3.5L14.6 8.9L20.5 9.7L16.2 13.8L17.3 19.7L12 16.9L6.7 19.7L7.8 13.8L3.5 9.7L9.4 8.9Z",
        "download": "M12 4V15 M7.5 10.5L12 15L16.5 10.5 M5 20H19",
        "dots": "M5.5 12H5.6 M12 12H12.1 M18.5 12H18.6",
        "tabs": "M3.5 8H16.5V20H3.5Z M7.5 4H20.5V16",
        "search": "M10.5 17.5A7 7 0 1 0 10.5 3.5A7 7 0 1 0 10.5 17.5Z M20.5 20.5L15.6 15.6",
        "lock": "M6 11H18V20H6Z M8.5 11V8A3.5 3.5 0 0 1 15.5 8V11",
        "mask": "M3 11C6 8.5 18 8.5 21 11 M5.5 11L6.8 6H17.2L18.5 11 M7.5 17.5A2.5 2.5 0 1 0 7.5 12.5A2.5 2.5 0 1 0 7.5 17.5Z M16.5 17.5A2.5 2.5 0 1 0 16.5 12.5A2.5 2.5 0 1 0 16.5 17.5Z M10 15H14",
        "settings": "M12 15A3 3 0 1 0 12 9A3 3 0 1 0 12 15Z M19.4 13.5L21 12L19.4 10.5L19.8 8.3L17.7 7.6L16.9 5.5L14.7 5.9L13.2 4.2L12 4L10.8 4.2L9.3 5.9L7.1 5.5L6.3 7.6L4.2 8.3L4.6 10.5L3 12L4.6 13.5L4.2 15.7L6.3 16.4L7.1 18.5L9.3 18.1L10.8 19.8L13.2 19.8L14.7 18.1L16.9 18.5L17.7 16.4L19.8 15.7Z",
        "history": "M4 12A8 8 0 1 0 6.3 6.3 M4 4.5V9H8.5 M12 8V12.5L15 14.5",
        "bookmark": "M6.5 3.5H17.5V20.5L12 16.5L6.5 20.5Z",
        "translate": "M4 5.5H12 M8 3.5V5.5 M6 5.5C6.5 9 9 11.5 12 12.5 M10.2 5.5C9.6 9 7.5 12 4.5 13.5 M13 20.5L16.8 11L20.6 20.5 M14.3 17.3H19.3",
        "copy": "M9 9H20V20H9Z M5 15V4H16",
        "external": "M14 4H20V10 M20 4L11 13 M18 14V20H4V6H10",
        "image": "M4 5H20V19H4Z M4 16L9 11L13 15L16 12L20 16 M15.5 8.5H15.6",
        "folder": "M3 6.5H9L11 8.5H21V19H3Z",
        "trash": "M4 7H20 M9.5 7V4.5H14.5V7 M6.5 7L7.5 20H16.5L17.5 7",
        "home": "M3.5 11L12 4L20.5 11 M5.5 9.5V20H18.5V9.5",
        "fullscreen": "M4 9V4H9 M20 9V4H15 M4 15V20H9 M20 15V20H15",
        "check": "M5 12.5L10 17.5L19 7",
        "chevron": "M6 9L12 15L18 9",
        "globe": "M12 21A9 9 0 1 0 12 3A9 9 0 1 0 12 21Z M3 12H21 M12 3C15.5 6.5 15.5 17.5 12 21 M12 3C8.5 6.5 8.5 17.5 12 21",
        "user": "M12 12A4 4 0 1 0 12 4A4 4 0 1 0 12 12Z M4.5 20.5C5.5 16.8 8.3 15 12 15C15.7 15 18.5 16.8 19.5 20.5",
        "key": "M15.5 9A4.5 4.5 0 1 1 11.2 14.3L9 16.5H6.5V19H4V16.5L9.7 10.8A4.5 4.5 0 0 1 15.5 9Z",
        "zoom": "M10.5 17.5A7 7 0 1 0 10.5 3.5A7 7 0 1 0 10.5 17.5Z M20.5 20.5L15.6 15.6 M7.5 10.5H13.5 M10.5 7.5V13.5",
        "sun": "M12 16A4 4 0 1 0 12 8A4 4 0 1 0 12 16Z M12 2.5V4.5 M12 19.5V21.5 M2.5 12H4.5 M19.5 12H21.5 M5.3 5.3L6.7 6.7 M17.3 17.3L18.7 18.7 M5.3 18.7L6.7 17.3 M17.3 6.7L18.7 5.3",
        "shield": "M12 3L19.5 6V11.5C19.5 16 16.3 19.6 12 21C7.7 19.6 4.5 16 4.5 11.5V6Z",
        "pin": "M12 21C12 21 18.5 14.8 18.5 10A6.5 6.5 0 0 0 5.5 10C5.5 14.8 12 21 12 21Z M12 12.3A2.3 2.3 0 1 0 12 7.7A2.3 2.3 0 1 0 12 12.3Z",
        "camera": "M4 7.5H8L9.5 5.5H14.5L16 7.5H20V19H4Z M12 16.5A3.5 3.5 0 1 0 12 9.5A3.5 3.5 0 1 0 12 16.5Z",
        "mic": "M12 14.5A3 3 0 0 0 15 11.5V6A3 3 0 0 0 9 6V11.5A3 3 0 0 0 12 14.5Z M6 11.5A6 6 0 0 0 18 11.5 M12 17.5V21",
        "bell": "M6 16.5V11A6 6 0 0 1 18 11V16.5L19.5 18H4.5Z M10 20.5H14"
    })

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: ico.color
            strokeWidth: ico.stroke
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            scale: Qt.size(ico.size / 24, ico.size / 24)
            PathSvg { path: ico.paths[ico.name] || "" }
        }
    }
}
