#include "adblock.h"
#include <QUrl>

static const char *kHosts[] = {
    "doubleclick.net", "googlesyndication.com", "googleadservices.com", "google-analytics.com",
    "googletagmanager.com", "googletagservices.com", "adservice.google.com", "pagead2.googlesyndication.com",
    "adnxs.com", "adsrvr.org", "amazon-adsystem.com", "criteo.com", "criteo.net", "taboola.com",
    "outbrain.com", "rubiconproject.com", "pubmatic.com", "openx.net", "casalemedia.com", "smartadserver.com",
    "scorecardresearch.com", "quantserve.com", "moatads.com", "adform.net", "adsafeprotected.com",
    "doubleverify.com", "teads.tv", "yieldmo.com", "media.net", "sharethrough.com", "bidswitch.net",
    "3lift.com", "triplelift.com", "indexww.com", "contextweb.com", "lijit.com", "sovrn.com",
    "zemanta.com", "revcontent.com", "mgid.com", "propellerads.com", "popads.net", "popcash.net",
    "adcolony.com", "applovin.com", "unityads.unity3d.com", "hotjar.com", "mixpanel.com",
    "segment.io", "segment.com", "fullstory.com", "mouseflow.com", "crazyegg.com", "clarity.ms",
    "facebook.net", "connect.facebook.net", "ads.linkedin.com", "analytics.twitter.com", "ads-twitter.com",
    "ads.yahoo.com", "advertising.com", "adtech.de", "serving-sys.com", "eyeblaster.com",
    "gemius.pl", "hit.gemius.pl", "adocean.pl", "etarget.hu", "gemhu.adocean.pl", "adverticum.net",
    "imasdk.googleapis.com", "ad.doubleclick.net", "stats.g.doubleclick.net", "yandex.ru/ads",
    "mc.yandex.ru", "an.yandex.ru", "branch.io", "app-measurement.com", "onesignal.com",
    "trafficjunky.net", "exoclick.com", "juicyads.com", "adskeeper.co.uk", "admitad.com",
};

AdBlocker::AdBlocker(QObject *parent) : QWebEngineUrlRequestInterceptor(parent) {
    for (const char *h : kHosts) m_hosts.insert(QString::fromLatin1(h));
}

void AdBlocker::interceptRequest(QWebEngineUrlRequestInfo &info) {
    if (!m_enabled) return;
    if (info.resourceType() == QWebEngineUrlRequestInfo::ResourceTypeMainFrame) return;
    QString host = info.requestUrl().host().toLower();
    // a host és minden szülő domainje
    while (!host.isEmpty()) {
        if (m_hosts.contains(host)) {
            info.block(true);
            ++m_blocked;
            return;
        }
        int dot = host.indexOf(QLatin1Char('.'));
        if (dot < 0) break;
        host = host.mid(dot + 1);
        if (host.indexOf(QLatin1Char('.')) < 0) break; // csak a TLD maradt
    }
}
