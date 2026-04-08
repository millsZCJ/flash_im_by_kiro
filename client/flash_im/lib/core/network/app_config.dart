/// 全局网络配置，IP 变化时只改这里
class AppConfig {
  static String host = '192.168.122.208';
  static int port = 3000;

  static String get baseUrl => 'http://$host:$port';
}
