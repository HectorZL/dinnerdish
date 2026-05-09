import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dinnerhome/providers/providers.dart';
import 'package:dinnerhome/services/in_memory/in_memory_auth_service.dart';

void main() {
  group('Providers', () {
    test('authServiceProvider returns InMemoryAuthService', () {
      final container = ProviderContainer();
      addTearDown(() => container.dispose());

      final authService = container.read(authServiceProvider);
      expect(authService, isA<InMemoryAuthService>());
    });

    test('menuServiceProvider returns InMemoryMenuService', () {
      final container = ProviderContainer();
      addTearDown(() => container.dispose());

      final menuService = container.read(menuServiceProvider);
      expect(menuService, isNotNull);
    });

    test('currentUserProvider can be overridden', () {
      final container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(InMemoryAuthService()),
        ],
      );
      addTearDown(() => container.dispose());

      final authService = container.read(authServiceProvider);
      expect(authService, isA<InMemoryAuthService>());
    });
  });
}
