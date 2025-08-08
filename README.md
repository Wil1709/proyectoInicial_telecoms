# 📊 Sensor Ultrasónico - Dashboard en Tiempo Real

Sistema de monitoreo de distancias con dashboard web en tiempo real usando IPv6.

# Visión general

## Frontend (`dashboard_ipv6.html`)
Página con **Chart.js** que:
- Obtiene info del backend (`/`) para saber la IP/URLs.
- Precarga histórico (`/data`).
- Abre un **WebSocket** (`/ws`) para recibir lecturas en tiempo real.
- Actualiza métricas:
  - Actual
  - Mínimo
  - Máximo
  - Promedio
  - Conteo único
- Actualiza **3 gráficas**.
- Prefiere **IPv6** y hace fallback a **IPv4** si el navegador no permite IPv6.

## Backend (`backend.py`, FastAPI)
- **GET `/`**:
  - Detecta IPv6 local (con scope si es `fe80::`).
  - La hace URL-safe y devuelve:
    - `websocket_url`
    - `data_url`
    - `local_url`
    - `port`
- **GET `/data`**:
  - Lee `lecturas.txt`, parsea líneas `timestamp;distancia` y responde JSON.
- **WS `/ws`**:
  - Hace “tail” del archivo y envía cada nueva lectura como JSON al cliente.
- Escucha en `host="::"` (solo IPv6).
- **CORS habilitado**.

## Fuente de datos
- `logger.py` (lanzado por `iniciar.bat`) lee del puerto serie (COM3) y escribe en `lecturas.txt` líneas:


## Scripts
- **`iniciar.bat`**: instala dependencias, arranca `logger.py` y el backend.
- **`reiniciar_con_cors.bat`**: mata procesos Python y arranca `backend.py`.

---

# Flujo de datos (paso a paso)
1. `logger.py` escribe mediciones en `lecturas.txt` como `timestamp;distancia`.
2. El backend:
 - En `/data` entrega el histórico leído del archivo.
 - En `/ws` “sigue” el archivo y emite cada nueva línea como JSON.
 - En `/` publica la dirección IPv6 detectada y URLs listas para usar.
3. El dashboard:
 - Llama a `/` (IPv6 → fallback IPv4) y muestra la IP una sola vez.
 - Precarga datos desde `/data`.
 - Abre el WebSocket (IPv6 → fallback IPv4).
 - Cada mensaje recibido se ingresa si su timestamp no fue visto (evita duplicados) y actualiza métricas/gráficas.
 - Si se cae la conexión, reintenta automáticamente.