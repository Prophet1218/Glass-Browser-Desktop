cmake_minimum_required(VERSION 3.21)
project(glass-browser-desktop VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 6.8 REQUIRED COMPONENTS Core Gui Qml Quick QuickControls2 WebEngineCore WebEngineQuick ShaderTools Network)
find_package(KF6WindowSystem QUIET)

qt_standard_project_setup(REQUIRES 6.8)

qt_add_executable(glass-browser-desktop
    src/main.cpp
    src/backend.h src/backend.cpp
    src/adblock.h src/adblock.cpp
)

set_source_files_properties(qml/G.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)

qt_add_qml_module(glass-browser-desktop
    URI GlassBrowser
    VERSION 1.0
    QML_FILES
        qml/G.qml
        qml/Main.qml
        qml/Glass.qml
        qml/GlassButton.qml
        qml/Ico.qml
        qml/ToolTipLite.qml
        qml/TabChip.qml
        qml/TabPage.qml
        qml/StartPage.qml
        qml/TopBar.qml
        qml/SearchPanel.qml
        qml/GlassMenu.qml
        qml/Overview.qml
        qml/SidePanel.qml
        qml/SettingsPanel.qml
        qml/DownloadsPanel.qml
        qml/ListPanel.qml
        qml/FindBar.qml
        qml/Toast.qml
        qml/PromptDialog.qml
        qml/GSlider.qml
        qml/GSwitch.qml
        qml/GChoice.qml
        qml/Js.js
    RESOURCES
        qml/icons/logo.svg
)

qt_add_shaders(glass-browser-desktop "shaders"
    PREFIX "/"
    FILES shaders/lens.frag
)

target_link_libraries(glass-browser-desktop PRIVATE
    Qt6::Core Qt6::Gui Qt6::Qml Qt6::Quick Qt6::QuickControls2
    Qt6::WebEngineCore Qt6::WebEngineQuick Qt6::Network)

if(KF6WindowSystem_FOUND)
    target_link_libraries(glass-browser-desktop PRIVATE KF6::WindowSystem)
    target_compile_definitions(glass-browser-desktop PRIVATE HAVE_KWINDOWSYSTEM=1)
endif()

target_compile_definitions(glass-browser-desktop PRIVATE APP_VERSION="${PROJECT_VERSION}")

install(TARGETS glass-browser-desktop RUNTIME DESTINATION bin)
install(FILES packaging/glass-browser-desktop.desktop DESTINATION share/applications)
install(FILES qml/icons/logo.svg DESTINATION share/icons/hicolor/scalable/apps RENAME glass-browser-desktop.svg)
