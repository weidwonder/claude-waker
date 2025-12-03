#!/bin/bash

# Claude Waker 安装脚本
# 支持 Linux 和 macOS

set -e

echo "======================================"
echo "   Claude Waker 安装脚本"
echo "======================================"
echo ""

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查操作系统
OS="$(uname -s)"
case "$OS" in
    Linux*)     OS_TYPE=Linux;;
    Darwin*)    OS_TYPE=Mac;;
    *)          echo -e "${RED}❌ 不支持的操作系统: $OS${NC}"; exit 1;;
esac

echo -e "${GREEN}✓${NC} 检测到操作系统: $OS_TYPE"

# 检查 uv 是否安装
echo ""
echo "检查 uv 安装..."
if ! command -v uv &> /dev/null; then
    echo -e "${RED}❌ 未找到 uv 命令${NC}"
    echo ""
    echo "请先安装 uv:"
    echo "  curl -LsSf https://astral.sh/uv/install.sh | sh"
    echo ""
    echo "或访问: https://github.com/astral-sh/uv"
    exit 1
fi
echo -e "${GREEN}✓${NC} uv 已安装: $(uv --version)"

# 检查 Python3
echo ""
echo "检查 Python 安装..."
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}❌ 未找到 python3 命令${NC}"
    exit 1
fi
echo -e "${GREEN}✓${NC} Python 已安装: $(python3 --version)"

# 检查配置文件
echo ""
echo "检查配置文件..."
if [ ! -f "config.yaml" ]; then
    echo -e "${YELLOW}⚠️  config.yaml 不存在${NC}"
    if [ -f "config.yaml.example" ]; then
        echo "正在从 config.yaml.example 创建 config.yaml..."
        cp config.yaml.example config.yaml
        echo -e "${GREEN}✓${NC} 已创建 config.yaml"
        echo ""
        echo -e "${YELLOW}请编辑 config.yaml 文件，填入你的 OAuth Token 和唤醒时间${NC}"
        echo "编辑完成后，请重新运行此脚本"
        exit 0
    else
        echo -e "${RED}❌ config.yaml.example 也不存在${NC}"
        exit 1
    fi
fi
echo -e "${GREEN}✓${NC} config.yaml 存在"

# 创建虚拟环境
echo ""
echo "创建虚拟环境..."
if [ -d ".venv" ]; then
    echo -e "${YELLOW}⚠️  虚拟环境已存在，跳过创建${NC}"
else
    uv venv
    echo -e "${GREEN}✓${NC} 虚拟环境创建完成"
fi

# 安装依赖
echo ""
echo "安装依赖..."
uv pip install -r requirements.txt
echo -e "${GREEN}✓${NC} 依赖安装完成"

# 验证配置
echo ""
echo "验证配置..."
PYTHON_BIN="$SCRIPT_DIR/.venv/bin/python3"

# 创建临时验证脚本
cat > /tmp/validate_config.py << 'EOF'
import sys
import yaml
from pathlib import Path

config_file = Path("config.yaml")
if not config_file.exists():
    print("❌ 配置文件不存在")
    sys.exit(1)

try:
    with open(config_file, 'r', encoding='utf-8') as f:
        config = yaml.safe_load(f)

    # 检查必需字段
    if not config.get('accounts'):
        print("❌ 配置文件缺少 accounts 字段")
        sys.exit(1)

    if not config.get('wake_hours'):
        print("❌ 配置文件缺少 wake_hours 字段")
        sys.exit(1)

    # 检查账号
    valid_accounts = 0
    for account in config['accounts']:
        token = account.get('token', '')
        if token and token not in ['your-oauth-token-here-1', 'your-oauth-token-here-2']:
            valid_accounts += 1

    if valid_accounts == 0:
        print("❌ 没有配置有效的 OAuth Token")
        print("请在 config.yaml 中填入真实的 token")
        sys.exit(1)

    print(f"✓ 配置验证通过，找到 {valid_accounts} 个有效账号")

    # 解析唤醒时间
    wake_hours = [int(h.strip()) for h in config['wake_hours'].split(',')]
    if not wake_hours or len(wake_hours) > 5:
        print("❌ wake_hours 格式错误（应为1-5个小时数）")
        sys.exit(1)

    for hour in wake_hours:
        if hour < 0 or hour > 23:
            print(f"❌ 无效的小时数: {hour}（应为0-23）")
            sys.exit(1)

    print(f"✓ 唤醒时间: {', '.join([f'{h}:05' for h in wake_hours])}")

    # 输出唤醒时间供 shell 脚本使用
    print(f"WAKE_HOURS={config['wake_hours']}")

except Exception as e:
    print(f"❌ 配置验证失败: {e}")
    sys.exit(1)
EOF

# 运行验证
VALIDATION_OUTPUT=$("$PYTHON_BIN" /tmp/validate_config.py)
VALIDATION_EXIT_CODE=$?
rm /tmp/validate_config.py

echo "$VALIDATION_OUTPUT" | grep -v "^WAKE_HOURS="

if [ $VALIDATION_EXIT_CODE -ne 0 ]; then
    echo ""
    echo -e "${RED}配置验证失败，请检查 config.yaml${NC}"
    exit 1
fi

# 提取唤醒时间
WAKE_HOURS=$(echo "$VALIDATION_OUTPUT" | grep "^WAKE_HOURS=" | cut -d'=' -f2)
echo -e "${GREEN}✓${NC} 配置验证通过"

# 设置 crontab
echo ""
echo "配置 crontab 任务..."
CRON_COMMAND="5 $WAKE_HOURS * * * cd $SCRIPT_DIR && $PYTHON_BIN waker.py"
CRON_COMMENT="# Claude Waker - Auto wake Claude accounts"

# 检查是否已存在
if crontab -l 2>/dev/null | grep -q "Claude Waker"; then
    echo -e "${YELLOW}⚠️  检测到已存在的 Claude Waker 任务${NC}"
    read -p "是否替换现有任务? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # 删除旧任务
        crontab -l 2>/dev/null | grep -v "Claude Waker" | crontab -
        echo "已删除旧任务"
    else
        echo "保留现有任务，跳过"
        exit 0
    fi
fi

# 添加新任务
(crontab -l 2>/dev/null; echo ""; echo "$CRON_COMMENT"; echo "$CRON_COMMAND") | crontab -
echo -e "${GREEN}✓${NC} Crontab 任务已添加"

echo ""
echo "======================================"
echo -e "${GREEN}✓ 安装完成！${NC}"
echo "======================================"
echo ""
echo "Crontab 任务:"
echo "  $CRON_COMMAND"
echo ""
echo "日志文件: $SCRIPT_DIR/waker.log"
echo ""
echo "提示:"
echo "  - 查看 crontab: crontab -l"
echo "  - 编辑配置: vim config.yaml"
echo "  - 手动测试: $PYTHON_BIN waker.py"
echo "  - 卸载任务: crontab -l | grep -v 'Claude Waker' | crontab -"
echo ""
