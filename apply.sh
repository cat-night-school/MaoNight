#!/usr/bin/env bash
# 猫夜定制：源码级资源替换（仓库根目录即可运行）
set -e
DOPA="$1"
[ -z "$DOPA" ] && { echo "usage: apply.sh <dopamine-repo>"; exit 1; }
KIT="$(cd "$(dirname "$0")" && pwd)"
APP="$DOPA/Application/Dopamine"
ASSETS="$APP/Assets.xcassets"

TITLE="${TITLE:-猫夜}"
AUTHOR="${AUTHOR:-王关喆}"
BG="${BG:-zhbai}"

ICON_SRC=""
for c in "$KIT/assets/icon.png" "$KIT/icon.png"; do
  [ -f "$c" ] && ICON_SRC="$c" && break
done

BG_SRC=""
for c in "$KIT/assets/background-$BG.jpg" "$KIT/assets/background.jpg" "$KIT/bg.jpg"; do
  [ -f "$c" ] && BG_SRC="$c" && break
done

echo "==> 参数 title=$TITLE author=$AUTHOR bg=$BG"
echo "==> 图标: ${ICON_SRC:-未找到}"
echo "==> 背景: ${BG_SRC:-未找到}"

if [ -n "$ICON_SRC" ] && [ -d "$ASSETS/AppIcon.appiconset" ]; then
  echo "==> app icons"
  cd "$ASSETS/AppIcon.appiconset"
  while read -r name size; do
    [ -z "$name" ] && continue
    sips -s format png -z "$size" "$size" "$ICON_SRC" --out "$name" >/dev/null 2>&1 || true
  done <<'EOF'
Icon-38@2x.png 76
Icon-38@3x.png 114
Icon-60@3x.png 180
Icon-64@2x.png 128
Icon-64@3x.png 192
Icon-68@2x.png 136
Icon-76@2x.png 152
Icon-83.5@2x.png 167
Icon-Notification@2x.png 40
Icon-Notification@3x.png 60
Icon-Small-40@2x.png 80
Icon-Small-40@3x.png 120
Icon-Small@2x.png 58
Icon-Small@3x.png 87
EOF
fi

if [ -n "$BG_SRC" ]; then
  echo "==> backgrounds"
  n=0
  for d in "$ASSETS"/Background*imageset; do
    [ -d "$d" ] || continue
    jpg=$(ls "$d"/*.jpg 2>/dev/null | head -1)
    [ -z "$jpg" ] && continue
    sips -s format jpeg "$BG_SRC" --out "$jpg" >/dev/null 2>&1 && n=$((n+1)) || true
  done
  echo "    替换背景 $n 张"
fi

echo "==> 顶部标题"
grep -rl '@"Dopamine"' "$APP" 2>/dev/null | while read -r f; do
  sed -i '' "s/@\"Dopamine\"/@\"$TITLE\"/g" "$f" 2>/dev/null || sed -i "s/@\"Dopamine\"/@\"$TITLE\"/g" "$f"
done

echo "==> strings"
for f in "$APP"/*.lproj/Localizable.strings; do
  [ -f "$f" ] || continue
  sed -i '' "s/Dopamine/$TITLE/g" "$f" 2>/dev/null || sed -i "s/Dopamine/$TITLE/g" "$f"
done

echo "==> display name"
plutil -replace CFBundleDisplayName -string "$TITLE" "$APP/Info.plist" 2>/dev/null || true
plutil -replace CFBundleName -string "Maonight" "$APP/Info.plist" 2>/dev/null || true

echo "==> done"
