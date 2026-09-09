#!/bin/bash
set -e

echo "=== Story App - GitHub 仓库初始化脚本 ==="
echo ""

# 检查是否已经是 git 仓库
if [ -d .git ]; then
  echo "✓ 已经是 git 仓库"
  git remote -v
  echo ""
  echo "→ 添加所有修改..."
  git add .
  git status --short
else
  echo "→ 初始化 git 仓库..."
  git init
  echo "✓ git 仓库已初始化"
  echo ""
  echo "→ 添加所有文件..."
  git add .
fi

echo ""
echo "→ 创建提交..."
git commit -m "fix: 修复 iOS 构建 + 添加免费双平台构建 workflow

- 升级 connectivity_plus 7.3.0 → 7.3.1（修复 Xcode 16 兼容性）
- 新增 build-both-platforms.yml：同时构建 APK + iOS 模拟器
- 新增 build-story-ipa.yml：付费方案的 TestFlight 上传
- 文档：cicd.md（完整流程）、build-free.md（免费方案指南）

Fixes: iOS 构建报错 'isUltraConstrained' member not found
" || echo "（可能没有需要提交的更改）"

echo ""
echo "✓ 本地 git 仓库准备完成"
echo ""
echo "=== 下一步：推送到 GitHub ==="
echo ""
echo "1. 在 GitHub 创建新仓库（https://github.com/new）"
echo "   - 仓库名建议：story-fun-app"
echo "   - 可见性：Public（免费无限 Actions）或 Private（2000 分钟/月）"
echo "   - 不要勾选 'Initialize with README'（已有本地代码）"
echo ""
echo "2. 创建后，复制仓库 URL（如 https://github.com/你的用户名/story-fun-app.git）"
echo ""
echo "3. 执行以下命令推送代码："
echo ""
echo "   git remote add origin https://github.com/你的用户名/story-fun-app.git"
echo "   git branch -M main"
echo "   git push -u origin main"
echo ""
echo "4. 推送成功后，访问仓库 → Actions 标签页 → 选择 'Build APK + iOS (Free)' → Run workflow"
echo ""
