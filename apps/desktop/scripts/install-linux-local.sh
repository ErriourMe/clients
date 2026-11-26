#!/bin/sh
set -eu

DESKTOP_DIR=$(cd "$(dirname "$0")/.." && pwd)
ROOT_DIR=$(cd "$DESKTOP_DIR/../.." && pwd)
PREFIX="${PREFIX:-$HOME/.local}"
APP_DIR="$PREFIX/opt/bitwarden"

cd "$ROOT_DIR"
if [ ! -f node_modules/.package-lock.json ] || [ package-lock.json -nt node_modules/.package-lock.json ]; then
  npm ci
fi

cd "$DESKTOP_DIR"
npm run build-native
npm run build
npx electron-builder --linux dir --x64 -p never

rm -rf "$APP_DIR"
mkdir -p "$PREFIX/opt" "$PREFIX/bin" "$PREFIX/share/applications"
cp -a dist/linux-unpacked "$APP_DIR"
ln -sf "$APP_DIR/bitwarden" "$PREFIX/bin/bitwarden"

for icon in resources/icons/*.png; do
  size=$(basename "$icon" .png)
  mkdir -p "$PREFIX/share/icons/hicolor/$size/apps"
  cp "$icon" "$PREFIX/share/icons/hicolor/$size/apps/com.bitwarden.desktop.png"
done

sed -e "s|^Exec=bitwarden |Exec=$APP_DIR/bitwarden |" -e "s|^StartupWMClass=.*|StartupWMClass=Bitwarden|" \
  resources/com.bitwarden.desktop.desktop > "$PREFIX/share/applications/bitwarden.desktop"

for manifest in "$HOME"/.mozilla/native-messaging-hosts/com.8bit.bitwarden.json \
  "$HOME"/.config/*/NativeMessagingHosts/com.8bit.bitwarden.json; do
  [ -f "$manifest" ] && sed -i "s|\"path\": \"[^\"]*\"|\"path\": \"$APP_DIR/desktop_proxy\"|" "$manifest"
done

update-desktop-database "$PREFIX/share/applications" 2>/dev/null || true
gtk-update-icon-cache -q "$PREFIX/share/icons/hicolor" 2>/dev/null || true
xdg-mime default bitwarden.desktop x-scheme-handler/bitwarden 2>/dev/null || true

echo "Installed to $APP_DIR"
