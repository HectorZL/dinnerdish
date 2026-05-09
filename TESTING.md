# Testing Guide — DinnerHome

## Running in Mock Mode

The app runs with in-memory services by default. No backend required.

### Prerequisites
- Flutter 3.x
- Dart 3.x

### Setup
```bash
git clone <repo>
cd dinnerhome
flutter pub get
flutter pub run build_runner build
flutter run
```

### Features Available
| Screen | Route | Role | Description |
|--------|-------|------|-------------|
| Login | /login | All | Login with any credentials |
| Main Menu | /menu | All | Dashboard with module access |
| Create Order | /orders/create | Mesero | Select dishes, send to kitchen |
| Order Detail | /orders/:id | Mesero | View/edit order, request payment |
| KDS | /kds | Cocinero | Real-time kitchen tickets |
| Audit Log | /audit | Admin | View all recorded actions |

### Mock Data
- **Users**: Login with any username/password (auto-creates Mesero role)
- **Menu**: 5 items (Pasta Carbonara, Ensalada César, Lomo Saltado, Ceviche Mixto, Sopa del Día)
- **Real-time**: Order events flow through in-memory SocketService

### Testing Flows

#### 1. Mesero Completo
1. Open app → Login with any credentials
2. Go to Main Menu
3. Tap "Crear Orden" → select dishes → add items
4. Tap "Enviar a Cocina" → confirm modal
5. Create another order
6. View KDS in another tab to see tickets arrive

#### 2. Kitchen (KDS)
1. Login as cocinero (or any role)
2. Navigate to /kds
3. View incoming tickets in real-time
4. Tap "Iniciar Preparación" / "Marcar Listo"

#### 3. Payment
1. From Order Detail, tap "Solicitar Pago"
2. Check Audit Log for the transaction record

### Running Tests
```bash
flutter test
```

### Project Structure
```
lib/
├── models/          # Data classes with Hive annotations
├── services/        # Service abstractions + implementations
│   ├── in_memory/   # Mock services for development
│   └── hive/        # Audit service with Hive persistence
├── providers/       # Riverpod providers
├── router/          # GoRouter configuration + guards
├── presentation/
│   └── screens/     # All UI screens
├── widgets/         # Reusable UI components
└── main.dart        # App entry point
```
