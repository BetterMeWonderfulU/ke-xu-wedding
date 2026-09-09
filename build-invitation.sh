#!/bin/bash
# 从 index.html 重新生成 invitation.html（资源全部内嵌）
# 用法：./build-invitation.sh
# 产物：invitation.html（单文件版，可直接发给亲友或离线使用）

set -e
cd "$(dirname "$0")"

echo "📦 1. 重新打包 invitation.html (内嵌所有照片+音乐) ..."
python3 <<'PYEOF'
import base64, os, re, pathlib
src = open('index.html', 'r', encoding='utf-8').read()
out = src

# 内嵌照片
photo_dir = pathlib.Path('web_photos')
def to_data_uri(fn):
    p = photo_dir / fn
    ext = p.suffix.lstrip('.').lower()
    mime = 'image/jpeg' if ext in ('jpg', 'jpeg') else f'image/{ext}'
    return f"data:{mime};base64,{base64.b64encode(p.read_bytes()).decode('ascii')}"

photos = sorted(set(re.findall(r'web_photos/([\w\-.]+\.jpg)', src)))
for fn in photos:
    out = out.replace(f'web_photos/{fn}', to_data_uri(fn))
print(f"   内嵌照片: {len(photos)} 张")

# 内嵌音乐
mp3 = pathlib.Path('music/concerto.mp3')
if mp3.exists():
    mp3_b64 = base64.b64encode(mp3.read_bytes()).decode('ascii')
    out = out.replace('"music/concerto.mp3"', f'"data:audio/mpeg;base64,{mp3_b64}"')
    print(f"   内嵌音乐: {mp3.stat().st_size/1024/1024:.2f} MB")
else:
    print("   ⚠️  music/concerto.mp3 不存在，跳过")

with open('invitation.html', 'w', encoding='utf-8') as f:
    f.write(out)

print(f"   ✓ invitation.html: {os.path.getsize('invitation.html')/1024/1024:.2f} MB")
PYEOF

echo ""
echo "📤 2. 同步到备份目录 ..."
BACKUP_DIR="backup-$(date +%Y%m%d-%H%M%S)"
LATEST_BACKUP=$(ls -dt backup-* 2>/dev/null | head -1)
if [ -n "$LATEST_BACKUP" ]; then
  cp invitation.html "$LATEST_BACKUP/invitation.html"
  echo "   ✓ 已同步到 $LATEST_BACKUP/invitation.html"
fi
