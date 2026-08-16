import 'package:dinnerhome/exceptions/app_exception.dart';
import 'package:dinnerhome/services/audit_service.dart';
import 'package:dinnerhome/services/menu_service.dart';

const maximumStock = 999999;

class RestockRequest {
  final String operationId;
  final String itemId;
  final String? variationId;
  final int quantity;
  final int? expectedCurrentStock;
  final String userId;

  const RestockRequest({
    required this.operationId,
    required this.itemId,
    required this.quantity,
    required this.userId,
    this.variationId,
    this.expectedCurrentStock,
  });
}

class RestockResult {
  final String operationId;
  final String itemId;
  final String? variationId;
  final int previousStock;
  final int addedQuantity;
  final int newStock;

  const RestockResult({
    required this.operationId,
    required this.itemId,
    required this.variationId,
    required this.previousStock,
    required this.addedQuantity,
    required this.newStock,
  });
}

class StockRestockException extends AppException {
  const StockRestockException(super.message, [super.code = 'STOCK_ERROR']);
}

class StockRestockValidationException extends StockRestockException {
  const StockRestockValidationException()
    : super(
        'La reposición debe ser un número entero positivo.',
        'STOCK_INVALID_QUANTITY',
      );
}

class StockRestockLimitException extends StockRestockException {
  const StockRestockLimitException()
    : super(
        'La reposición supera el máximo permitido.',
        'STOCK_LIMIT_EXCEEDED',
      );
}

class StockRestockConflictException extends StockRestockException {
  const StockRestockConflictException()
    : super(
        'El stock cambió. Actualiza el valor y vuelve a intentar.',
        'STOCK_CONFLICT',
      );
}

class StockRestockNotFoundException extends StockRestockException {
  const StockRestockNotFoundException()
    : super('El plato o la variación no existe.', 'STOCK_TARGET_NOT_FOUND');
}

abstract class StockService {
  Future<RestockResult> restock(RestockRequest request);
}

class MenuStockService implements StockService {
  final MenuService _menuService;
  final AuditService? _auditService;
  final Map<String, RestockResult> _completedOperations = {};

  MenuStockService(this._menuService, {AuditService? auditService})
    : _auditService = auditService;

  @override
  Future<RestockResult> restock(RestockRequest request) async {
    if (request.quantity <= 0) {
      throw const StockRestockValidationException();
    }
    if (request.operationId.trim().isEmpty || request.userId.trim().isEmpty) {
      throw const StockRestockValidationException();
    }

    final previousOperation = _completedOperations[request.operationId];
    if (previousOperation != null) {
      if (previousOperation.itemId != request.itemId ||
          previousOperation.variationId != request.variationId ||
          previousOperation.addedQuantity != request.quantity) {
        throw const StockRestockConflictException();
      }
      return previousOperation;
    }

    final item = await _menuService.getMenuItem(request.itemId);
    if (item == null) {
      throw const StockRestockNotFoundException();
    }

    final previousStock = _readStock(item, request.variationId);
    if (previousStock == null) {
      throw const StockRestockNotFoundException();
    }
    if (request.expectedCurrentStock != null &&
        request.expectedCurrentStock != previousStock) {
      throw const StockRestockConflictException();
    }
    if (request.quantity > maximumStock - previousStock) {
      throw const StockRestockLimitException();
    }

    final newStock = previousStock + request.quantity;
    await _menuService.adjustStock(
      request.itemId,
      request.variationId,
      request.quantity,
    );

    final updated = await _menuService.getMenuItem(request.itemId);
    final persistedStock = updated == null
        ? null
        : _readStock(updated, request.variationId);
    if (persistedStock != newStock) {
      throw const StockRestockException(
        'No se pudo guardar la reposición. Puedes reintentar.',
        'STOCK_STORAGE_ERROR',
      );
    }

    final result = RestockResult(
      operationId: request.operationId,
      itemId: request.itemId,
      variationId: request.variationId,
      previousStock: previousStock,
      addedQuantity: request.quantity,
      newStock: newStock,
    );
    _completedOperations[request.operationId] = result;

    try {
      await _auditService?.record(
        action: 'stock_restocked',
        userId: request.userId,
        metadata: {
          'itemId': request.itemId,
          'variationId': request.variationId,
          'previousStock': previousStock,
          'addedQuantity': request.quantity,
          'newStock': newStock,
          'operationId': request.operationId,
        },
      );
    } catch (_) {
      // La reposición ya fue confirmada. No se vuelve a sumar stock si falla
      // únicamente el registro de auditoría.
    }

    return result;
  }

  int? _readStock(dynamic item, String? variationId) {
    if (variationId == null || variationId.isEmpty) return item.stock as int;
    for (final variation in item.variations) {
      if (variation.id == variationId) return variation.stock;
    }
    return null;
  }
}
