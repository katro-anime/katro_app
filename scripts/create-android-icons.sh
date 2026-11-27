
#!/usr/bin/env bash
set -euo pipefail

ICON="app/icon.jpg"
RES="android/app/src/main/res"

if [ ! -f "$ICON" ]; then
  echo "ERROR: app/icon.jpg not found"
  exit 1
fi

mkdir -p "$RES/drawable-nodpi"
mkdir -p "$RES/mipmap-mdpi"
mkdir -p "$RES/mipmap-hdpi"
mkdir -p "$RES/mipmap-xhdpi"
mkdir -p "$RES/mipmap-xxhdpi"
mkdir -p "$RES/mipmap-xxxhdpi"
mkdir -p "$RES/mipmap-anydpi-v26"
mkdir -p "$RES/values"

echo "Generating KATRO icons..."

# Standard Android icons
convert "$ICON" -strip -resize 48x48! "$RES/mipmap-mdpi/ic_launcher.png"
convert "$ICON" -strip -resize 72x72! "$RES/mipmap-hdpi/ic_launcher.png"
convert "$ICON" -strip -resize 96x96! "$RES/mipmap-xhdpi/ic_launcher.png"
convert "$ICON" -strip -resize 144x144! "$RES/mipmap-xxhdpi/ic_launcher.png"
convert "$ICON" -strip -resize 192x192! "$RES/mipmap-xxxhdpi/ic_launcher.png"

# Round icons
for density in mdpi hdpi xhdpi xxhdpi xxxhdpi; do
  cp "$RES/mipmap-$density/ic_launcher.png" \
     "$RES/mipmap-$density/ic_launcher_round.png"
done

# Adaptive icon foreground
convert "$ICON" -strip \
  -resize 324x324 \
  -gravity center \
  -background none \
  -extent 432x432 \
  "$RES/drawable-nodpi/ic_launcher_foreground.png"

# KATRO unique background color
cat > "$RES/values/katro_icon_colors.xml" <<'EOF'
<resources>
    <color name="katro_icon_background">#FFFFFF</color>
</resources>
EOF

# Adaptive icon XML
cat > "$RES/mipmap-anydpi-v26/ic_launcher.xml" <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/katro_icon_background"/>
    <foreground android:drawable="@drawable/ic_launcher_foreground"/>
</adaptive-icon>
EOF

cat > "$RES/mipmap-anydpi-v26/ic_launcher_round.xml" <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/katro_icon_background"/>
    <foreground android:drawable="@drawable/ic_launcher_foreground"/>
</adaptive-icon>
EOF

# Link KATRO icon to AndroidManifest
python3 - <<'PY'
from pathlib import Path
import re

manifest = Path("android/app/src/main/AndroidManifest.xml")

if not manifest.exists():
    raise SystemExit("AndroidManifest.xml not found")

content = manifest.read_text(encoding="utf-8")
match = re.search(r"<application\b[^>]*>", content)

if not match:
    raise SystemExit("Application tag not found")

tag = match.group(0)
tag = re.sub(r'\s+android:icon="[^"]*"', '', tag)
tag = re.sub(r'\s+android:roundIcon="[^"]*"', '', tag)

tag = tag[:-1] + (
    ' android:icon="@mipmap/ic_launcher"'
    ' android:roundIcon="@mipmap/ic_launcher_round">'
)

content = content[:match.start()] + tag + content[match.end():]
manifest.write_text(content, encoding="utf-8")

print("KATRO icon successfully linked to AndroidManifest")
PY

# Verify icon files
test -f "$RES/mipmap-mdpi/ic_launcher.png"
test -f "$RES/mipmap-hdpi/ic_launcher.png"
test -f "$RES/mipmap-xhdpi/ic_launcher.png"
test -f "$RES/mipmap-xxhdpi/ic_launcher.png"
test -f "$RES/mipmap-xxxhdpi/ic_launcher.png"
test -f "$RES/mipmap-anydpi-v26/ic_launcher.xml"
test -f "$RES/mipmap-anydpi-v26/ic_launcher_round.xml"
test -f "$RES/drawable-nodpi/ic_launcher_foreground.png"
test -f "$RES/values/katro_icon_colors.xml"

echo "KATRO icons generated and verified successfully!"
