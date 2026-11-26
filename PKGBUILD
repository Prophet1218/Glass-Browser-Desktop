# Maintainer: Prophet1218
pkgname=glass-browser-desktop
pkgver=1.0.0
pkgrel=1
pkgdesc="Liquid glass web browser built on Chromium (Qt WebEngine) for KDE Plasma"
arch=('x86_64')
url="https://github.com/Prophet1218/Glass-Browser-Desktop"
license=('MIT')
depends=('qt6-base' 'qt6-declarative' 'qt6-webengine' 'kwindowsystem')
makedepends=('cmake' 'qt6-shadertools')
options=('!debug')

build() {
    cmake -B build -S "$startdir" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr
    cmake --build build -j"$(nproc)"
}

package() {
    DESTDIR="$pkgdir" cmake --install build
    install -Dm644 "$startdir/LICENSE" "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
}
