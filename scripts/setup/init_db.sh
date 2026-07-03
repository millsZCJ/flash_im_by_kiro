#!/usr/bin/env zsh
# =============================================================================
# init_db.sh
# 快速初始化数据库（简化版）
# =============================================================================

set -e

echo "🚀 初始化数据库..."

# 运行数据库管理脚本
./scripts/database/db_manager.sh init

echo ""
echo "✅ 数据库初始化完成！"
echo ""
echo "下一步："
echo "  1. 复制环境变量: cp server/.env.example server/.env"
echo "  2. 运行服务器: cd server && cargo run"
echo ""
