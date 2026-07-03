#!/usr/bin/env zsh
# =============================================================================
# start.sh
# 启动后端服务（一键：检测 PostgreSQL → 停止旧后端 → 重新构建 → 运行）
# =============================================================================

set -e

# ─── 颜色输出 ─────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info()    { echo -e "${BLUE}[INFO]${NC} $1" }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1" }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1" }
print_error()   { echo -e "${RED}[ERROR]${NC} $1" }

# ─── 路径配置 ─────────────────────────────────────────────────────────────────
PROJECT_ROOT="${0:A:h:h:h}"
SERVER_DIR="${PROJECT_ROOT}/server"
SERVER_PORT=3000

# PostgreSQL 配置（与 start_postgres.sh 保持一致）
PG_BIN="/opt/homebrew/opt/postgresql@17/bin"
PG_DATA_DIR="$HOME/SDK/postgres/data"
PG_LOG_FILE="$HOME/SDK/postgres/logs/postgres.log"

# ─── [1] 检测并启动 PostgreSQL ────────────────────────────────────────────────
check_and_start_postgres() {
  print_info "检测 PostgreSQL 状态..."

  if "${PG_BIN}/pg_ctl" status -D "${PG_DATA_DIR}" 2>/dev/null | grep -q "server is running"; then
    print_success "PostgreSQL 已在运行"
  else
    print_warning "PostgreSQL 未运行，正在启动..."
    "${PG_BIN}/pg_ctl" start -D "${PG_DATA_DIR}" -l "${PG_LOG_FILE}"
    sleep 1

    if "${PG_BIN}/pg_ctl" status -D "${PG_DATA_DIR}" 2>/dev/null | grep -q "server is running"; then
      print_success "PostgreSQL 启动成功"
    else
      print_error "PostgreSQL 启动失败，请检查日志: ${PG_LOG_FILE}"
      exit 1
    fi
  fi
}

# ─── [2] 检测并停止旧的后端服务 ──────────────────────────────────────────────
check_and_stop_server() {
  print_info "检测后端服务是否在运行 (端口 ${SERVER_PORT})..."

  # 查找占用端口的进程
  local pids
  pids=$(lsof -ti :${SERVER_PORT} 2>/dev/null || true)

  if [[ -n "${pids}" ]]; then
    print_warning "后端服务已在运行 (PID: ${pids})，正在停止..."
    echo "${pids}" | while read -r pid; do
      kill "${pid}" 2>/dev/null || true
    done

    # 等待进程退出（最多 5 秒）
    local count=0
    while [[ ${count} -lt 5 ]]; do
      local remaining
      remaining=$(lsof -ti :${SERVER_PORT} 2>/dev/null || true)
      if [[ -z "${remaining}" ]]; then
        break
      fi
      sleep 1
      count=$((count + 1))
    done

    # 如果还没退出，强制 kill
    local remaining
    remaining=$(lsof -ti :${SERVER_PORT} 2>/dev/null || true)
    if [[ -n "${remaining}" ]]; then
      print_warning "进程未响应，强制终止..."
      echo "${remaining}" | while read -r pid; do
        kill -9 "${pid}" 2>/dev/null || true
      done
      sleep 1
    fi

    print_success "旧后端服务已停止"
  else
    print_info "后端服务未在运行"
  fi
}

# ─── [3] 重新构建并运行 ───────────────────────────────────────────────────────
build_and_run() {
  print_info "重新构建后端项目..."
  cd "${SERVER_DIR}"

  if ! cargo build 2>&1; then
    print_error "构建失败"
    exit 1
  fi
  print_success "构建完成"

  echo ""
  print_info "启动后端服务..."
  echo "─────────────────────────────────────"

  # 后台运行，日志输出到终端
  cargo run
}

# ─── 主流程 ───────────────────────────────────────────────────────────────────
main() {
  echo ""
  echo "=========================================="
  echo "  Flash IM Server 启动脚本"
  echo "=========================================="
  echo ""

  check_and_start_postgres
  echo ""

  check_and_stop_server
  echo ""

  build_and_run
}

main "$@"
