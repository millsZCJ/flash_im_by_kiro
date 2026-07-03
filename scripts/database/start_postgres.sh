#!/usr/bin/env zsh
# =============================================================================
# start_postgres.sh
# 启动 PostgreSQL 服务（数据目录: ~/SDK/postgres）
# =============================================================================

PG_BIN="/opt/homebrew/opt/postgresql@17/bin"
PG_DATA_DIR="$HOME/SDK/postgres/data"
PG_LOG_FILE="$HOME/SDK/postgres/logs/postgres.log"

# 检查是否已在运行
if "${PG_BIN}/pg_ctl" status -D "${PG_DATA_DIR}" | grep -q "server is running"; then
  echo "PostgreSQL 已在运行"
  "${PG_BIN}/pg_ctl" status -D "${PG_DATA_DIR}"
  exit 0
fi

# 启动
echo "启动 PostgreSQL..."
"${PG_BIN}/pg_ctl" start -D "${PG_DATA_DIR}" -l "${PG_LOG_FILE}"

# 等待就绪
sleep 1
echo ""
echo "日志: ${PG_LOG_FILE}"
echo "连接: psql -p 5432 flash_im"
