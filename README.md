# 📊 Sensor Ultrasónico - Dashboard en Tiempo Real

Sistema de monitoreo de distancias con dashboard web en tiempo real usando IPv6.

## 🚀 Archivos Principales

- **`backend.py`** - Servidor FastAPI con soporte IPv6 y WebSockets
- **`dashboard.html`** - Dashboard web con gráficas en tiempo real
- **`lecturas.txt`** - Archivo de datos del sensor (formato: timestamp;distancia)

## ⚡ Inicio Rápido

### 1. Iniciar el servidor:
```bash
reiniciar_con_cors.bat
```

### 2. Generar datos de prueba:
```bash
generar_datos.bat
```

### 3. Abrir el dashboard:
Abre `dashboard.html` en tu navegador

## 📋 Scripts Disponibles

- **`reiniciar_con_cors.bat`** - Inicia el servidor con soporte CORS
- **`generar_datos.bat`** - Genera datos de prueba
- **`probar_conexion_completa.bat`** - Prueba todo el sistema

## 🔧 Características

- ✅ Soporte IPv6 completo
- ✅ WebSockets en tiempo real
- ✅ Dashboard con gráficas interactivas
- ✅ CORS habilitado
- ✅ Puerto automático (8000-8009)
- ✅ Reconexión automática

## 📊 Dashboard

El dashboard muestra:
- Distancia actual, mínima, máxima y promedio
- Gráfica en tiempo real
- Histograma de distribución
- Gráfica de tendencia
- Estado de conexión

## 🌐 URLs

- **Dashboard**: `http://localhost:8000` (o puerto asignado)
- **API**: `http://localhost:8000/data`
- **WebSocket**: `ws://localhost:8000/ws`

## 📝 Formato de Datos

Cada línea en `lecturas.txt` debe tener el formato:
```
2024-01-15 14:30:25;45.67
```

Donde:
- `2024-01-15 14:30:25` = Timestamp
- `45.67` = Distancia en centímetros