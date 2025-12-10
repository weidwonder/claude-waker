#!/usr/bin/env python3
"""
Claude Waker - 自动唤醒 Claude 账号以优化5小时限额窗口
"""

import os
import sys
import asyncio
import logging
from datetime import datetime
from pathlib import Path
import yaml

# 设置日志
LOG_FILE = Path(__file__).parent / "waker.log"
logging.basicConfig(
    level=logging.INFO,
    format='[%(asctime)s] %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S',
    handlers=[
        logging.FileHandler(LOG_FILE, encoding='utf-8'),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)


def load_config():
    """加载配置文件"""
    config_file = Path(__file__).parent / "config.yaml"

    if not config_file.exists():
        logger.error(f"❌ 配置文件不存在: {config_file}")
        logger.error("请复制 config.yaml.example 为 config.yaml 并填入配置")
        sys.exit(1)

    try:
        with open(config_file, 'r', encoding='utf-8') as f:
            config = yaml.safe_load(f)

        # 验证配置
        if not config.get('accounts'):
            logger.error("❌ 配置文件缺少 accounts 字段")
            sys.exit(1)

        if not config.get('wake_hours'):
            logger.error("❌ 配置文件缺少 wake_hours 字段")
            sys.exit(1)

        return config
    except Exception as e:
        logger.error(f"❌ 读取配置文件失败: {e}")
        sys.exit(1)


async def wake_account_subprocess(account_name, oauth_token):
    """在子进程中唤醒单个账号，确保 token 完全隔离"""
    try:
        logger.info(f"正在唤醒账号: {account_name}")

        # 创建子进程脚本
        script = f'''
import os
import asyncio

async def run():
    os.environ['CLAUDE_CODE_OAUTH_TOKEN'] = {repr(oauth_token)}
    from claude_agent_sdk import query

    try:
        async with asyncio.timeout(60):
            gen = query(prompt='hi')
            async for msg in gen:
                msg_type = type(msg).__name__
                if 'SystemMessage' not in msg_type:
                    print(f"SUCCESS:{{msg_type}}")
                    return
            print("ERROR:未收到有效响应")
    except asyncio.TimeoutError:
        print("TIMEOUT:响应超时")
    except Exception as e:
        print(f"ERROR:{{e}}")

asyncio.run(run())
'''

        # 运行子进程
        process = await asyncio.create_subprocess_exec(
            sys.executable, '-c', script,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE
        )

        try:
            stdout, stderr = await asyncio.wait_for(process.communicate(), timeout=70)
            output = stdout.decode('utf-8').strip()

            if 'SUCCESS:' in output:
                msg_type = output.split('SUCCESS:')[1]
                logger.info(f"✅ {account_name} - 唤醒成功，收到响应: {msg_type}")
                return True
            elif 'TIMEOUT:' in output:
                logger.warning(f"⚠️  {account_name} - 响应超时（60秒），但唤醒请求已发送")
                return True
            else:
                error_msg = output.split('ERROR:')[1] if 'ERROR:' in output else output
                logger.error(f"❌ {account_name} - 唤醒失败: {error_msg}")
                return False

        except asyncio.TimeoutError:
            process.kill()
            logger.warning(f"⚠️  {account_name} - 子进程超时")
            return False

    except Exception as e:
        logger.error(f"❌ {account_name} - 唤醒失败: {e}")
        return False


async def main():
    """主函数"""
    logger.info("=" * 60)
    logger.info("Claude Waker 开始运行")

    # 加载配置
    config = load_config()

    logger.info(f"开始唤醒任务，共 {len(config['accounts'])} 个账号")

    # 统计结果
    success_count = 0
    fail_count = 0

    # 遍历所有账号
    for idx, account in enumerate(config['accounts']):
        account_name = account.get('name', '未命名账号')
        oauth_token = account.get('token', '')

        if not oauth_token or oauth_token == 'your-oauth-token-here-1' or oauth_token == 'your-oauth-token-here-2':
            logger.warning(f"⚠️  {account_name} - Token 未配置，跳过")
            fail_count += 1
            continue

        # 使用子进程唤醒账号，确保 token 完全隔离
        try:
            success = await wake_account_subprocess(account_name, oauth_token)
            if success:
                success_count += 1
            else:
                fail_count += 1
        except Exception as e:
            logger.error(f"❌ {account_name} - 任务执行失败: {e}")
            fail_count += 1

        # 账号之间间隔2秒
        if idx < len(config['accounts']) - 1:
            await asyncio.sleep(2)

    # 输出统计
    logger.info("-" * 60)
    logger.info(f"唤醒任务完成: 成功 {success_count} 个，失败 {fail_count} 个")
    logger.info("=" * 60)


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        logger.info("\n程序被用户中断")
    except Exception as e:
        logger.error(f"程序异常: {e}")
        sys.exit(1)
