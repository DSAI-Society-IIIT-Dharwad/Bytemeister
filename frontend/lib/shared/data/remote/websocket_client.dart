import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketClient {
  WebSocketChannel? _channel;

  Stream<dynamic>? connect(String url) {
    _channel = WebSocketChannel.connect(Uri.parse(url));
    return _channel?.stream;
  }

  void send(dynamic message) {
    _channel?.sink.add(message);
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }
}
