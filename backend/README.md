# DinnerHome POS Backend - Guía de Despliegue en Railway

Este es el backend de **DinnerHome POS**, desarrollado en **FastAPI** con **SQLAlchemy**, **WebSockets** en tiempo real y soporte nativo para **PostgreSQL** y **SQLite**.

---

## 🚀 Despliegue Rápido en Railway

### Opción 1: Desde la Interfaz Web de Railway (Recomendado)

1. **Crear Proyecto en Railway**:
   - Entra a [railway.app](https://railway.app) e inicia sesión.
   - Haz clic en **"New Project"** -> **"Deploy from GitHub repo"**.
   - Selecciona tu repositorio `dinnerhome`.

2. **Agregar Base de Datos PostgreSQL**:
   - En el panel del proyecto en Railway, haz clic en **"+ New"** -> **"Database"** -> **"Add PostgreSQL"**.
   - Railway creará la base de datos y generará automáticamente la variable `DATABASE_URL`.

3. **Vincular Variables de Entorno en el Servicio**:
   - Haz clic en el servicio de tu aplicación FastAPI.
   - Ve a la pestaña **"Variables"**.
   - Agrega las siguientes variables:
     - `DATABASE_URL`: Selecciona **"Add Reference"** y elige `${{Postgres.DATABASE_URL}}` (o la variable del servicio PostgreSQL creado).
     - `JWT_SECRET_KEY`: Una cadena segura aleatoria (ej: `mi_clave_super_secreta_pos_2026_xYz987`).
     - `CORS_ORIGINS`: `*` (o la URL de tu frontend Flutter Web).
     - `ADMIN_USERNAME`: `admin` (opcional, por defecto es `admin`).
     - `ADMIN_PASSWORD`: `admin123` (opcional, por defecto es `admin123`).

4. **Configurar el Root Directory (si es necesario)**:
   - Si despliegas desde el monorepo, en **Settings** -> **Root Directory**, escribe: `/backend` (o déjalo en raíz gracias al archivo `railway.json`).

5. **Generar Dominio Público**:
   - En la pestaña **Settings** de tu servicio en Railway, ve a **"Networking"** y haz clic en **"Generate Domain"**.
   - Obtendrás una URL como `https://dinnerhome-production.up.railway.app`.

---

## 🌐 Endpoints Principales

| Módulo | Método | Endpoint | Descripción |
|---|---|---|---|
| **Sistema** | `GET` | `/health` | Chequeo de salud del servicio |
| **Documentación** | `GET` | `/docs` | Swagger UI interactivo interactivo |
| **Auth** | `POST` | `/api/auth/login` | Inicio de sesión (JWT) |
| **Auth** | `GET` | `/api/auth/me` | Perfil del usuario autenticado |
| **Usuarios** | `GET` / `POST` | `/api/users` | Listar y crear usuarios |
| **Menú** | `GET` / `POST` | `/api/menu` | Catálogo de platos y stock |
| **Menú** | `POST` | `/api/menu/{id}/stock` | Ajuste de inventario en tiempo real |
| **Adicionales** | `GET` / `POST` | `/api/additionals` | Adicionales globales y especiales |
| **Mesas** | `GET` / `POST` | `/api/tables` | Mesas y estado (`available`, `occupied`) |
| **Pedidos** | `POST` | `/api/orders/draft` | Crear borrador de comanda |
| **Pedidos** | `POST` | `/api/orders/{id}/send-to-kitchen` | Enviar a KDS / Cocina |
| **Pedidos** | `GET` | `/api/orders/active` | Pedidos activos en curso |
| **Pagos** | `POST` | `/api/payments/process` | Procesar pago (Efectivo, Tarjeta, etc.) |
| **Caja** | `POST` | `/api/cash-drawer/open` | Abrir turno de caja |
| **Auditoría** | `GET` | `/api/audit` | Historial de auditoría |
| **WebSockets** | `WS` | `/ws` | Sincronización en tiempo real para KDS y POS |

---

## 💻 Ejecución Local

Para probar el backend en tu máquina:

```powershell
cd backend
python -m venv venv
.\venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```

Abre en tu navegador:
- API Docs: `http://localhost:8000/docs`
- Healthcheck: `http://localhost:8000/health`
