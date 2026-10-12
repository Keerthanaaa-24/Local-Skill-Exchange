import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'api_client.dart';

import '../core/network/token_storage.dart';

class WebSocketManager {
  WebSocketChannel? _channel;
  
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  bool _isConnecting = false;
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 5;

  Future<void> connect() async {
    if (_channel != null || _isConnecting) return;

    _isConnecting = true;
    final token = await TokenStorage.getToken();

    
    if (token == null) {
      _isConnecting = false;
      return;
    }

    try {
      final baseUri = Uri.parse(apiClient.dio.options.baseUrl);
      final wsUri = baseUri.replace(scheme: baseUri.scheme == 'https' ? 'wss' : 'ws');
      final path = wsUri.path.endsWith('/') ? '${wsUri.path}chat/ws' : '${wsUri.path}/chat/ws';
      final fullWsUri = wsUri.replace(path: path, queryParameters: {'token': token});
      debugPrint('Attempting WebSocket connection to: ${wsUri.toString()}/chat/ws?token=***');
      _channel = WebSocketChannel.connect(fullWsUri);

      _reconnectAttempts = 0; // Reset on successful connect
      _startHeartbeat();

      _channel?.stream.listen(
        (data) {
          try {
            final Map<String, dynamic> json = jsonDecode(data);
            if (json['type'] == 'pong' || json['type'] == 'ping') {
              return;
            }
            _messageController.add(json);
          } catch (e) {
            debugPrint('Failed to decode WS message: $e');
          }
        },
        onError: (error) {
          debugPrint('WebSocket Error: $error');
          _handleDisconnect();
        },
        onDone: () {
          debugPrint('WebSocket Closed');
          _handleDisconnect();
        },
      );
    } catch (e) {
      debugPrint('WebSocket Connection Error: $e');
      _handleDisconnect();
    } finally {
      _isConnecting = false;
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_channel != null) {
        send({'type': 'ping'});
      }
    });
  }

  void _handleDisconnect() {
    _channel?.sink.close(status.goingAway);
    _channel = null;
    _heartbeatTimer?.cancel();

    TokenStorage.getToken().then((token) {
      if (token == null || token.isEmpty) return;

      if (_reconnectAttempts < maxReconnectAttempts) {
        _reconnectAttempts++;
        final backoff = Duration(seconds: 2 * _reconnectAttempts);
        debugPrint('Reconnecting in ${backoff.inSeconds} seconds...');
        
        _reconnectTimer?.cancel();
        _reconnectTimer = Timer(backoff, () {
          connect();
        });
      }
    });
  }

  void send(Map<String, dynamic> data) {
    if (_channel != null) {
      _channel?.sink.add(jsonEncode(data));
    }
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    _channel?.sink.close(status.goingAway);
    _channel = null;
    _reconnectAttempts = maxReconnectAttempts; // Prevent auto-reconnect
  }

  void dispose() {
    disconnect();
    _messageController.close();
  }
}

final webSocketManager = WebSocketManager();
