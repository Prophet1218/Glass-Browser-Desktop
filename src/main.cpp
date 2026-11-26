#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QIcon>
#include <QLocalServer>
#include <QLocalSocket>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QUrl>
#include <QtWebEngineQuick/qtwebenginequickglobal.h>

#include "backend.h"

int main(int argc, char *argv[]) {
    // sima görgetés, GPU-gyorsítás, Wayland
    qputenv("QTWEBENGINE_CHROMIUM_FLAGS",
            qgetenv("QTWEBENGINE_CHROMIUM_FLAGS") +
                " --enable-smooth-scrolling --enable-gpu-rasterization --ignore-gpu-blocklist");
    QCoreApplication::setOrganizationName(QStringLiteral("GlassBrowser"));
    QCoreApplication::setApplicationName(QStringLiteral("Glass Browser"));
    QCoreApplication::setApplicationVersion(QStringLiteral(APP_VERSION));
    QtWebEngineQuick::initialize();

    QGuiApplication app(argc, argv);
    QGuiApplication::setDesktopFileName(QStringLiteral("glass-browser-desktop"));
    app.setWindowIcon(QIcon(QStringLiteral(":/qt/qml/GlassBrowser/qml/icons/logo.svg")));
    QQuickStyle::setStyle(QStringLiteral("Basic"));

    QStringList urls;
    for (int i = 1; i < argc; ++i) {
        const QString a = QString::fromLocal8Bit(argv[i]);
        if (a.startsWith(QLatin1Char('-'))) continue;
        // helyi fájl elérési útja → file:// cím
        if (QFile::exists(a)) urls << QUrl::fromLocalFile(QFileInfo(a).absoluteFilePath()).toString();
        else urls << a;
    }

    // egyetlen példány: ha már fut, átadjuk neki a címeket (a profilt nem nyithatja meg két folyamat)
    const QString serverName = QStringLiteral("glass-browser-desktop-") + qEnvironmentVariable("USER");
    {
        QLocalSocket sock;
        sock.connectToServer(serverName);
        if (sock.waitForConnected(300)) {
            sock.write((urls.isEmpty() ? QStringLiteral("\n") : urls.join(QLatin1Char('\n')) + QLatin1Char('\n')).toUtf8());
            sock.waitForBytesWritten(1000);
            sock.disconnectFromServer();
            return 0;
        }
    }
    QLocalServer::removeServer(serverName);
    QLocalServer server;
    server.listen(serverName);

    Backend backend;
    QObject::connect(&server, &QLocalServer::newConnection, &backend, [&server, &backend]() {
        while (QLocalSocket *c = server.nextPendingConnection()) {
            QObject::connect(c, &QLocalSocket::readyRead, c, [c, &backend]() {
                const QStringList list = QString::fromUtf8(c->readAll()).split(QLatin1Char('\n'), Qt::SkipEmptyParts);
                emit backend.urlsReceived(list);
            });
            QObject::connect(c, &QLocalSocket::disconnected, c, &QObject::deleteLater);
        }
    });
    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty(QStringLiteral("Backend"), &backend);
    engine.rootContext()->setContextProperty(QStringLiteral("StartupUrls"), urls);
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed, &app,
                     []() { QCoreApplication::exit(1); }, Qt::QueuedConnection);
    engine.loadFromModule("GlassBrowser", "Main");
    return app.exec();
}
