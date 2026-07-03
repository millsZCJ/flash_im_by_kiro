#!/usr/bin/env zsh
# =============================================================================
# db_manager.sh
# 数据库管理脚本 - 自动创建、迁移、清除数据库
# 使用 sqlx-cli 进行数据库迁移管理
# =============================================================================

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置
DB_NAME="flash_im"
DB_USER="zcj"
DB_HOST="localhost"
DB_PORT="5432"
DATABASE_URL="postgres://${DB_USER}@${DB_HOST}:${DB_PORT}/${DB_NAME}"
MIGRATIONS_DIR="server/migrations"

# PostgreSQL 路径
PG_BIN="/opt/homebrew/opt/postgresql@17/bin"

# =============================================================================
# 工具函数
# =============================================================================

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# =============================================================================
# 检测并安装 sqlx-cli
# =============================================================================

check_and_install_sqlx_cli() {
    print_info "检测 sqlx-cli..."
    
    if command -v sqlx &> /dev/null; then
        print_success "sqlx-cli 已安装: $(sqlx --version)"
        return 0
    fi
    
    print_warning "sqlx-cli 未安装，正在安装..."
    
    # 检测是否安装了 Rust
    if ! command -v cargo &> /dev/null; then
        print_error "Cargo 未安装，请先安装 Rust: https://rustup.rs/"
        exit 1
    fi
    
    # 安装 sqlx-cli
    print_info "使用 cargo 安装 sqlx-cli..."
    cargo install sqlx-cli --no-default-features --features native-tls,postgres
    
    if [ $? -eq 0 ]; then
        print_success "sqlx-cli 安装成功: $(sqlx --version)"
    else
        print_error "sqlx-cli 安装失败"
        exit 1
    fi
}

# =============================================================================
# 检测并启动 PostgreSQL
# =============================================================================

check_and_start_postgres() {
    print_info "检测 PostgreSQL 状态..."
    
    if "${PG_BIN}/pg_ctl" status -D "$HOME/SDK/postgres/data" | grep -q "server is running"; then
        print_success "PostgreSQL 已在运行"
        return 0
    fi
    
    print_warning "PostgreSQL 未运行，正在启动..."
    "${PG_BIN}/pg_ctl" start -D "$HOME/SDK/postgres/data" -l "$HOME/SDK/postgres/logs/postgres.log"
    
    sleep 1
    
    if "${PG_BIN}/pg_ctl" status -D "$HOME/SDK/postgres/data" | grep -q "server is running"; then
        print_success "PostgreSQL 启动成功"
    else
        print_error "PostgreSQL 启动失败"
        exit 1
    fi
}

# =============================================================================
# 创建数据库
# =============================================================================

create_database() {
    print_info "创建数据库: ${DB_NAME}"
    
    # 设置环境变量
    export DATABASE_URL
    
    # 检查数据库是否存在
    if "${PG_BIN}/psql" -p "${DB_PORT}" -lqt | cut -d \| -f 1 | grep -qw "${DB_NAME}"; then
        print_warning "数据库 ${DB_NAME} 已存在"
    else
        # 使用 sqlx 创建数据库
        sqlx database create
        print_success "数据库 ${DB_NAME} 创建成功"
    fi
}

# =============================================================================
# 运行迁移
# =============================================================================

run_migrations() {
    print_info "运行数据库迁移..."
    
    export DATABASE_URL
    
    # 检查迁移目录
    if [ ! -d "${MIGRATIONS_DIR}" ]; then
        print_warning "迁移目录不存在: ${MIGRATIONS_DIR}"
        print_info "创建迁移目录..."
        mkdir -p "${MIGRATIONS_DIR}"
    fi
    
    # 运行迁移
    sqlx migrate run --source "${MIGRATIONS_DIR}"
    
    print_success "数据库迁移完成"
}

# =============================================================================
# 回滚迁移
# =============================================================================

rollback_migration() {
    print_info "回滚最后一次迁移..."
    
    export DATABASE_URL
    
    sqlx migrate revert --source "${MIGRATIONS_DIR}"
    
    print_success "迁移已回滚"
}

# =============================================================================
# 清除数据库
# =============================================================================

drop_database() {
    print_warning "即将删除数据库: ${DB_NAME}"
    read -q "REPLY?确认删除吗？(y/N): "
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        export DATABASE_URL
        
        # 断开所有连接
        "${PG_BIN}/psql" -p "${DB_PORT}" -d postgres -c "
            SELECT pg_terminate_backend(pid)
            FROM pg_stat_activity
            WHERE datname = '${DB_NAME}' AND pid <> pg_backend_pid();
        " > /dev/null 2>&1
        
        # 删除数据库
        sqlx database drop
        
        print_success "数据库 ${DB_NAME} 已删除"
    else
        print_info "操作已取消"
    fi
}

# =============================================================================
# 重置数据库
# =============================================================================

reset_database() {
    print_warning "即将重置数据库: ${DB_NAME}"
    read -q "REPLY?确认重置吗？(y/N): "
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        export DATABASE_URL
        
        # 断开所有连接
        "${PG_BIN}/psql" -p "${DB_PORT}" -d postgres -c "
            SELECT pg_terminate_backend(pid)
            FROM pg_stat_activity
            WHERE datname = '${DB_NAME}' AND pid <> pg_backend_pid();
        " > /dev/null 2>&1
        
        # 删除并重新创建数据库
        sqlx database drop
        sqlx database create
        sqlx migrate run --source "${MIGRATIONS_DIR}"
        
        print_success "数据库 ${DB_NAME} 已重置"
    else
        print_info "操作已取消"
    fi
}

# =============================================================================
# 查看迁移状态
# =============================================================================

migration_status() {
    print_info "迁移状态:"
    
    export DATABASE_URL
    
    sqlx migrate info --source "${MIGRATIONS_DIR}"
}

# =============================================================================
# 创建新的迁移文件
# =============================================================================

create_migration() {
    if [ -z "$1" ]; then
        print_error "请指定迁移名称，例如: $0 new heartbeat_logs"
        exit 1
    fi
    
    print_info "创建迁移: $1"
    
    export DATABASE_URL
    
    sqlx migrate add "$1" --source "${MIGRATIONS_DIR}"
    
    print_success "迁移文件已创建"
}

# =============================================================================
# 主菜单
# =============================================================================

show_help() {
    echo "用法: $0 <命令>"
    echo ""
    echo "命令:"
    echo "  init        初始化：检测工具、创建数据库、运行迁移"
    echo "  create      创建数据库"
    echo "  migrate     运行迁移"
    echo "  rollback    回滚最后一次迁移"
    echo "  drop        删除数据库"
    echo "  reset       重置数据库（删除并重新创建）"
    echo "  status      查看迁移状态"
    echo "  new <name>  创建新的迁移文件"
    echo "  help        显示帮助信息"
}

# =============================================================================
# 主程序
# =============================================================================

main() {
    case "${1:-help}" in
        init)
            check_and_install_sqlx_cli
            check_and_start_postgres
            create_database
            run_migrations
            print_success "数据库初始化完成！"
            print_info "连接字符串: ${DATABASE_URL}"
            ;;
        create)
            check_and_start_postgres
            create_database
            ;;
        migrate)
            check_and_start_postgres
            run_migrations
            ;;
        rollback)
            check_and_start_postgres
            rollback_migration
            ;;
        drop)
            check_and_start_postgres
            drop_database
            ;;
        reset)
            check_and_start_postgres
            reset_database
            ;;
        status)
            migration_status
            ;;
        new)
            create_migration "$2"
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "未知命令: $1"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
