#pragma once
#include <QObject>
#include <QString>
#include <QVariant>
#include <QPointer>
#include <QStringList>

class AdBlocker;
class QQuickWebEngineProfile;
class QWindow;

// A QML felülethez a rendszerközeli szolgáltatások: KWin ablak-elmosás, profilok, szűrő,
// fájlok megnyitása, sütik törlése.
class Backend : public QObject {
    Q_OBJECT
    Q_PROPERTY(QObject *normalProfile READ normalProfile CONSTANT)
    Q_PROPERTY(QObject *privateProfile READ privateProfile CONSTANT)
    Q_PROPERTY(QString version READ version CONSTANT)
    Q_PROPERTY(QString systemLanguage READ systemLanguage CONSTANT)
    Q_PROPERTY(bool blurAvailable READ blurAvailable CONSTANT)
public:
    explicit Backend(QObject *parent = nullptr);

    QObject *normalProfile() const;
    QObject *privateProfile() const;
    QString version() const { return QStringLiteral(APP_VERSION); }
    QString systemLanguage() const;
    bool blurAvailable() const;

    Q_INVOKABLE void setBlurBehind(QWindow *window, bool on, int radius = 0);
    Q_INVOKABLE void setAdblock(bool on);
    Q_INVOKABLE int blockedCount() const;
    Q_INVOKABLE QString downloadsDir() const;
    Q_INVOKABLE void openPath(const QString &path) const;
    Q_INVOKABLE void showInFolder(const QString &path) const;
    Q_INVOKABLE bool removeFile(const QString &path) const;
    Q_INVOKABLE void clearCookies();
    Q_INVOKABLE void clearCache();
    Q_INVOKABLE void resetPrivateProfile();
    Q_INVOKABLE void copyText(const QString &text) const;
    Q_INVOKABLE QString clipboardText() const;
    Q_INVOKABLE void saveScreenshot(QWindow *window, const QString &path);
    Q_INVOKABLE QString screenshotPath() const;
    Q_INVOKABLE void quitLater(int ms);

signals:
    // egy másik indítás címeket küldött (pl. link megnyitása más alkalmazásból)
    void urlsReceived(const QStringList &urls);

private:
    QQuickWebEngineProfile *makeProfile(bool persistent);
    QQuickWebEngineProfile *m_normal = nullptr;
    QQuickWebEngineProfile *m_private = nullptr;
    AdBlocker *m_adblock = nullptr;
};
