#include "backend.h"
#include "adblock.h"

#include <QCoreApplication>
#include <QDesktopServices>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QGuiApplication>
#include <QClipboard>
#include <QLocale>
#include <QProcess>
#include <QQuickWindow>
#include <QRegularExpression>
#include <QStandardPaths>
#include <QTimer>
#include <QUrl>
#include <QWebEngineCookieStore>
#include <QtWebEngineQuick/QQuickWebEngineProfile>

#ifdef HAVE_KWINDOWSYSTEM
#include <KWindowEffects>
#endif

Backend::Backend(QObject *parent) : QObject(parent) {
    m_adblock = new AdBlocker(this);
    m_normal = makeProfile(true);
    m_private = makeProfile(false);
}

QQuickWebEngineProfile *Backend::makeProfile(bool persistent) {
    auto *p = new QQuickWebEngineProfile(this);
    if (persistent) {
        p->setStorageName(QStringLiteral("GlassBrowser"));
        p->setOffTheRecord(false);
        p->setPersistentCookiesPolicy(QQuickWebEngineProfile::ForcePersistentCookies);
        p->setHttpCacheType(QQuickWebEngineProfile::DiskHttpCache);
    }
    // Chrome-azonosító (a Google bejelentkezés így nem utasítja el a böngészőt)
    QString ua = p->httpUserAgent();
    ua.remove(QRegularExpression(QStringLiteral("QtWebEngine/[0-9.]+ ")));
    p->setHttpUserAgent(ua);
    p->setDownloadPath(downloadsDir());
    p->setUrlRequestInterceptor(m_adblock);
    p->setSpellCheckEnabled(false);
    return p;
}

QObject *Backend::normalProfile() const { return m_normal; }
QObject *Backend::privateProfile() const { return m_private; }

QString Backend::systemLanguage() const { return QLocale::system().name().left(2); }

bool Backend::blurAvailable() const {
#ifdef HAVE_KWINDOWSYSTEM
    return true;
#else
    return false;
#endif
}

void Backend::setBlurBehind(QWindow *window, bool on, int radius) {
    Q_UNUSED(radius)
    if (!window) return;
#ifdef HAVE_KWINDOWSYSTEM
    KWindowEffects::enableBlurBehind(window, on);
#else
    Q_UNUSED(on)
#endif
}

void Backend::setAdblock(bool on) { m_adblock->setEnabled(on); }
int Backend::blockedCount() const { return m_adblock->blockedCount(); }

QString Backend::downloadsDir() const {
    QString d = QStandardPaths::writableLocation(QStandardPaths::DownloadLocation);
    if (d.isEmpty()) d = QDir::homePath() + QStringLiteral("/Downloads");
    QDir().mkpath(d);
    return d;
}

void Backend::openPath(const QString &path) const {
    QDesktopServices::openUrl(QUrl::fromLocalFile(path));
}

void Backend::showInFolder(const QString &path) const {
    // KDE: a Dolphin kijelöli a fájlt; máshol a mappa nyílik meg
    if (!QProcess::startDetached(QStringLiteral("dolphin"), {QStringLiteral("--select"), path}))
        QDesktopServices::openUrl(QUrl::fromLocalFile(QFileInfo(path).absolutePath()));
}

bool Backend::removeFile(const QString &path) const { return QFile::remove(path); }

void Backend::clearCookies() {
    if (auto *s = m_normal->cookieStore()) s->deleteAllCookies();
}

void Backend::clearCache() { m_normal->clearHttpCache(); }

void Backend::resetPrivateProfile() {
    if (auto *s = m_private->cookieStore()) s->deleteAllCookies();
    m_private->clearHttpCache();
}

void Backend::copyText(const QString &text) const {
    if (auto *cb = QGuiApplication::clipboard()) cb->setText(text);
}

QString Backend::clipboardText() const {
    if (auto *cb = QGuiApplication::clipboard()) return cb->text();
    return {};
}

void Backend::saveScreenshot(QWindow *window, const QString &path) {
    auto *qw = qobject_cast<QQuickWindow *>(window);
    if (!qw) return;
    qw->grabWindow().save(path);
}

QString Backend::screenshotPath() const {
    return qEnvironmentVariable("GLASS_SCREENSHOT");
}

void Backend::quitLater(int ms) {
    QTimer::singleShot(ms, qApp, &QCoreApplication::quit);
}
