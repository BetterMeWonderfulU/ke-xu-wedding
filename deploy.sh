#!/bin/bash
# 就地部署到 GitHub Pages（本目录即为 ke-xu-wedding 仓库克隆）
# 用法：./deploy.sh "更新说明"
set -e
cd "$(dirname "$0")"
MSG="${1:-更新婚帖内容}"

# 工作源从 Pictures 同步最新 index.html + web_photos + music（若存在源）
SRC="/Users/changyu/Pictures/电子请帖"
if [ -f "$SRC/index.html" ]; then
  echo "📥 1. 从源同步最新文件 ..."
  cp "$SRC/index.html" ./index.html
  mkdir -p web_photos music
  cp "$SRC"/web_photos/*.jpg web_photos/ 2>/dev/null || true
  cp "$SRC"/music/*.mp3 music/ 2>/dev/null || true
fi

echo "📤 2. 提交并推送 GitHub Pages ..."
git add -A
if git diff --cached --quiet; then
  echo "   ⚠️  没有改动，跳过提交"
  exit 0
fi
git commit -m "$MSG"
git push origin main
echo "   ✓ 已推送"
echo ""
echo "🌐 1-2 分钟后刷新：https://bettermewonderfulu.github.io/ke-xu-wedding/"
