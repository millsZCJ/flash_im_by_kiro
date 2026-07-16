/// Flash IM 核心模块
///
/// 当前版本包含 Protobuf 协议定义与 WebSocket 客户端。
library;

// data
export 'src/data/proto/ws.pb.dart';
export 'src/data/proto/ws.pbenum.dart';
export 'src/data/im_config.dart';

// logic
export 'src/logic/ws_client.dart';

// view
export 'src/view/ws_status_indicator.dart';
