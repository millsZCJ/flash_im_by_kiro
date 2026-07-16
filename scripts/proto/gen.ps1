# Protobuf 统一代码生成脚本
# 用法：powershell -ExecutionPolicy Bypass -File scripts/proto/gen.ps1
# 修改 proto/ 下的 .proto 文件后，执行此脚本即可同步更新前后端代码

$ErrorActionPreference = "Stop"

$protoDir = "proto"
$dartOut = "client/modules/flash_im_core/lib/src/data/proto"

# ===== 后端（Rust）=====
# prost-build 在 cargo build 时自动触发，这里显式编译 im-ws 确保生成
Write-Host "🔧 [后端] 编译 im-ws（触发 prost-build）..."
Push-Location server
cargo build -p im-ws
Pop-Location
Write-Host "✅ [后端] Rust proto 代码已生成"

# ===== 前端（Dart）=====
Write-Host "🔧 [前端] 生成 Dart proto 代码..."
New-Item -ItemType Directory -Force -Path $dartOut | Out-Null
protoc --proto_path=$protoDir --dart_out=$dartOut "$protoDir/ws.proto"
Write-Host "✅ [前端] Dart proto 代码已生成到 $dartOut"

Write-Host ""
Write-Host "🎉 前后端协议代码已同步更新"
