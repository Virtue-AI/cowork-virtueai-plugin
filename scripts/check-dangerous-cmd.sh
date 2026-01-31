#!/bin/bash
#
# 危险命令检测脚本
# 从 stdin 读取工具调用信息，检测并阻止危险的 Bash 命令
#
# 退出码:
#   0 - 允许执行
#   2 - 阻止执行（危险命令）
#

# 读取 stdin 中的 JSON 输入
INPUT=$(cat)

# 提取命令内容
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# 如果没有命令，直接放行
if [ -z "$COMMAND" ]; then
  exit 0
fi

# 危险命令模式列表
DANGEROUS_PATTERNS=(
  # 危险的删除操作
  "rm[[:space:]]+-rf[[:space:]]+/"
  "rm[[:space:]]+-rf[[:space:]]+~"
  "rm[[:space:]]+-rf[[:space:]]+\*"
  "rm[[:space:]]+-fr[[:space:]]+/"
  "rm[[:space:]].*--no-preserve-root"

  # 格式化/销毁磁盘
  "mkfs\."
  "dd[[:space:]]+if=.*of=/dev/"
  ":(){.*:;};:"  # fork bomb

  # 危险的权限修改
  "chmod[[:space:]]+-R[[:space:]]+777[[:space:]]+/"
  "chown[[:space:]]+-R.*/"

  # 覆盖系统文件
  ">[[:space:]]*/dev/sda"
  ">[[:space:]]*/dev/null.*<"
  "mv[[:space:]]+/[[:space:]]+"

  # 危险的网络操作
  "curl.*\|.*sh"
  "wget.*\|.*sh"
  "curl.*\|.*bash"
  "wget.*\|.*bash"

  # 清空历史/日志
  "history[[:space:]]+-c"
  ">[[:space:]]*/var/log/"

  # 关机/重启
  "shutdown"
  "reboot"
  "init[[:space:]]+0"
  "init[[:space:]]+6"
  "halt"
  "poweroff"
)

# 检查命令是否匹配危险模式
for pattern in "${DANGEROUS_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qE "$pattern"; then
    echo "🚫 阻止危险命令: 匹配模式 '$pattern'" >&2
    echo "原始命令: $COMMAND" >&2
    exit 2
  fi
done

# 未匹配危险模式，放行
exit 0
