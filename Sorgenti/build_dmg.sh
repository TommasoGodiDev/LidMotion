#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
APP_BUNDLE="$BUILD_DIR/LidMotion.app"
DMG_NAME="LidMotion_1.0.0.dmg"
DMG_PATH="$BUILD_DIR/$DMG_NAME"
TEMP_DMG_DIR="$BUILD_DIR/dmg_temp"

echo "=== Creazione DMG per LidMotion ==="

# Verifica che l'app esista
if [ ! -d "$APP_BUNDLE" ]; then
    echo "Errore: LidMotion.app non trovata. Esegui prima build.sh."
    exit 1
fi

# Prepara la cartella temporanea per il DMG
rm -rf "$TEMP_DMG_DIR"
mkdir -p "$TEMP_DMG_DIR"
cp -R "$APP_BUNDLE" "$TEMP_DMG_DIR/"
ln -s /Applications "$TEMP_DMG_DIR/Applications"

# Rimuovi DMG esistente
rm -f "$DMG_PATH"

echo "Generazione immagine disco..."
hdiutil create -volname "LidMotion" -srcfolder "$TEMP_DMG_DIR" -ov -format UDZO "$DMG_PATH"

# Pulizia
rm -rf "$TEMP_DMG_DIR"

echo "=== DMG pronto: $DMG_PATH ==="
