#!/usr/bin/env zsh
# =============================================================================
# install_postgres.sh
# macOS (Apple Silicon / Intel) + Homebrew - Install PostgreSQL 17
#
# Usage:
#   chmod +x scripts/setup/install_postgres.sh
#   ./scripts/setup/install_postgres.sh
# =============================================================================

set -euo pipefail

# ─── 配置 ──────────────────────────────────────────────────────────────────────

PG_VERSION="17"
PG_INSTALL_DIR="$HOME/SDK/postgres"
PG_DATA_DIR="${PG_INSTALL_DIR}/data"
PG_LOG_DIR="${PG_INSTALL_DIR}/logs"
PG_LOG_FILE="${PG_LOG_DIR}/postgres.log"
PG_PORT=5432
DB_NAME="flash_im"

SHELL_RC="$HOME/.zshrc"

# Homebrew prefix: Apple Silicon = /opt/homebrew, Intel = /usr/local
if [[ "$(uname -m)" == "arm64" ]]; then
  BREW_PREFIX="/opt/homebrew"
else
  BREW_PREFIX="/usr/local"
fi
PG_BIN="${BREW_PREFIX}/opt/postgresql@${PG_VERSION}/bin"

# ─── 颜色 ──────────────────────────────────────────────────────────────────────

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

# ─── 1. 检查 Homebrew ──────────────────────────────────────────────────────────

info "检查 Homebrew..."
if ! command -v brew &>/dev/null; then
  error "未找到 Homebrew，请先安装: https://brew.sh"
fi
info "Homebrew: $(brew --version | head -1)"

# ─── 2. 安装 PostgreSQL ────────────────────────────────────────────────────────

PKG="postgresql@${PG_VERSION}"
if brew list "$PKG" &>/dev/null; then
  warn "${PKG} 已安装，跳过"
else
  info "安装 ${PKG} ..."
  # HOMEBREW_NO_AUTO_UPDATE       : 跳过自动更新，加快安装
  # HOMEBREW_NO_REQUIRE_TAP_TRUST : 跳过 Homebrew 5.1+ 的 tap 信任交互
  # echo y                        : 自动回答安装确认提示
  HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_REQUIRE_TAP_TRUST=1 \
    echo y | brew install "$PKG"
  info "${PKG} 安装完成"
fi

# ─── 3. 创建目录 ───────────────────────────────────────────────────────────────

info "创建目录: ${PG_INSTALL_DIR}"
mkdir -p "${PG_DATA_DIR}"
mkdir -p "${PG_LOG_DIR}"

# ─── 4. 初始化数据目录 ─────────────────────────────────────────────────────────

if [[ -f "${PG_DATA_DIR}/PG_VERSION" ]]; then
  warn "数据目录已存在，跳过 initdb: ${PG_DATA_DIR}"
else
  info "初始化数据目录: ${PG_DATA_DIR}"
  "${PG_BIN}/initdb" \
    --pgdata="${PG_DATA_DIR}" \
    --username="$(whoami)" \
    --encoding=UTF8 \
    --locale=en_US.UTF-8 \
    --auth=trust
  info "initdb 完成"
fi

# ─── 5. 配置端口 ───────────────────────────────────────────────────────────────

PG_CONF="${PG_DATA_DIR}/postgresql.conf"
if grep -q "^port = " "${PG_CONF}" 2>/dev/null; then
  sed -i '' "s/^port = .*/port = ${PG_PORT}/" "${PG_CONF}"
else
  echo "port = ${PG_PORT}" >> "${PG_CONF}"
fi
info "端口设置为 ${PG_PORT}"

# ─── 6. 写入 ~/.zshrc 环境变量 ────────────────────────────────────────────────

MARKER="# >>> postgresql@${PG_VERSION} >>>"
MARKER_END="# <<< postgresql@${PG_VERSION} <<<"
CURRENT_USER="$(whoami)"

if grep -qF "$MARKER" "${SHELL_RC}" 2>/dev/null; then
  warn "环境变量已存在于 ${SHELL_RC}，跳过写入"
else
  info "写入环境变量到 ${SHELL_RC}"

  {
    echo ""
    echo "${MARKER}"
    echo "export PGDATA=\"${PG_DATA_DIR}\""
    echo "export PGPORT=\"${PG_PORT}\""
    echo "export PGUSER=\"${CURRENT_USER}\""
    echo "export PGDATABASE=\"${CURRENT_USER}\""
    echo "export PATH=\"${PG_BIN}:\$PATH\""
    echo "${MARKER_END}"
  } >> "${SHELL_RC}"

  info "环境变量写入完成，执行 'source ~/.zshrc' 生效"
fi

# 当前 shell 临时生效
export PGDATA="${PG_DATA_DIR}"
export PGPORT="${PG_PORT}"
export PGUSER="$(whoami)"
export PATH="${PG_BIN}:${PATH}"

# ─── 7. 启动 PostgreSQL ────────────────────────────────────────────────────────

info "检查 PostgreSQL 运行状态..."
if "${PG_BIN}/pg_ctl" status -D "${PG_DATA_DIR}" | grep -q "server is running"; then
  warn "PostgreSQL 已在运行"
else
  info "启动 PostgreSQL..."
  "${PG_BIN}/pg_ctl" start -D "${PG_DATA_DIR}" -l "${PG_LOG_FILE}"
  sleep 2
  info "PostgreSQL 已启动，日志: ${PG_LOG_FILE}"
fi

# ─── 8. 创建项目数据库 ─────────────────────────────────────────────────────────

if "${PG_BIN}/psql" -p "${PG_PORT}" -lqt | cut -d'|' -f1 | grep -qw "${DB_NAME}"; then
  warn "数据库 '${DB_NAME}' 已存在"
else
  info "创建数据库: ${DB_NAME}"
  "${PG_BIN}/createdb" -p "${PG_PORT}" "${DB_NAME}"
  info "数据库 '${DB_NAME}' 创建完成"
fi

# ─── 9. 完成 ──────────────────────────────────────────────────────────────────

CONN_USER="$(whoami)"
echo ""
echo -e "${GREEN}========================================"
echo " PostgreSQL ${PG_VERSION} 安装完成"
echo -e "========================================${NC}"
echo ""
echo "  安装目录 : ${PG_INSTALL_DIR}"
echo "  数据目录 : ${PG_DATA_DIR}"
echo "  日志文件 : ${PG_LOG_FILE}"
echo "  端口     : ${PG_PORT}"
echo "  用户     : ${CONN_USER}"
echo "  数据库   : ${DB_NAME}"
echo ""
echo "  常用命令:"
echo "    pg_ctl start   -D \$PGDATA -l ${PG_LOG_FILE}"
echo "    pg_ctl stop    -D \$PGDATA"
echo "    pg_ctl restart -D \$PGDATA"
echo "    psql ${DB_NAME}"
echo ""
echo "  Rust .env 连接字符串:"
echo "    DATABASE_URL=postgres://${CONN_USER}@localhost:${PG_PORT}/${DB_NAME}"
echo ""
echo "  让环境变量生效:"
echo "    source ~/.zshrc"
echo ""
