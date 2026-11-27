
#!/usr/bin/env bash
set -euo pipefail

ICON="app/icon.jpg"
RES="android/app/src/main/res"
MANIFEST="android/app/src/main/AndroidManifest.xml"

# Detect ImageMagick
if command -v magick >/dev/null 2>&1; then
  IM_CMD="magick"
elif command -v convert >/dev/null 2>&1; then
  IM_CMD="convert"
else
  echo "ERROR: ImageMagick is not installed!"
  exit 1
fi

# Check required files
if [ ! -s "$ICON" ]; then
  echo "ERROR: app/icon.jpg is missing or empty"
  exit 1
fi

if [ ! -f "$MANIFEST" ]; then
  echo "ERROR: AndroidManifest.xml not found"
  exit 1
fi

# Create Android resource folders
mkdir -p "$RES/drawable-nodpi"
mkdir -p "$RES/mipmap-mdpi"
mkdir -p "$RES/mipmap-hdpi"
mkdir -p "$RES/mipmap-xhdpi"
mkdir -p "$RES/mipmap-xxhdpi"
mkdir -p "$RES/mipmap-xxxhdpi"
mkdir -p "$RES/mipmap-anydpi-v26"
mkdir -p "$RES/values"

echo "Generating KATRO launcher icons..."

# Generate standard launcher icons
"$IM_CMD" "$ICON" -strip -resize 48x48! \
  "$RES/mipmap-mdpi/ic_launcher.png"

"$IM_CMD" "$ICON" -strip -resize 72x72! \
  "$RES/mipmap-hdpi/ic_launcher.png"

"$IM_CMD" "$ICON" -strip -resize 96x96! \
  "$RES/mipmap-xhdpi/ic_launcher.png"

"$IM_CMD" "$ICON" -strip -resize 144x144! \
  "$RES/mipmap-xxhdpi/ic_launcher.png"

"$IM_CMD" "$ICON" -strip -resize 192x192! \
  "$RES/mipmap-xxxhdpi/ic_launcher.png"

# Generate round launcher icons
for density in mdpi hdpi xhdpi xxhdpi xxxhdpi; do
  cp "$RES/mipmap-$density/ic_launcher.png" \
     "$RES/mipmap-$density/ic_launcher_round.png"
done

# Generate adaptive icon foreground
"$IM_CMD" "$ICON" -strip \
  -resize 324x324 \
  -gravity center \
  -background none \
  -extent 432x432 \
  "$RES/drawable-nodpi/ic_launcher_foreground.png"

# Set KATRO background color
cat > "$RES/values/katro_icon_colors.xml" <<'EOF'
<resources>
    <color name="katro_icon_background">#FFFFFF</color>
</resources>
EOF

# Adaptive launcher icon
cat > "$RES/mipmap-anydpi-v26/ic_launcher.xml" <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/katro_icon_background"/>
    <foreground android:drawable="@drawable/ic_launcher_foreground"/>
</adaptive-icon>
EOF

# Adaptive round launcher icon
cat > "$RES/mipmap-anydpi-v26/ic_launcher_round.xml" <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/katro_icon_background"/>
    <foreground android:drawable="@drawable/ic_launcher_foreground"/>
</adaptive-icon>
EOF

# Link KATRO icons in AndroidManifest
python3 - <<'PY'
from pathlib import Path
import re

manifest = Path("android/app/src/main/AndroidManifest.xml")
content = manifest.read_text(encoding="utf-8")

match = re.search(r"<application\b[^>]*>", content, flags=re.DOTALL)

if not match:
    raise SystemExit("ERROR: application tag not found")

tag = match.group(0)

tag = re.sub(r'\s+android:icon\s*=\s*"[^"]*"', '', tag)
tag = re.sub(r'\s+android:roundIcon\s*=\s*"[^"]*"', '', tag)

tag = tag[:-1] + (
    ' android:icon="@mipmap/ic_launcher"'
    ' android:roundIcon="@mipmap/ic_launcher_round">'
)

content = content[:match.start()] + tag + content[match.end():]

manifest.write_text(content, encoding="utf-8")

print("KATRO icon linked successfully!")
PY

# Verify generated files
for file in \
  "$RES/mipmap-mdpi/ic_launcher.png" \
  "$RES/mipmap-hdpi/ic_launcher.png" \
  "$RES/mipmap-xhdpi/ic_launcher.png" \
  "$RES/mipmap-xxhdpi/ic_launcher.png" \
  "$RES/mipmap-xxxhdpi/ic_launcher.png" \
  "$RES/mipmap-anydpi-v26/ic_launcher.xml" \
  "$RES/mipmap-anydpi-v26/ic_launcher_round.xml" \
  "$RES/drawable-nodpi/ic_launcher_foreground.png" \
  "$RES/values/katro_icon_colors.xml"; do

  if [ ! -s "$file" ]; then
    echo "ERROR: Missing resource: $file"
    exit 1
  fi

done

echo "=================================="
echo "KATRO ICON GENERATED SUCCESSFULLY"
echo "=================================="
