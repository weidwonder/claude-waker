# Claude Waker ⏰

Automatic Claude account scheduler for optimizing 5-hour usage quota windows | Claude Scheduler | Claude Wakeup Tool | Claude Auto Timer

> **自动唤醒 Claude 账号，优化 5 小时限额使用窗口**
>
> English Documentation | [中文文档](README.md)

**Keywords**: claude scheduler | claude wakeup | claude timer | claude automation | claude quota optimizer | claude auto wake | claude cron | claude pro optimizer | claude max tool

## 📖 Background

### The Problem

Claude Pro/Max accounts have a usage limit every 5 hours, but this limit **doesn't reset at fixed times** - it starts counting from **your first use**.

This can prevent you from maximizing your quota. For example:

- Work hours: 9:30-12:00, 13:30-18:30
- If you first use Claude at 10:00 and quickly exhaust the quota
- You can't use it until 3:00 PM (wasting your afternoon work time)

### The Solution

By automatically sending messages at **fixed time points** to "wake up" Claude, you can proactively trigger timing windows and optimize usage time:

- 7:05 AM auto wake → 12:00 PM reset
- 12:05 PM auto wake → 5:00 PM reset
- 5:05 PM auto wake → 10:00 PM reset

**Why :05 minutes?** Claude's 5-hour quota counts by **whole hours** (e.g., 7:00-12:00). Sending a message at 7:05 doesn't waste those 5 minutes because the timer already started at 7:00. Using :05 ensures cron jobs trigger reliably.

This way you can maximize your quota during work hours!

## ✨ Features

**🎯 Core Advantages**:
- 🚀 **Manage Multiple Claude Accounts** - Unlike most online tools that only support single accounts, this tool can wake all your accounts at once
- ⚡ **Ultra Lightweight** - Single Python file + minimal dependencies, no complex configuration, extremely low resource usage
- 🎨 **Simple to Use** - One-click installation, automatic configuration, no programming knowledge required

**Complete Features**:
- ✅ Support multiple Claude accounts simultaneously
- ✅ Customizable wake times (up to 5 time points)
- ✅ Automatic crontab scheduling (claude scheduler)
- ✅ Minimized API requests (short prompt + fast timeout)
- ✅ Detailed logging
- ✅ Error handling (single account failure doesn't affect others)
- ✅ Supports Linux and macOS

## 🚀 Quick Start

### Deployment Recommendations

**Recommended Deployment Environment**:
- 🖥️ **Always-on Machine**: Home NAS, cloud server, personal computer, or any 24/7 running device
- 💻 **Operating System**: macOS or Linux (Ubuntu/Debian recommended)
- ⚠️ **Note**: If deploying on a personal computer, keep it powered on to ensure scheduled tasks run properly

**Why an always-on machine?**
The program runs via crontab scheduled tasks, which cannot execute when the machine is off. Recommended deployment on servers, NAS, Raspberry Pi, or other always-on devices.

### Prerequisites

1. **Python 3.8+**
2. **uv** (Fast Python package manager)
   ```bash
   curl -LsSf https://astral.sh/uv/install.sh | sh
   ```
3. **Claude CLI** (For obtaining OAuth Token)
   ```bash
   npm install -g @anthropic-ai/claude-code
   ```

### Installation Steps

#### 1. Get OAuth Token

Obtain OAuth Token for each Claude account:

```bash
# Get token for first account
claude setup-token
```

This will open a browser for authentication. After completion, the token will be output in the terminal, like:

```
Your OAuth token: eyJhbGc...(long string)
```

**Copy and save this token**.

If you have multiple accounts, log out and repeat:
```bash
# Log out of Claude in the browser
# Run again to get another account's token
claude setup-token
```

#### 2. Clone and Configure Project

```bash
# Clone or download project
cd claude_waker

# Run installation script
./setup.sh
```

First run of `setup.sh` will automatically create `config.yaml` and prompt you to edit the configuration.

#### 3. Edit Configuration File

Edit `config.yaml`:

```yaml
# Claude account list
accounts:
  - name: "Main Account"
    token: "eyJhbGc...(first account token)"
  - name: "Backup Account"
    token: "eyJhbGc...(second account token)"

# Wake hours (0-23)
# Actual trigger time is :05 of each hour
wake_hours: "7,12,17"  # Wake at 7:05, 12:05, 17:05
```

#### 4. Complete Installation

After editing configuration, run the installation script again:

```bash
./setup.sh
```

The installation script will:
- ✓ Create virtual environment (using uv)
- ✓ Install dependencies
- ✓ Validate configuration and tokens
- ✓ Automatically configure crontab scheduled tasks

## 📝 Usage Instructions

### Automatic Execution

After installation, the program will automatically run at specified times without manual intervention.

### Manual Testing

Test if the program works properly:

```bash
.venv/bin/python3 waker.py
```

### View Logs

```bash
tail -f waker.log
```

Log example:
```
[2025-12-03 07:05:01] ============================================================
[2025-12-03 07:05:01] Claude Waker starting
[2025-12-03 07:05:01] ✓ Detected OS: Mac
[2025-12-03 07:05:01] Starting wake task for 2 accounts
[2025-12-03 07:05:01] Waking account: Main Account
[2025-12-03 07:05:03] ✅ Main Account - Wake successful
[2025-12-03 07:05:05] Waking account: Backup Account
[2025-12-03 07:05:07] ✅ Backup Account - Wake successful
[2025-12-03 07:05:07] ------------------------------------------------------------
[2025-12-03 07:05:07] Wake task complete: 2 successful, 0 failed
[2025-12-03 07:05:07] ============================================================
```

### View Crontab Task

```bash
crontab -l | grep "Claude Waker"
```

### Modify Wake Times

1. Edit `wake_hours` in `config.yaml`
2. Re-run `./setup.sh` to update crontab

### Uninstall

Remove crontab task:

```bash
crontab -l | grep -v "Claude Waker" | crontab -
```

## ⚙️ Configuration Guide

### config.yaml

| Field | Description | Format |
|------|------|------|
| `accounts` | Claude account list | Array, each account contains `name` and `token` |
| `wake_hours` | Wake times | String, comma-separated hours (0-23), max 5 |

### Wake Time Examples

```yaml
# Morning, noon, evening
wake_hours: "7,12,17"

# Before work, after lunch, before leaving work
wake_hours: "9,14,18"

# Only morning on weekdays (manually modify crontab to add weekday restriction)
wake_hours: "9"
```

**Note**: Actual trigger time is **:05** of each hour (e.g., 7:05, 12:05). This doesn't waste 5 minutes of quota because Claude counts from the whole hour.

## 🔧 Advanced Usage

### Restrict to Weekdays

Manually edit crontab to add weekday restriction:

```bash
crontab -e
```

Modify Claude Waker task to:

```cron
# Claude Waker - Auto wake Claude accounts (weekdays only)
5 7,12,17 * * 1-5 cd /path/to/claude_waker && .venv/bin/python3 waker.py
```

`1-5` means Monday through Friday.

### Custom Log Location

Modify the `LOG_FILE` variable in `waker.py`:

```python
LOG_FILE = Path("/your/custom/path/waker.log")
```

### Adjust Timeout

Modify timeout setting in `waker.py`:

```python
async with asyncio.timeout(60):  # Change to desired seconds
```

## ❓ FAQ

### Q: How to verify if token is valid?

Run `./setup.sh`, the script will automatically validate tokens.

Or test manually:
```bash
.venv/bin/python3 waker.py
```

### Q: Program not running on schedule?

1. Check if crontab is correct: `crontab -l | grep "Claude Waker"`
2. Verify system time is correct: `date`
3. Check log file: `tail -f waker.log`
4. Ensure cron service is running (macOS requires terminal authorization)

### Q: What if token expires?

Re-obtain token and update `config.yaml`:

```bash
claude setup-token
# Copy new token to config.yaml
```

### Q: How to add more accounts?

Add new accounts in `config.yaml`:

```yaml
accounts:
  - name: "Account 1"
    token: "token1"
  - name: "Account 2"
    token: "token2"
  - name: "Account 3"  # New
    token: "token3"
```

No need to re-run `setup.sh`.

### Q: Can I have more than 5 wake times?

Technically yes, but 5 is recommended. Just modify `wake_hours`:

```yaml
wake_hours: "6,9,12,15,18,21"  # 6 time points
```

### Q: Log file too large?

Use logrotate or manual cleanup:

```bash
# Manually clear log
> waker.log

# Or keep last 100 lines
tail -100 waker.log > waker.log.tmp && mv waker.log.tmp waker.log
```

### Q: Cron doesn't have permission on macOS?

macOS requires terminal authorization:

1. System Preferences → Security & Privacy → Privacy → Full Disk Access
2. Add `/usr/sbin/cron` or your terminal application

## 📄 Project Structure

```
claude_waker/
├── waker.py              # Main program
├── setup.sh              # Installation script
├── config.yaml           # Configuration file (manual creation)
├── config.yaml.example   # Configuration example
├── requirements.txt      # Python dependencies
├── .gitignore
├── .venv/               # Virtual environment (created by setup.sh)
├── waker.log            # Log file (auto-generated)
├── README.md            # Chinese documentation
└── README.en.md         # This file
```

## 🔗 Related Links

- [Claude Code Documentation](https://docs.claude.com/en/docs/claude-code)
- [Claude Agent SDK](https://docs.claude.com/en/api/agent-sdk/overview)
- [uv - Python Package Manager](https://github.com/astral-sh/uv)
- [Reference Project - claude-oauth-demo](https://github.com/anthropics/claude-agent-sdk-python)

## 📜 License

MIT

## 🙏 Acknowledgments

This project references the OAuth authentication implementation from [claude-oauth-demo](../claude-oauth-demo).

---

**Enjoy! Maximize every minute of your Claude Pro/Max quota!** 🚀
