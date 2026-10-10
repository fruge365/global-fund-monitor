#!/usr/bin/env bash
# 环球基金行情看板 停止脚本
# 用 ss 提取监听端口的进程 PID 后终止，不使用 fuser / lsof
set -u

PORT=8000
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PID_FILE="${BASE_DIR}/.server.pid"

# 通过 ss 提取监听指定端口的 PID
port_pids() {
  ss -tlnp | grep -E "[:.]${PORT}[[:space:]]" | grep -oE 'pid=[0-9]+' | cut -d= -f2 | sort -u
}

PIDS="$(port_pids)"

if [ -z "${PIDS}" ]; then
  echo "[stop] 端口 ${PORT} 未在监听，服务未运行"
  : > "${PID_FILE}"
  exit 0
fi

for pid in ${PIDS}; do
  echo "[stop] 终止进程 PID ${pid}"
  kill "${pid}"
done

# 等待进程退出
i=0
while [ "${i}" -lt 50 ]; do
  if [ -z "$(port_pids)" ]; then
    echo "[stop] 服务已停止，端口 ${PORT} 已释放"
    : > "${PID_FILE}"
    exit 0
  fi
  i=$((i + 1))
  sleep 0.2
done

# 仍未退出则强制终止
for pid in ${PIDS}; do
  echo "[stop] 进程 PID ${pid} 未响应，强制终止"
  kill -9 "${pid}"
done
: > "${PID_FILE}"
echo "[stop] 已强制终止端口 ${PORT} 上的进程"
exit 0
