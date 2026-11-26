#pragma once
#include <QWebEngineUrlRequestInterceptor>
#include <QSet>
#include <atomic>

// Egyszerű, gyors reklám- és követőszűrő: ismert hirdetési / követő domainek kérései
// (és aldomainjeik) nem töltődnek le. A fő oldal betöltését soha nem tiltja.
class AdBlocker : public QWebEngineUrlRequestInterceptor {
    Q_OBJECT
public:
    explicit AdBlocker(QObject *parent = nullptr);
    void interceptRequest(QWebEngineUrlRequestInfo &info) override;
    void setEnabled(bool on) { m_enabled = on; }
    bool enabled() const { return m_enabled; }
    int blockedCount() const { return m_blocked; }
private:
    QSet<QString> m_hosts;
    std::atomic<bool> m_enabled{true};
    std::atomic<int> m_blocked{0};
};
