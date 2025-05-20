class WebDAVConfig {
  final String name;
  final String protocol;
  final String address;
  final int port;
  final String username;
  final String password;
  final String path;

  const WebDAVConfig({
    required this.name,
    required this.protocol,
    required this.address,
    required this.port,
    required this.username,
    required this.password,
    required this.path,
  });

  String get fullUrl => '$protocol://$address:$port$path/';

  factory WebDAVConfig.fromJson(configName, Map<String, dynamic> json) {
    return WebDAVConfig(
      name: configName,
      protocol: json['protocol'] ?? 'https',
      address: json['address'] ?? '',
      port: json['port'] ?? 80,
      username: json['username'] ?? '',
      password: json['password'] ?? '',
      path: json['path'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'protocol': protocol,
      'address': address,
      'port': port,
      'username': username,
      'password': password,
      'path': path,
    };
  }
}