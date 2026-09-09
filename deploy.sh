#!/bin/bash
# 一站式部署：GitHub Pages + 重建 cf-deploy（供 Cloudflare 上传）
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

echo "📤 2. 重建 cf-deploy（Cloudflare 部署包） ..."
python3 <<'PYEOF'
import os, re, shutil
shutil.rmtree('cf-deploy', ignore_errors=True)
os.makedirs('cf-deploy/web_photos', exist_ok=True)
os.makedirs('cf-deploy/music', exist_ok=True)
html = open('index.html', encoding='utf-8').read()
photos = sorted(set(re.findall(r'web_photos/([\w\-.]+\.(?:jpg|jpeg|png))', html)))
for fn in photos:
    shutil.copy(f'web_photos/{fn}', f'cf-deploy/web_photos/{fn}')
for fn in sorted(set(re.findall(r'music/([\w\-.]+\.mp3)', html))):
    shutil.copy(f'music/{fn}', f'cf-deploy/music/{fn}')
shutil.copy('index.html', 'cf-deploy/')
print(f"   ✓ cf-deploy: {len(photos)} 图, {shutil.disk_usage('cf-deploy') and 'ready'}")
PYEOF

echo "🚀 3. 提交并推送 GitHub Pages ..."
git add -A
if git diff --cached --quiet; then
  echo "   ⚠️  没有改动，跳过提交"; exit 0
fi
git commit -m "$MSG"
git push origin main
echo "   ✓ 已推送：https://bettermewonderfulu.github.io/ke-xu-wedding/"
echo ""
echo "☁️  Cloudflare: 请上传 cf-deploy/ 文件夹到 ourwedding → 部署 → 新部署"
