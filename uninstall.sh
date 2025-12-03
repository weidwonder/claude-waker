#!/bin/bash

# Claude Waker 卸载脚本
# 支持 Linux 和 macOS

set -e

echo "======================================"
echo "   Claude Waker 卸载脚本"
echo "======================================"
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查是否存在 Claude Waker 任务
echo "检查 crontab 任务..."
if ! crontab -l 2>/dev/null | grep -q "Claude Waker"; then
    echo -e "${YELLOW}⚠️  未找到 Claude Waker 的 crontab 任务${NC}"
    echo "可能已经卸载或从未安装"
    exit 0
fi

# 显示当前任务
echo ""
echo "找到以下 Claude Waker 任务:"
echo "----------------------------------------"
crontab -l 2>/dev/null | grep -A 1 "Claude Waker" || true
echo "----------------------------------------"
echo ""

# 确认卸载
read -p "确认删除这些任务吗? (y/n) " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "已取消卸载"
    exit 0
fi

# 删除任务
echo ""
echo "正在删除 crontab 任务..."

# 获取当前 crontab，删除包含 "Claude Waker" 的行及其后一行（任务命令）
TEMP_CRON=$(mktemp)
crontab -l 2>/dev/null | grep -B 0 -A 1 "Claude Waker" > "$TEMP_CRON" || true

if [ -s "$TEMP_CRON" ]; then
    # 使用临时文件来安全地删除
    crontab -l 2>/dev/null | grep -v "Claude Waker" | grep -v -F -f <(cat "$TEMP_CRON" | grep -v "Claude Waker") | crontab - 2>/dev/null || true
fi

rm -f "$TEMP_CRON"

# 验证删除
if crontab -l 2>/dev/null | grep -q "Claude Waker"; then
    echo -e "${RED}❌ 删除失败，请手动检查 crontab${NC}"
    echo "运行: crontab -e"
    exit 1
else
    echo -e "${GREEN}✓${NC} Crontab 任务已删除"
fi

echo ""
echo "======================================"
echo -e "${GREEN}✓ 卸载完成！${NC}"
echo "======================================"
echo ""
echo "提示:"
echo "  - 项目文件和配置仍然保留"
echo "  - 如需完全删除，请手动删除项目目录"
echo "  - 如需重新安装，请运行: ./setup.sh"
echo ""
