#!/usr/bin/env bash
# 环球基金行情看板 启动脚本
# 静态站点，生产模式直接提供文件服务，无热重载 / 无构建缓存，规避 OOM 峰值
set -u

PORT=8000
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PID_FILE="${BASE_DIR}/.server.pid"
LOG_FILE="${BASE_DIR}/.server.log"

# 判断端口是否已被监听（即服务是否已启动）
listening() {
  ss -tln | grep -qE "[:.]${PORT}[[:space:]]"
}

# 已启动：直接返回 0，避免重复启动
if listening; then
  echo "[start] 服务已在端口 ${PORT} 运行，无需重复启动"
  exit 0
fi

# 静态站点无构建产物，无需清理构建缓存
cd "${BASE_DIR}" || { echo "[start] 无法进入目录 ${BASE_DIR}"; exit 2; }

# 生产模式启动：监听 0.0.0.0，根路径默认返回 index.html
# 不使用 timeout 包裹，避免服务被超时机制杀掉
export PYTHONUNBUFFERED=1
nohup python3 -m http.server "${PORT}" --bind 0.0.0.0 --directory "${BASE_DIR}" > "${LOG_FILE}" 2>&1 &
SERVER_PID=$!
echo "${SERVER_PID}" > "${PID_FILE}"

# 轮询等待端口就绪（仅为就绪检测，不是超时杀进程）
i=0
while [ "${i}" -lt 50 ]; do
  if listening; then
    echo "[start] 启动成功：端口 ${PORT}，PID ${SERVER_PID}"
    exit 0
  fi
  i=$((i + 1))
  sleep 0.2
done

echo "[start] 启动失败：端口 ${PORT} 未就绪，请查看日志 ${LOG_FILE}"
exit 2
