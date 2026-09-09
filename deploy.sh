#!/bin/bash
# 就地部署到 GitHub Pages（本目录 06_ke-xu-wedding 即仓库克隆）
# 用法：./deploy.sh "更新说明"
set -e
cd "$(dirname "$0")"
MSG="${1:-更新婚帖内容}"

echo "📦 1. 重新打包 invitation.html（内嵌照片+音乐） ..."
python3 <<'PYEOF'
import base64, os, re, pathlib
src = open('index.html', encoding='utf-8').read()
out = src
photo_dir = pathlib.Path('web_photos')
def to_data_uri(fn):
    p = photo_dir / fn
    ext = p.suffix.lstrip('.').lower()
    mime = 'image/jpeg' if ext in ('jpg','jpeg') else f'image/{ext}'
    return f"data:{mime};base64,{base64.b64encode(p.read_bytes()).decode('ascii')}"
for m in sorted(set(re.findall(r'web_photos/([\w\-.]+\.(?:jpg|jpeg|png))', src))):
    out = out.replace(f'web_photos/{m}', to_data_uri(m))
open('invitation.html','w',encoding='utf-8').write(out)
print(f"   ✓ invitation.html {os.path.getsize('invitation.html')/1024/1024:.2f} MB")
PYEOF

echo "📤 2. 提交并推送 GitHub Pages ..."
git add -A
if git diff --cached --quiet; then
  echo "   ⚠️  没有改动，跳过提交"; exit 0
fi
git commit -m "$MSG"
git push origin main
echo "   ✓ 已推送：https://bettermewonderfulu.github.io/ke-xu-wedding/"
