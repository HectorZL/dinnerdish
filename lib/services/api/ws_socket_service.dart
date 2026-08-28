import 'dart:async';
import 'dart:convert';
import 'package:dinnerhome/models/order.dart';
import 'package:dinnerhome/services/order_service.dart';
import 'package:dinnerhome/services/socket_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'api_config.dart';

class WsSocketService implements SocketService {
  final _eventController = StreamController<OrderEvent>.broadcast();
  WebSocketChannel? _channel;
  bool _isDisposed = false;
  Timer? _reconnectTimer;

  WsSocketService({bool autoConnect = true}) {
    if (autoConnect && !ApiConfig.isTestEnvironment) {
      _connect();
    }
  }

  void _connect() {
    if (_isDisposed || ApiConfig.isTestEnvironment) return;

    try {
      final uri = Uri.parse(ApiConfig.wsUrl);
      _channel = WebSocketChannel.connect(uri);

      _channel!.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message.toString());
            if (data is Map<String, dynamic>) {
              final type = data['type'] as String? ?? 'update';
              final payload = data['payload'];
              if (payload is Map<String, dynamic>) {
                if (payload.containsKey('tableId') && payload.containsKey('items')) {
                  final order = Order.fromJson(payload);
                  _eventController.add(OrderEvent(
                    orderId: order.id,
                    eventType: type,
                    order: order,
                  ));
                } else if (payload.containsKey('order') && payload['order'] is Map<String, dynamic>) {
                  final order = Order.fromJson(payload['order'] as Map<String, dynamic>);
                  _eventController.add(OrderEvent(
                    orderId: order.id,
                    eventType: type,
                    order: order,
                  ));
                }
              }
            }
          } catch (_) {
            // Ignore malformed WS message
          }
        },
        onError: (err) {
          _scheduleReconnect();
        },
        onDone: () {
          _scheduleReconnect();
        },
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_isDisposed) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      _connect();
    });
  }

  @override
  Stream<OrderEvent> get orderEvents => _eventController.stream;

  @override
  void emitOrderEvent(OrderEvent event) {
    if (_channel != null) {
      try {
        _channel!.sink.add(jsonEncode({
          'type': event.eventType,
          'payload': event.order.toJson(),
        }));
      } catch (_) {}
    }
    _eventController.add(event);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _eventController.close();
  }
}
