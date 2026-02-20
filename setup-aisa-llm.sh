#!/bin/bash
#
# AISA Unified Model Setup for OpenClaw
# Interactive script to configure AISA API as the LLM backend
#
# Usage:
#   Local:   ./setup-aisa.sh [--lang en|zh] [--key sk-xxxx] [--model 1-5]
#   Remote:  curl -fsSL https://cdn.aisa.one/setup.sh | bash
#   With args: curl -fsSL https://cdn.aisa.one/setup.sh | bash -s -- --key sk-xxx --model 1
#

set -euo pipefail

# Wrap in main() so bash reads the entire script before executing.
# This is required for curl | bash to work correctly.
main() {

# ── Colors & Symbols ────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m' # No Color

# ── Config ──────────────────────────────────────────────────────
OPENCLAW_CONFIG="${HOME}/.openclaw/openclaw.json"
OPENCLAW_DIR="${HOME}/.openclaw"
AISA_BASE_URL="https://api.aisa.one/v1"
AISA_MARKETPLACE="https://marketplace.aisa.one/"

# ── Model definitions ──────────────────────────────────────────
MODEL_IDS=("aisa/claude-haiku-4-5-20251001" "aisa/gpt-5" "aisa/gemini-3-pro-preview" "aisa/deepseek-r1" "aisa/qwen3-max")
MODEL_NAMES_EN=("Claude Haiku 4.5" "GPT-5" "Gemini 3 Pro" "DeepSeek R1" "Qwen3 Max")
MODEL_NAMES_ZH=("Claude Haiku 4.5" "GPT-5" "Gemini 3 Pro" "DeepSeek R1" "Qwen3 Max")
MODEL_EMOJIS=("⚡" "🌟" "🔵" "🔬" "🇨🇳")
MODEL_DESCS_EN=("Fast & lightweight, recommended default" "Latest OpenAI flagship, balanced" "Google latest multimodal model" "Strong reasoning chain" "Best for Chinese tasks")
MODEL_DESCS_ZH=("速度快、轻量级，推荐默认" "OpenAI 最新旗舰，性能均衡" "Google 最新多模态模型" "推理链路强" "中文任务最优")

# ── CLI arguments ───────────────────────────────────────────────
ARG_LANG=""
ARG_KEY=""
ARG_MODEL=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --lang) ARG_LANG="$2"; shift 2 ;;
    --key)  ARG_KEY="$2";  shift 2 ;;
    --model) ARG_MODEL="$2"; shift 2 ;;
    -h|--help)
      echo "Usage: ./setup-aisa.sh [--lang en|zh] [--key sk-xxxx] [--model 1|2|3|4]"
      echo ""
      echo "Options:"
      echo "  --lang en|zh    Set language (default: auto-detect)"
      echo "  --key sk-xxxx   AISA API Key (will prompt if not provided)"
      echo "  --model 1-5     Default model choice (will prompt if not provided)"
      exit 0
      ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

# ── Pipe mode detection (for curl | bash) ─────────────────────
# When running via pipe, stdin is the script itself, not the terminal.
# Redirect stdin from /dev/tty so read commands get user input.
if [[ ! -t 0 ]]; then
  if ( exec < /dev/tty ) 2>/dev/null; then
    exec < /dev/tty
  elif [[ -z "${ARG_KEY:-}" || -z "${ARG_MODEL:-}" ]]; then
    echo "Error: No terminal available for interactive input."
    echo "Usage: curl -fsSL <url> | bash -s -- --key sk-xxx --model 1"
    exit 1
  fi
fi

# ── Language detection ──────────────────────────────────────────
detect_language() {
  if [[ -n "$ARG_LANG" ]]; then
    echo "$ARG_LANG"
    return
  fi
  local locale="${LANG:-${LC_ALL:-en_US.UTF-8}}"
  if [[ "$locale" == zh* ]]; then
    echo "zh"
  else
    echo "en"
  fi
}

LANG_CODE=$(detect_language)

# ── i18n helper ─────────────────────────────────────────────────
t() {
  local key="$1"
  case "$LANG_CODE" in
    zh)
      case "$key" in
        welcome_title)       echo "🚀🎯 欢迎使用 AISA 统一模型配置！" ;;
        welcome_desc)        echo "本脚本将帮助您快速配置 OpenClaw 使用 AISA 统一模型 API" ;;
        welcome_feature1)    echo "💰 统一计费，无需多个 API 订阅" ;;
        welcome_feature2)    echo "⚡ 智能路由，自动选择最优节点" ;;
        welcome_feature3)    echo "🔄 48 个顶级模型一键切换" ;;
        overview_title)      echo "📦 模型总览 — 8 大厂商，56 个模型" ;;
        overview_provider)   echo "厂商" ;;
        overview_count)      echo "数量" ;;
        overview_featured)   echo "代表模型" ;;
        overview_total)      echo "合计" ;;
        overview_all)        echo "全部通过 AISA 统一 API 调用" ;;
        overview_more)       echo "更多" ;;
        check_openclaw)      echo "🔍 检查 OpenClaw 安装状态..." ;;
        openclaw_found)      echo "✅ OpenClaw 已安装" ;;
        openclaw_not_found)  echo "❌ 未找到 OpenClaw，请先安装: https://openclaw.ai" ;;
        config_exists)       echo "📄 已检测到现有配置文件" ;;
        config_backup)       echo "📦 已备份现有配置到" ;;
        config_new)          echo "📄 将创建新的配置文件" ;;
        ask_key_title)       echo "🔑 请输入您的 AISA API Key" ;;
        ask_key_hint)        echo "格式: sk-xxxx" ;;
        ask_key_get)         echo "📝 还没有？请访问获取:" ;;
        ask_key_free)        echo "🎁 新用户可获得 \$5 免费额度！" ;;
        ask_key_prompt)      echo "请粘贴您的 API Key: " ;;
        key_invalid)         echo "❌ API Key 格式无效，应以 sk- 开头" ;;
        key_accepted)        echo "✅ API Key 已接收！" ;;
        ask_model_title)     echo "🤖 请选择您的默认模型（输入数字 1-5，直接回车默认 1）：" ;;
        ask_model_prompt)    echo "👉 请输入 1-5 [1]: " ;;
        model_invalid)       echo "❌ 无效选择，请输入 1-5" ;;
        model_selected)      echo "✅ 已选择:" ;;
        writing_config)      echo "⚙️  正在写入配置..." ;;
        restarting_gw)       echo "🔄 正在重启 Gateway..." ;;
        gw_restarted)        echo "✅ Gateway 重启成功！" ;;
        gw_restart_fail)     echo "⚠️  Gateway 重启失败，请手动执行: openclaw gateway restart" ;;
        gw_not_running)      echo "ℹ️  Gateway 未在运行，配置已写入。启动命令: openclaw gateway restart" ;;
        success_title)       echo "🎉🎊 恭喜！AISA 统一模型配置成功！🎊🎉" ;;
        success_done)        echo "⚙️  配置已完成，Gateway 已就绪 ✅" ;;
        success_why)         echo "🌟 为什么选择 AISA 模型路由？" ;;
        models_title)        echo "📦 已配置 56 个模型（8 大厂商）" ;;
        rec_title)           echo "📋 推荐模型速查" ;;
        notes_title)         echo "⚠️  重要提示" ;;
        notes_current)       echo "📌 关于当前配置：" ;;
        notes_default)       echo "   所有新会话将自动使用您选择的默认模型：" ;;
        notes_switch)        echo "🔄 在 TUI 中切换模型：" ;;
        notes_other)         echo "🔀 想试试其他推荐模型？随时切换：" ;;
        notes_back)          echo "🔙 切回原版 Claude：" ;;
        notes_status)        echo "💡 状态栏提示：" ;;
        notes_status_desc)   echo "   切换模型后状态栏可能需要 2-3 轮对话才会更新，使用 /status 确认。" ;;
        start_using)         echo "🚀 开始使用吧！运行 openclaw tui 即可体验 AISA 模型。🎯" ;;
        separator)           echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" ;;
        # Table headers
        th_cmd)              echo "切换命令" ;;
        th_name)             echo "模型名称" ;;
        th_ctx)              echo "上下文" ;;
        th_use)              echo "用途" ;;
        th_desc)             echo "说明" ;;
        # Vendor names
        vendor_openai)       echo "🟢 OpenAI 系列 (10 个)" ;;
        vendor_claude)       echo "🟣 Anthropic Claude 系列 (13 个)" ;;
        vendor_gemini)       echo "🔵 Google Gemini 系列 (6 个)" ;;
        vendor_deepseek)     echo "🟠 DeepSeek 系列 (4 个)" ;;
        vendor_grok)         echo "⚫ xAI Grok 系列 (2 个)" ;;
        vendor_kimi)         echo "🟡 Moonshot Kimi 系列 (2 个)" ;;
        vendor_qwen)         echo "🔴 Alibaba Qwen 系列 (15 个)" ;;
        vendor_seed)         echo "🌱 ByteDance Seed 系列 (4 个)" ;;
        # Recommendations
        rec_general)         echo "通用任务" ;;
        rec_reasoning)       echo "默认 (快速)" ;;
        rec_coding)          echo "代码开发" ;;
        rec_chinese)         echo "中文任务" ;;
        rec_thinking)        echo "深度思考" ;;
        rec_fast)            echo "快速响应" ;;
        rec_general_d)       echo "🌟 最新旗舰" ;;
        rec_reasoning_d)     echo "⚡ 速度快、轻量级 ⭐ 默认" ;;
        rec_coding_d)        echo "💻 专为编程优化" ;;
        rec_chinese_d)       echo "🇨🇳 中文表现优秀" ;;
        rec_thinking_d)      echo "🔬 推理链路强" ;;
        rec_fast_d)          echo "⚡ 速度快成本低" ;;
        lang_choice)         echo "🌐 选择语言 / Choose language:" ;;
        *) echo "$key" ;;
      esac
      ;;
    *)
      case "$key" in
        welcome_title)       echo "🚀🎯 Welcome to AISA Unified Model Setup!" ;;
        welcome_desc)        echo "This script configures OpenClaw to use the AISA Unified Model API" ;;
        welcome_feature1)    echo "💰 Cost-effective: Unified billing, no multiple API subscriptions" ;;
        welcome_feature2)    echo "⚡ Faster response: Smart routing, auto-selects optimal nodes" ;;
        welcome_feature3)    echo "🔄 One-click switch: 48 top models available anytime" ;;
        overview_title)      echo "📦 Model Overview — 8 Providers, 56 Models" ;;
        overview_provider)   echo "Provider" ;;
        overview_count)      echo " # " ;;
        overview_featured)   echo "Featured Models" ;;
        overview_total)      echo "Total" ;;
        overview_all)        echo "All available via AISA unified API" ;;
        overview_more)       echo "more" ;;
        check_openclaw)      echo "🔍 Checking OpenClaw installation..." ;;
        openclaw_found)      echo "✅ OpenClaw is installed" ;;
        openclaw_not_found)  echo "❌ OpenClaw not found. Please install first: https://openclaw.ai" ;;
        config_exists)       echo "📄 Existing configuration detected" ;;
        config_backup)       echo "📦 Backed up existing config to" ;;
        config_new)          echo "📄 Will create new configuration" ;;
        ask_key_title)       echo "🔑 Enter your AISA API Key" ;;
        ask_key_hint)        echo "Format: sk-xxxx" ;;
        ask_key_get)         echo "📝 Don't have one? Get it here:" ;;
        ask_key_free)        echo "🎁 New users receive \$5 free credit!" ;;
        ask_key_prompt)      echo "Paste your API Key: " ;;
        key_invalid)         echo "❌ Invalid API Key format, should start with sk-" ;;
        key_accepted)        echo "✅ API Key accepted!" ;;
        ask_model_title)     echo "🤖 Choose your default model (enter 1-5, press Enter for default 1):" ;;
        ask_model_prompt)    echo "👉 Enter 1-5 [1]: " ;;
        model_invalid)       echo "❌ Invalid choice, please enter 1-5" ;;
        model_selected)      echo "✅ Selected:" ;;
        writing_config)      echo "⚙️  Writing configuration..." ;;
        restarting_gw)       echo "🔄 Restarting Gateway..." ;;
        gw_restarted)        echo "✅ Gateway restarted successfully!" ;;
        gw_restart_fail)     echo "⚠️  Gateway restart failed. Run manually: openclaw gateway restart" ;;
        gw_not_running)      echo "ℹ️  Gateway not running. Config written. Start with: openclaw gateway restart" ;;
        success_title)       echo "🎉🎊 Congratulations! AISA Unified Model Configuration Complete! 🎊🎉" ;;
        success_done)        echo "⚙️  Configuration done, Gateway is ready ✅" ;;
        success_why)         echo "🌟 Why Choose AISA Model Router?" ;;
        models_title)        echo "📦 56 Models Configured (8 Providers)" ;;
        rec_title)           echo "📋 Recommended Models Quick Reference" ;;
        notes_title)         echo "⚠️  Important Notes" ;;
        notes_current)       echo "📌 About Your Configuration:" ;;
        notes_default)       echo "   All new sessions will automatically use your selected default:" ;;
        notes_switch)        echo "🔄 Switch Models in TUI:" ;;
        notes_other)         echo "🔀 Want to try other top models? Switch anytime:" ;;
        notes_back)          echo "🔙 Switch back to original Claude:" ;;
        notes_status)        echo "💡 Status Bar Tip:" ;;
        notes_status_desc)   echo "   Status bar may take 2-3 turns to update. Use /status to confirm." ;;
        start_using)         echo "🚀 Start using now! Run openclaw tui to experience AISA models. 🎯" ;;
        separator)           echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" ;;
        th_cmd)              echo "Switch Command" ;;
        th_name)             echo "Model Name" ;;
        th_ctx)              echo "Context" ;;
        th_use)              echo "Use Case" ;;
        th_desc)             echo "Description" ;;
        vendor_openai)       echo "🟢 OpenAI Series (10)" ;;
        vendor_claude)       echo "🟣 Anthropic Claude Series (13)" ;;
        vendor_gemini)       echo "🔵 Google Gemini Series (6)" ;;
        vendor_deepseek)     echo "🟠 DeepSeek Series (4)" ;;
        vendor_grok)         echo "⚫ xAI Grok Series (2)" ;;
        vendor_kimi)         echo "🟡 Moonshot Kimi Series (2)" ;;
        vendor_qwen)         echo "🔴 Alibaba Qwen Series (15)" ;;
        vendor_seed)         echo "🌱 ByteDance Seed Series (4)" ;;
        rec_general)         echo "General tasks" ;;
        rec_reasoning)       echo "Default (Fast)" ;;
        rec_coding)          echo "Coding" ;;
        rec_chinese)         echo "Chinese tasks" ;;
        rec_thinking)        echo "Deep thinking" ;;
        rec_fast)            echo "Fast response" ;;
        rec_general_d)       echo "🌟 Latest flagship" ;;
        rec_reasoning_d)     echo "⚡ Fast & lightweight ⭐ Default" ;;
        rec_coding_d)        echo "💻 Optimized for code" ;;
        rec_chinese_d)       echo "🇨🇳 Best for Chinese" ;;
        rec_thinking_d)      echo "🔬 Reasoning chain" ;;
        rec_fast_d)          echo "⚡ Fast & low cost" ;;
        lang_choice)         echo "🌐 Choose language / 选择语言:" ;;
        *) echo "$key" ;;
      esac
      ;;
  esac
}

# ── Helpers ─────────────────────────────────────────────────────
print_line() {
  echo -e "$1"
}

print_header() {
  echo ""
  echo -e "${BOLD}${CYAN}$1${NC}"
  echo ""
}

print_separator() {
  echo -e "${DIM}$(t separator)${NC}"
}

# Print model overview table (7 providers, 48 models, 3 featured each)
print_model_overview() {
  local more="$(t overview_more)"
  echo ""
  echo -e "  ${BOLD}$(t overview_title)${NC}"
  echo ""
  printf "  ${DIM}┌──────────────────┬─────┬────────────────────────────────────────────────┐${NC}\n"
  printf "  ${DIM}│${NC} ${BOLD}%-16s${NC} ${DIM}│${NC}${BOLD}%-5s${NC}${DIM}│${NC} ${BOLD}%-46s${NC} ${DIM}│${NC}\n" "$(t overview_provider)" "$(t overview_count)" "$(t overview_featured)"
  printf "  ${DIM}├──────────────────┼─────┼────────────────────────────────────────────────┤${NC}\n"
  printf "  ${DIM}│${NC} 🌟 %-13s ${DIM}│${NC} ${WHITE}%2d${NC}  ${DIM}│${NC} ${CYAN}%-33s${NC} ${DIM}+7 ${more}${NC} ${DIM}│${NC}\n"  "OpenAI"    10 "gpt-5, gpt-5.2, gpt-4.1"
  printf "  ${DIM}│${NC} 🧠 %-13s ${DIM}│${NC} ${WHITE}%2d${NC}  ${DIM}│${NC} ${CYAN}%-33s${NC} ${DIM}+10 ${more}${NC} ${DIM}│${NC}\n" "Anthropic" 13 "opus-4.6, sonnet-4.6, haiku-4.5"
  printf "  ${DIM}│${NC} 🔵 %-13s ${DIM}│${NC} ${WHITE}%2d${NC}  ${DIM}│${NC} ${CYAN}%-33s${NC} ${DIM}+3 ${more}${NC} ${DIM}│${NC}\n"  "Google"     6 "gemini-3.1-pro, 3-pro, 2.5-pro"
  printf "  ${DIM}│${NC} 🔬 %-13s ${DIM}│${NC} ${WHITE}%2d${NC}  ${DIM}│${NC} ${CYAN}%-33s${NC} ${DIM}+1 ${more}${NC} ${DIM}│${NC}\n"  "DeepSeek"   4 "deepseek-r1, v3.1, v3"
  printf "  ${DIM}│${NC} 🚀 %-13s ${DIM}│${NC} ${WHITE}%2d${NC}  ${DIM}│${NC} ${CYAN}%-46s${NC} ${DIM}│${NC}\n"                         "xAI"        2 "grok-4, grok-3"
  printf "  ${DIM}│${NC} 🌙 %-13s ${DIM}│${NC} ${WHITE}%2d${NC}  ${DIM}│${NC} ${CYAN}%-46s${NC} ${DIM}│${NC}\n"                         "Moonshot"   2 "kimi-k2.5, kimi-k2-thinking"
  printf "  ${DIM}│${NC} 🇨🇳 %-13s ${DIM}│${NC} ${WHITE}%2d${NC}  ${DIM}│${NC} ${CYAN}%-32s${NC} ${DIM}+12 ${more}${NC} ${DIM}│${NC}\n" "Alibaba"   15 "qwen3-max, qwen3-coder, vl-plus"
  printf "  ${DIM}│${NC} 🌱 %-13s ${DIM}│${NC} ${WHITE}%2d${NC}  ${DIM}│${NC} ${CYAN}%-33s${NC} ${DIM}+1 ${more}${NC} ${DIM}│${NC}\n"  "ByteDance"  4 "seed-1-6, seed-1-8, seedream-4-5"
  printf "  ${DIM}├──────────────────┼─────┼────────────────────────────────────────────────┤${NC}\n"
  printf "  ${DIM}│${NC} ${BOLD}%-16s${NC} ${DIM}│${NC} ${GREEN}${BOLD}%2d${NC}  ${DIM}│${NC} ${GREEN}%-46s${NC} ${DIM}│${NC}\n" "$(t overview_total)" 56 "✅ $(t overview_all)"
  printf "  ${DIM}└──────────────────┴─────┴────────────────────────────────────────────────┘${NC}\n"
}

# ── Step 0: Language selection (if not set) ─────────────────────
if [[ -z "$ARG_LANG" ]]; then
  # Auto-detected, but let user confirm if terminal is interactive
  if [[ -t 0 ]]; then
    echo ""
    echo -e "${BOLD}${CYAN}$(t lang_choice)${NC}"
    echo ""
    echo -e "  ${GREEN}1${NC}  English"
    echo -e "  ${GREEN}2${NC}  中文"
    echo ""
    read -r -p "$(echo -e "${YELLOW}👉 Enter 1 or 2 [default: $([ "$LANG_CODE" = "zh" ] && echo "2" || echo "1")]: ${NC}")" lang_choice
    case "${lang_choice}" in
      1) LANG_CODE="en" ;;
      2) LANG_CODE="zh" ;;
      "") ;; # keep auto-detected
      *) ;; # keep auto-detected
    esac
  fi
fi

# ── Step 1: Welcome ────────────────────────────────────────────
clear 2>/dev/null || true
echo ""
print_separator
echo ""
echo -e "  ${BOLD}${WHITE}$(t welcome_title)${NC}"
echo ""
echo -e "  ${GRAY}$(t welcome_desc)${NC}"
echo ""
echo -e "  $(t welcome_feature1)"
echo -e "  $(t welcome_feature2)"
echo -e "  $(t welcome_feature3)"

print_model_overview

echo ""
print_separator

# ── Step 2: Check OpenClaw ─────────────────────────────────────
echo ""
echo -e "$(t check_openclaw)"

if command -v openclaw &>/dev/null; then
  OPENCLAW_VERSION=$(openclaw --version 2>/dev/null | head -1 || echo "unknown")
  echo -e "$(t openclaw_found) ${DIM}(${OPENCLAW_VERSION})${NC}"
else
  echo -e "${RED}$(t openclaw_not_found)${NC}"
  exit 1
fi

# Check & backup existing config
if [[ -f "$OPENCLAW_CONFIG" ]]; then
  echo -e "$(t config_exists)"
  BACKUP_FILE="${OPENCLAW_CONFIG}.bak.$(date +%Y%m%d%H%M%S)"
  cp "$OPENCLAW_CONFIG" "$BACKUP_FILE"
  echo -e "$(t config_backup) ${DIM}${BACKUP_FILE}${NC}"

  # Read previous model for dynamic notes
  PREV_MODEL=$(grep -o '"primary"[[:space:]]*:[[:space:]]*"[^"]*"' "$OPENCLAW_CONFIG" 2>/dev/null | head -1 | sed 's/.*"primary"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' || echo "anthropic/claude-opus-4-5")
else
  echo -e "$(t config_new)"
  mkdir -p "$OPENCLAW_DIR"
  PREV_MODEL="anthropic/claude-opus-4-5"
fi

# ── Step 3: Get API Key ────────────────────────────────────────
echo ""
print_header "$(t ask_key_title)"
echo -e "  ${DIM}$(t ask_key_hint)${NC}"
echo -e "  $(t ask_key_get) ${CYAN}${AISA_MARKETPLACE}${NC}"
echo -e "  $(t ask_key_free)"
echo ""

if [[ -n "$ARG_KEY" ]]; then
  API_KEY="$ARG_KEY"
else
  while true; do
    read -r -p "$(echo -e "  ${YELLOW}$(t ask_key_prompt)${NC}")" API_KEY
    if [[ "$API_KEY" == sk-* ]] && [[ ${#API_KEY} -gt 10 ]]; then
      break
    else
      echo -e "  ${RED}$(t key_invalid)${NC}"
    fi
  done
fi

echo -e "  ${GREEN}$(t key_accepted)${NC}"

# ── Step 4: Choose default model ───────────────────────────────
echo ""
print_header "$(t ask_model_title)"

# Table header
printf "  ${DIM}┌─────┬──────────────────┬──────────────────────────────────────────┐${NC}\n"
if [[ "$LANG_CODE" == "zh" ]]; then
  printf "  ${DIM}│${NC} ${BOLD} #  ${NC}${DIM}│${NC} ${BOLD}模型名称         ${NC}${DIM}│${NC} ${BOLD}说明                                     ${NC}${DIM}│${NC}\n"
else
  printf "  ${DIM}│${NC} ${BOLD} #  ${NC}${DIM}│${NC} ${BOLD}Model            ${NC}${DIM}│${NC} ${BOLD}Description                              ${NC}${DIM}│${NC}\n"
fi
printf "  ${DIM}├─────┼──────────────────┼──────────────────────────────────────────┤${NC}\n"

for i in 0 1 2 3 4; do
  n=$((i + 1))
  emoji="${MODEL_EMOJIS[$i]}"
  if [[ "$LANG_CODE" == "zh" ]]; then
    name="${MODEL_NAMES_ZH[$i]}"
    desc="${MODEL_DESCS_ZH[$i]}"
  else
    name="${MODEL_NAMES_EN[$i]}"
    desc="${MODEL_DESCS_EN[$i]}"
  fi
  printf "  ${DIM}│${NC} ${GREEN}%s${NC} %s${DIM}│${NC} %-16s ${DIM}│${NC} %-40s ${DIM}│${NC}\n" "$n" "$emoji" "$name" "$desc"
done

# Table footer
printf "  ${DIM}└─────┴──────────────────┴──────────────────────────────────────────┘${NC}\n"

echo ""

if [[ -n "$ARG_MODEL" ]]; then
  MODEL_CHOICE="$ARG_MODEL"
else
  while true; do
    read -r -p "$(echo -e "  ${YELLOW}$(t ask_model_prompt)${NC}")" MODEL_CHOICE
    [[ -z "$MODEL_CHOICE" ]] && MODEL_CHOICE="1"
    if [[ "$MODEL_CHOICE" =~ ^[1-5]$ ]]; then
      break
    else
      echo -e "  ${RED}$(t model_invalid)${NC}"
    fi
  done
fi

MODEL_INDEX=$((MODEL_CHOICE - 1))
SELECTED_MODEL="${MODEL_IDS[$MODEL_INDEX]}"
SELECTED_NAME="${MODEL_NAMES_EN[$MODEL_INDEX]}"
SELECTED_EMOJI="${MODEL_EMOJIS[$MODEL_INDEX]}"

echo -e "  ${GREEN}$(t model_selected) ${SELECTED_EMOJI} ${SELECTED_NAME} (${SELECTED_MODEL})${NC}"

# ── Step 5: Write configuration ────────────────────────────────
echo ""
echo -e "$(t writing_config)"

# Preserve existing non-model config if present
# Read existing gateway config
if [[ -f "$BACKUP_FILE" ]]; then
  GW_PORT=$(python3 -c "import json; c=json.load(open('$BACKUP_FILE')); print(c.get('gateway',{}).get('port',18789))" 2>/dev/null || echo "18789")
  GW_TOKEN=$(python3 -c "import json; c=json.load(open('$BACKUP_FILE')); print(c.get('gateway',{}).get('auth',{}).get('token',''))" 2>/dev/null || echo "")
  GW_BIND=$(python3 -c "import json; c=json.load(open('$BACKUP_FILE')); print(c.get('gateway',{}).get('bind','loopback'))" 2>/dev/null || echo "loopback")
  WORKSPACE=$(python3 -c "import json; c=json.load(open('$BACKUP_FILE')); print(c.get('agents',{}).get('defaults',{}).get('workspace','${HOME}/.openclaw/workspace'))" 2>/dev/null || echo "${HOME}/.openclaw/workspace")
else
  GW_PORT="18789"
  GW_TOKEN=""
  GW_BIND="loopback"
  WORKSPACE="${HOME}/.openclaw/workspace"
fi

# Build auth block
if [[ -n "$GW_TOKEN" ]]; then
  AUTH_BLOCK="\"auth\": { \"mode\": \"token\", \"token\": \"${GW_TOKEN}\" },"
else
  AUTH_BLOCK=""
fi

# Extract raw model ID (without aisa/ prefix)
RAW_MODEL_ID="${SELECTED_MODEL#aisa/}"

cat > "$OPENCLAW_CONFIG" << JSONEOF
{
  "meta": {
    "lastTouchedVersion": "2026.1.30",
    "lastTouchedAt": "$(date -u +%Y-%m-%dT%H:%M:%S.000Z)"
  },
  "wizard": {
    "lastRunAt": "$(date -u +%Y-%m-%dT%H:%M:%S.000Z)",
    "lastRunVersion": "2026.1.30",
    "lastRunCommand": "onboard",
    "lastRunMode": "local"
  },
  "models": {
    "mode": "merge",
    "providers": {
      "aisa": {
        "baseUrl": "${AISA_BASE_URL}",
        "apiKey": "${API_KEY}",
        "api": "openai-completions",
        "models": [
          {"id": "gpt-4.1", "name": "GPT-4.1 (AISA)", "reasoning": false, "input": ["text"], "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0}, "contextWindow": 128000, "maxTokens": 8192},
          {"id": "gpt-4.1-mini", "name": "GPT-4.1 Mini (AISA)", "reasoning": false, "input": ["text"], "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0}, "contextWindow": 64000, "maxTokens": 8192},
          {"id": "gpt-4o", "name": "GPT-4o (AISA)", "reasoning": false, "input": ["text"], "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0}, "contextWindow": 128000, "maxTokens": 8192},
          {"id": "gpt-4o-mini", "name": "GPT-4o Mini (AISA)", "reasoning": false, "input": ["text"], "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0}, "contextWindow": 64000, "maxTokens": 8192},
          {"id": "gpt-5", "name": "GPT-5 (AISA)", "reasoning": false, "input": ["text"], "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0}, "contextWindow": 128000, "maxTokens": 8192},
          {"id": "gpt-5-mini", "name": "GPT-5 Mini (AISA)", "reasoning": false, "input": ["text"], "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0}, "contextWindow": 64000, "maxTokens": 8192},
          {"id": "gpt-5.2", "name": "GPT-5.2 (AISA)", "reasoning": false, "input": ["text"], "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0}, "contextWindow": 128000, "maxTokens": 8192},
          {"id": "gpt-5.2-2025-12-11", "name": "GPT-5.2 2025-12-11 (AISA)", "reasoning": false, "input": ["text"], "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0}, "contextWindow": 128000, "maxTokens": 8192},
          {"id": "gpt-5.2-chat-latest", "name": "GPT-5.2 Chat Latest (AISA)", "reasoning": false, "input": ["text"], "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0}, "contextWindow": 128000, "maxTokens": 8192},
          {"id": "gpt-oss-120b", "name": "GPT OSS 120B (AISA)", "reasoning": false, "input": ["text"], "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0}, "contextWindow": 128000, "maxTokens": 8192},
          {"id": "claude-3-7-sonnet-20250219", "name": "Claude 3.7 Sonnet (AISA)", "reasoning": false, "input": ["text"], "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0}, "contextWindow": 200000, "maxTokens": 8192},
          {"id": "claude-3-7-sonnet-20250219-thinking", "name": "Claude 3.7 Sonnet Thinking (AISA)", "reasoning": false, "input": ["text"], "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0}, "contextWindow": 200000, "maxTokens": 8192},
          {"id": "claude-haiku-4-5-20251001", "name": "Claude Haiku 4.5 (AISA)", "reasoning": false, "input": ["text"], "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0}, "contextWindow": 200000, "maxTokens": 8192},
          {"id": "claude-opus-4-1-20250805", "name": "Claude Opus 4.1 (AISA)", "reasoning": false, "input": ["text"], "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0}, "contextWindow": 200000, "maxTokens": 8192},
          {"id": "claude-opus-4-1-20250805-thinking", "name": "Claude Opus 4.1 Thinking (AISA)", "reasoning": false, "input": ["text"], "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0}, "contextWindow": 200000, "maxTokens": 8192},
          {"id": "claude-opus-4-20250514", "name": "Claude Opus 4 (AISA)", "reasoning": false, "input": ["text"], "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0}, "contextWindow": 200000, "maxTokens": 8192},
          {"id": "claude-opus-4-20250514-thinking", "name": "Claude Opus 4 Thinking (AISA)", "reasoning": false, "input": ["text"], "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0}, "contextWindow": 200000, "maxTokens": 8192},
          {"id": "claude-sonnet-4-20250514", "name": "Claude Sonnet 4 (AISA)", "reasoning": false, "input": ["text"], "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0}, "contextWindow": 200000, "maxTokens": 8192},
          {"id": "claude-sonnet-4-20250514-thinking", "name": "Claude Sonnet 4 Thinking (AISA)", "reasoning": false, "input": ["text"], "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0}, "contextWindow": 200000, "maxTokens": 8192},
          {"id": "claude-sonnet-4-5-20250929", "name": "Claude Sonnet 4.5 (AISA)", "reasoning": false, "input": ["text"], "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0}, "contextWindow": 200000, "maxTokens": 8192},
          {"id": "claude-opus-4-6", "name": "Claude Opus 4.6 (AISA)", "reasoning": false, "input": ["text"], "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0}, "contextWindow": 200000, "maxTokens": 8192},
          {"id": "claude-sonnet-4-6", "name": "Claude Sonnet 4.6 (AISA)", "reasoning": false, "input": ["text"], "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0}, "contextWindow": 200000, "maxTokens": 8192},
          {"id": "claude-sonnet-4-6-thinking", "name": "Claude Sonnet 4.6 Thinking (AISA)", "reasoning": false, "input": ["text"], "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0}, "contextWindow": 200000, "maxTokens": 8192},
          {"id": "gemini-2.5-flash", "name": "Gemini 2.5 Flash (AISA)", "reasoning": false, "input": ["text"], "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0}, "contextWindow": 128000, "maxTokens": 8192},
          {"id": "gemini-2.5-flash-lite", "name": "Gemini 2.5 Flash Lite (AISA)", "reasoning": false, "input": ["text"], "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0}, "contextWindow": 128000, "maxTokens": 8192},
          {"id": "gemini-2.5-pro", "name": "Gemini 2.5 Pro (AISA)", "reasoning": false, "input": ["text"], "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0}, "contextWindow": 128000, "maxTokens": 8192},
          {"id": "gemini-3-pro-image-preview", "name": "Gemini 3 Pro Image (AISA)", "reasoning": false, "input": ["text"], "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0}, "contextWindow": 128000, "maxTokens": 8192},
          {"id": "gemini-3-pro-preview", "name": "Gemini 3 Pro Preview (AISA)", "reasoning": false, "input": ["text"], "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0}, "contextWindow": 128000, "maxTokens": 8192},
          {"id": "gemini-3.1-pro-preview", "name": "Gemini 3.1 Pro Preview (AISA)", "reasoning": false, "input": ["text"], "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0}, "contextWindow": 128000, "maxTokens": 8192},
          {"id": "deepseek-r1", "name": "DeepSeek R1 (AISA)", "reasoning": false, "input": ["text"], "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0}, "contextWindow": 128000, "maxTokens": 8192},
          {"id": "deepseek-v3", "name": "DeepSeek V3 (AISA)", "reasoning": false, "input": ["text"], "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0}, "contextWindow": 128000, "maxTokens": 8192},
          {"id": "deepseek-v3-0324", "name": "DeepSeek V3 0324 (AISA)", "reasoning": false, "input": ["text"], "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0}, "contextWindow": 128000, "maxTokens": 8192},
          {"id": "deepseek-v3.1", "name": "DeepSeek V3.1 (AISA)", "reasoning": false, "input": ["text"], "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0}, "contextWindow": 128000, "maxTokens": 8192},
          {"id": "grok-3", "name": "Grok 3 (AISA)", "reasoning": false, "input": ["text"], "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0}, "contextWindow": 64000, "maxTokens": 8192},
          {"id": "grok-4", "name": "Grok 4 (AISA)", "reasoning": false, "input": ["text"], "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0}, "contextWindow": 64000, "maxTokens": 8192},
          {"id": "kimi-k2-thinking", "name": "Kimi K2 Thinking (AISA)", "reasoning": false, "input": ["text"], "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0}, "contextWindow": 128000, "maxTokens": 8192},
          {"id": "kimi-k2.5", "name": "Kimi K2.5 (AISA)", "reasoning": false, "input": ["text"], "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0}, "contextWindow": 128000, "maxTokens": 8192},
          {"id": "qwen-mt-flash", "name": "Qwen MT Flash (AISA)", "reasoning": false, "input": ["text"], "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0}, "contextWindow": 128000, "maxTokens": 8192},
          {"id": "qwen-mt-lite", "name": "Qwen MT Lite (AISA)", "reasoning": false, "input": ["text"], "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0}, "contextWindow": 128000, "maxTokens": 8192},
          {"id": "qwen-plus-2025-12-01", "name": "Qwen Plus (AISA)", "reasoning": false, "input": ["text"], "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0}, "contextWindow": 128000, "maxTokens": 8192},
          {"id": "qwen-vl-max", "name": "Qwen VL Max (AISA)", "reasoning": false, "input": ["text"], "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0}, "contextWindow": 128000, "maxTokens": 8192},
          {"id": "qwen3-coder-480b-a35b-instruct", "name": "Qwen3 Coder 480B (AISA)", "reasoning": false, "input": ["text"], "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0}, "contextWindow": 128000, "maxTokens": 8192},
          {"id": "qwen3-coder-flash", "name": "Qwen3 Coder Flash (AISA)", "reasoning": false, "input": ["text"], "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0}, "contextWindow": 128000, "maxTokens": 8192},
          {"id": "qwen3-coder-plus", "name": "Qwen3 Coder Plus (AISA)", "reasoning": false, "input": ["text"], "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0}, "contextWindow": 128000, "maxTokens": 8192},
          {"id": "qwen3-max", "name": "Qwen3 Max (AISA)", "reasoning": false, "input": ["text"], "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0}, "contextWindow": 128000, "maxTokens": 8192},
          {"id": "qwen3-max-2026-01-23", "name": "Qwen3 Max 2026-01-23 (AISA)", "reasoning": false, "input": ["text"], "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0}, "contextWindow": 128000, "maxTokens": 8192},
          {"id": "qwen3-omni-flash", "name": "Qwen3 Omni Flash (AISA)", "reasoning": false, "input": ["text"], "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0}, "contextWindow": 128000, "maxTokens": 8192},
          {"id": "qwen3-omni-flash-2025-12-01", "name": "Qwen3 Omni Flash 2025-12-01 (AISA)", "reasoning": false, "input": ["text"], "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0}, "contextWindow": 128000, "maxTokens": 8192},
          {"id": "qwen3-vl-flash", "name": "Qwen3 VL Flash (AISA)", "reasoning": false, "input": ["text"], "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0}, "contextWindow": 128000, "maxTokens": 8192},
          {"id": "qwen3-vl-flash-2025-10-15", "name": "Qwen3 VL Flash 2025-10-15 (AISA)", "reasoning": false, "input": ["text"], "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0}, "contextWindow": 128000, "maxTokens": 8192},
          {"id": "qwen3-vl-plus", "name": "Qwen3 VL Plus (AISA)", "reasoning": false, "input": ["text"], "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0}, "contextWindow": 128000, "maxTokens": 8192},
          {"id": "qwen3-vl-plus-2025-12-19", "name": "Qwen3 VL Plus 2025-12-19 (AISA)", "reasoning": false, "input": ["text"], "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0}, "contextWindow": 128000, "maxTokens": 8192},
          {"id": "seed-1-6-250915", "name": "Seed 1.6 (AISA)", "reasoning": false, "input": ["text"], "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0}, "contextWindow": 128000, "maxTokens": 8192},
          {"id": "seed-1-6-flash-250715", "name": "Seed 1.6 Flash (AISA)", "reasoning": false, "input": ["text"], "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0}, "contextWindow": 128000, "maxTokens": 8192},
          {"id": "seed-1-8-251228", "name": "Seed 1.8 (AISA)", "reasoning": false, "input": ["text"], "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0}, "contextWindow": 128000, "maxTokens": 8192},
          {"id": "seedream-4-5-251128", "name": "Seedream 4.5 (AISA)", "reasoning": false, "input": ["text"], "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0}, "contextWindow": 128000, "maxTokens": 8192}
        ]
      }
    }
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "${SELECTED_MODEL}"
      },
      "models": {
        "anthropic/claude-opus-4-5": {"alias": "opus"},
        "aisa/gpt-4.1": {},
        "aisa/gpt-4.1-mini": {},
        "aisa/gpt-4o": {},
        "aisa/gpt-4o-mini": {},
        "aisa/gpt-5": {},
        "aisa/gpt-5-mini": {},
        "aisa/gpt-5.2": {},
        "aisa/gpt-5.2-2025-12-11": {},
        "aisa/gpt-5.2-chat-latest": {},
        "aisa/gpt-oss-120b": {},
        "aisa/claude-3-7-sonnet-20250219": {},
        "aisa/claude-3-7-sonnet-20250219-thinking": {},
        "aisa/claude-haiku-4-5-20251001": {},
        "aisa/claude-opus-4-1-20250805": {},
        "aisa/claude-opus-4-1-20250805-thinking": {},
        "aisa/claude-opus-4-20250514": {},
        "aisa/claude-opus-4-20250514-thinking": {},
        "aisa/claude-sonnet-4-20250514": {},
        "aisa/claude-sonnet-4-20250514-thinking": {},
        "aisa/claude-sonnet-4-5-20250929": {},
        "aisa/claude-opus-4-6": {},
        "aisa/claude-sonnet-4-6": {},
        "aisa/claude-sonnet-4-6-thinking": {},
        "aisa/gemini-2.5-flash": {},
        "aisa/gemini-2.5-flash-lite": {},
        "aisa/gemini-2.5-pro": {},
        "aisa/gemini-3-pro-image-preview": {},
        "aisa/gemini-3-pro-preview": {},
        "aisa/gemini-3.1-pro-preview": {},
        "aisa/deepseek-r1": {},
        "aisa/deepseek-v3": {},
        "aisa/deepseek-v3-0324": {},
        "aisa/deepseek-v3.1": {},
        "aisa/grok-3": {},
        "aisa/grok-4": {},
        "aisa/kimi-k2-thinking": {},
        "aisa/kimi-k2.5": {},
        "aisa/qwen-mt-flash": {},
        "aisa/qwen-mt-lite": {},
        "aisa/qwen-plus-2025-12-01": {},
        "aisa/qwen-vl-max": {},
        "aisa/qwen3-coder-480b-a35b-instruct": {},
        "aisa/qwen3-coder-flash": {},
        "aisa/qwen3-coder-plus": {},
        "aisa/qwen3-max": {},
        "aisa/qwen3-max-2026-01-23": {},
        "aisa/qwen3-omni-flash": {},
        "aisa/qwen3-omni-flash-2025-12-01": {},
        "aisa/qwen3-vl-flash": {},
        "aisa/qwen3-vl-flash-2025-10-15": {},
        "aisa/qwen3-vl-plus": {},
        "aisa/qwen3-vl-plus-2025-12-19": {},
        "aisa/seed-1-6-250915": {},
        "aisa/seed-1-6-flash-250715": {},
        "aisa/seed-1-8-251228": {},
        "aisa/seedream-4-5-251128": {}
      },
      "workspace": "${WORKSPACE}",
      "compaction": { "mode": "safeguard" },
      "maxConcurrent": 4,
      "subagents": { "maxConcurrent": 8 }
    }
  },
  "messages": { "ackReactionScope": "group-mentions" },
  "commands": { "native": "auto", "nativeSkills": "auto" },
  "gateway": {
    "port": ${GW_PORT},
    "mode": "local",
    "bind": "${GW_BIND}",
    ${AUTH_BLOCK}
    "tailscale": { "mode": "off", "resetOnExit": false }
  }
}
JSONEOF

# Clean up empty auth block (trailing comma issue)
python3 -c "
import json
with open('$OPENCLAW_CONFIG') as f:
    config = json.load(f)
with open('$OPENCLAW_CONFIG', 'w') as f:
    json.dump(config, f, indent=2)
" 2>/dev/null || true

echo -e "  ${GREEN}✅${NC} ${OPENCLAW_CONFIG}"

# ── Step 6: Restart Gateway ────────────────────────────────────
echo ""
echo -e "$(t restarting_gw)"

# Stop gateway first
openclaw gateway stop &>/dev/null || true
sleep 3

# Delete stale agent-level model catalog cache
# Gateway will regenerate it from the new openclaw.json on startup
AGENT_MODELS_JSON="${HOME}/.openclaw/agents/main/agent/models.json"
if [[ -f "$AGENT_MODELS_JSON" ]]; then
  rm -f "$AGENT_MODELS_JSON"
fi

# Start gateway with new config
GW_RESTARTED=false
if openclaw gateway start &>/dev/null; then
  # Wait for model catalog to fully load (async)
  sleep 5
  if pgrep -f "openclaw.*gateway" &>/dev/null; then
    echo -e "$(t gw_restarted)"
    GW_RESTARTED=true
  fi
fi

if [[ "$GW_RESTARTED" == "false" ]]; then
  if openclaw gateway restart &>/dev/null; then
    sleep 5
    echo -e "$(t gw_restarted)"
  elif pgrep -f "openclaw.*gateway" &>/dev/null; then
    echo -e "$(t gw_restart_fail)"
  else
    echo -e "$(t gw_not_running)"
  fi
fi

# ── Step 7: Success Output ─────────────────────────────────────
echo ""
echo ""
print_separator
echo ""
echo -e "  ${BOLD}${WHITE}$(t success_title)${NC}"
echo ""
echo -e "  $(t success_done)"
echo ""
echo -e "  $(t success_why)"
echo -e "    $(t welcome_feature1)"
echo -e "    $(t welcome_feature2)"
echo -e "    $(t welcome_feature3)"
echo ""
print_separator
echo ""
echo -e "${BOLD}$(t models_title)${NC}"

# ── Model tables ────────────────────────────────────────────────
print_vendor_table() {
  local vendor_key="$1"
  shift
  local models=("$@")

  echo ""
  echo -e "${BOLD}$(t "$vendor_key")${NC}"
  printf "  ${DIM}%-44s %-28s %s${NC}\n" "$(t th_cmd)" "$(t th_name)" "$(t th_ctx)"

  for model_line in "${models[@]}"; do
    IFS='|' read -r cmd name ctx <<< "$model_line"
    # Highlight selected model
    if [[ "$cmd" == *"$RAW_MODEL_ID"* ]] && [[ "$cmd" == "/model ${SELECTED_MODEL}" ]]; then
      printf "  ${GREEN}%-44s %-28s %s ⭐${NC}\n" "$cmd" "$name" "$ctx"
    else
      printf "  %-44s %-28s %s\n" "$cmd" "$name" "$ctx"
    fi
  done
}

print_vendor_table "vendor_openai" \
  "/model aisa/gpt-4.1|GPT-4.1|128K" \
  "/model aisa/gpt-4.1-mini|GPT-4.1 Mini|64K" \
  "/model aisa/gpt-4o|GPT-4o|128K" \
  "/model aisa/gpt-4o-mini|GPT-4o Mini|64K" \
  "/model aisa/gpt-5|GPT-5 🌟|128K" \
  "/model aisa/gpt-5-mini|GPT-5 Mini|64K" \
  "/model aisa/gpt-5.2|GPT-5.2|128K" \
  "/model aisa/gpt-5.2-2025-12-11|GPT-5.2 (2025-12-11)|128K" \
  "/model aisa/gpt-5.2-chat-latest|GPT-5.2 Chat Latest|128K" \
  "/model aisa/gpt-oss-120b|GPT OSS 120B|128K"

print_vendor_table "vendor_claude" \
  "/model aisa/claude-3-7-sonnet-20250219|Claude 3.7 Sonnet|200K" \
  "/model aisa/claude-3-7-sonnet-20250219-thinking|Claude 3.7 Sonnet Thinking|200K" \
  "/model aisa/claude-haiku-4-5-20251001|Claude Haiku 4.5|200K" \
  "/model aisa/claude-opus-4-1-20250805|Claude Opus 4.1 🧠|200K" \
  "/model aisa/claude-opus-4-1-20250805-thinking|Claude Opus 4.1 Thinking|200K" \
  "/model aisa/claude-opus-4-20250514|Claude Opus 4|200K" \
  "/model aisa/claude-opus-4-20250514-thinking|Claude Opus 4 Thinking|200K" \
  "/model aisa/claude-opus-4-6|Claude Opus 4.6 🧠|200K" \
  "/model aisa/claude-sonnet-4-20250514|Claude Sonnet 4|200K" \
  "/model aisa/claude-sonnet-4-20250514-thinking|Claude Sonnet 4 Thinking|200K" \
  "/model aisa/claude-sonnet-4-5-20250929|Claude Sonnet 4.5|200K" \
  "/model aisa/claude-sonnet-4-6|Claude Sonnet 4.6|200K" \
  "/model aisa/claude-sonnet-4-6-thinking|Claude Sonnet 4.6 Thinking|200K"

print_vendor_table "vendor_gemini" \
  "/model aisa/gemini-2.5-flash|Gemini 2.5 Flash|128K" \
  "/model aisa/gemini-2.5-flash-lite|Gemini 2.5 Flash Lite|128K" \
  "/model aisa/gemini-2.5-pro|Gemini 2.5 Pro|128K" \
  "/model aisa/gemini-3-pro-image-preview|Gemini 3 Pro Image|128K" \
  "/model aisa/gemini-3-pro-preview|Gemini 3 Pro Preview|128K" \
  "/model aisa/gemini-3.1-pro-preview|Gemini 3.1 Pro Preview|128K"

print_vendor_table "vendor_deepseek" \
  "/model aisa/deepseek-r1|DeepSeek R1 🔬|128K" \
  "/model aisa/deepseek-v3|DeepSeek V3|128K" \
  "/model aisa/deepseek-v3-0324|DeepSeek V3 (0324)|128K" \
  "/model aisa/deepseek-v3.1|DeepSeek V3.1|128K"

print_vendor_table "vendor_grok" \
  "/model aisa/grok-3|Grok 3|64K" \
  "/model aisa/grok-4|Grok 4|64K"

print_vendor_table "vendor_kimi" \
  "/model aisa/kimi-k2-thinking|Kimi K2 Thinking|128K" \
  "/model aisa/kimi-k2.5|Kimi K2.5|128K"

print_vendor_table "vendor_qwen" \
  "/model aisa/qwen-mt-flash|Qwen MT Flash|128K" \
  "/model aisa/qwen-mt-lite|Qwen MT Lite|128K" \
  "/model aisa/qwen-plus-2025-12-01|Qwen Plus|128K" \
  "/model aisa/qwen-vl-max|Qwen VL Max|128K" \
  "/model aisa/qwen3-coder-480b-a35b-instruct|Qwen3 Coder 480B|128K" \
  "/model aisa/qwen3-coder-flash|Qwen3 Coder Flash|128K" \
  "/model aisa/qwen3-coder-plus|Qwen3 Coder Plus 💻|128K" \
  "/model aisa/qwen3-max|Qwen3 Max 🇨🇳|128K" \
  "/model aisa/qwen3-max-2026-01-23|Qwen3 Max (2026-01-23)|128K" \
  "/model aisa/qwen3-omni-flash|Qwen3 Omni Flash|128K" \
  "/model aisa/qwen3-omni-flash-2025-12-01|Qwen3 Omni Flash (2025-12-01)|128K" \
  "/model aisa/qwen3-vl-flash|Qwen3 VL Flash|128K" \
  "/model aisa/qwen3-vl-flash-2025-10-15|Qwen3 VL Flash (2025-10-15)|128K" \
  "/model aisa/qwen3-vl-plus|Qwen3 VL Plus|128K" \
  "/model aisa/qwen3-vl-plus-2025-12-19|Qwen3 VL Plus (2025-12-19)|128K"

print_vendor_table "vendor_seed" \
  "/model aisa/seed-1-6-250915|Seed 1.6|128K" \
  "/model aisa/seed-1-6-flash-250715|Seed 1.6 Flash|128K" \
  "/model aisa/seed-1-8-251228|Seed 1.8|128K" \
  "/model aisa/seedream-4-5-251128|Seedream 4.5|128K"

# ── Recommendations table ──────────────────────────────────────
echo ""
print_separator
echo ""
echo -e "${BOLD}$(t rec_title)${NC}"
echo ""
printf "  ${DIM}%-18s %-42s %s${NC}\n" "$(t th_use)" "$(t th_cmd)" "$(t th_desc)"
printf "  %-18s %-42s %s\n" "$(t rec_general)"   "/model aisa/gpt-5"                      "$(t rec_general_d)"
printf "  %-18s %-42s %s\n" "$(t rec_reasoning)" "/model aisa/claude-haiku-4-5-20251001"  "$(t rec_reasoning_d)"
printf "  %-18s %-42s %s\n" "$(t rec_coding)"    "/model aisa/qwen3-coder-plus"           "$(t rec_coding_d)"
printf "  %-18s %-42s %s\n" "$(t rec_chinese)"   "/model aisa/qwen3-max"                  "$(t rec_chinese_d)"
printf "  %-18s %-42s %s\n" "$(t rec_thinking)"  "/model aisa/deepseek-r1"                "$(t rec_thinking_d)"
printf "  %-18s %-42s %s\n" "$(t rec_fast)"      "/model aisa/gpt-4.1-mini"               "$(t rec_fast_d)"

# ── Dynamic Important Notes ────────────────────────────────────
echo ""
print_separator
echo ""
echo -e "${BOLD}$(t notes_title)${NC}"
echo ""
echo -e "$(t notes_current)"
echo -e "$(t notes_default)"
echo -e "  ${GREEN}✅ ${SELECTED_EMOJI} ${SELECTED_NAME} (${SELECTED_MODEL})${NC}"
echo ""
echo -e "$(t notes_switch)"
echo -e "  ${CYAN}/model ${SELECTED_MODEL}${NC}"
if [[ "$LANG_CODE" == "zh" ]]; then
  echo -e "  ${YELLOW}⚠️  语法注意：直接输入 /model aisa/xxx，不要加 \"set\"！${NC}"
else
  echo -e "  ${YELLOW}⚠️  Syntax: Type /model aisa/xxx directly. Do NOT add \"set\"!${NC}"
fi
echo ""
echo -e "$(t notes_other)"

# Show the other 4 models the user didn't pick as a table
printf "  ${DIM}┌────┬─────────────────────────────────────────┬──────────────────────────────────────────────────┐${NC}\n"
if [[ "$LANG_CODE" == "zh" ]]; then
  printf "  ${DIM}│${NC}${BOLD}    ${NC}${DIM}│${NC} ${BOLD}切换命令                                ${NC}${DIM}│${NC} ${BOLD}说明                                               ${NC}${DIM}│${NC}\n"
else
  printf "  ${DIM}│${NC}${BOLD}    ${NC}${DIM}│${NC} ${BOLD}Command                                 ${NC}${DIM}│${NC} ${BOLD}Description                                        ${NC}${DIM}│${NC}\n"
fi
printf "  ${DIM}├────┼─────────────────────────────────────────┼──────────────────────────────────────────────────┤${NC}\n"

for i in 0 1 2 3 4; do
  if [[ $i -ne $MODEL_INDEX ]]; then
    if [[ "$LANG_CODE" == "zh" ]]; then
      desc="${MODEL_DESCS_ZH[$i]}"
    else
      desc="${MODEL_DESCS_EN[$i]}"
    fi
    printf "  ${DIM}│${NC} %s ${DIM}│${NC} ${CYAN}%-39s${NC} ${DIM}│${NC} %-48s ${DIM}│${NC}\n" "${MODEL_EMOJIS[$i]}" "/model ${MODEL_IDS[$i]}" "${MODEL_NAMES_EN[$i]} — ${desc}"
  fi
done

printf "  ${DIM}└────┴─────────────────────────────────────────┴──────────────────────────────────────────────────┘${NC}\n"

echo ""
echo -e "$(t notes_back)"
echo -e "  ${CYAN}/model opus${NC}"
echo ""
echo -e "$(t notes_status)"
echo -e "$(t notes_status_desc)"

echo ""
print_separator
echo ""
echo -e "  ${BOLD}${WHITE}$(t start_using)${NC}"
echo ""

exit 0
} # end main()

main "$@"
