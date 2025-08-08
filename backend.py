import asyncio
from pathlib import Path
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
import socket
import os
import psutil  # pip install psutil

APP_FILE = Path("lecturas.txt")
app = FastAPI(title="Lecturas Ultrasonico")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

def get_ipv6_with_scope():
    """
    Devuelve la dirección IPv6 global o link-local con scope_id incluido si aplica.
    Ejemplo: fe80::1a52:34ee:69de:e766%Ethernet  (o %15)
    """
    try:
        for iface_name, addrs in psutil.net_if_addrs().items():
            for addr in addrs:
                if addr.family == socket.AF_INET6:
                    ipv6 = addr.address
                    # Saltar loopback ::1
                    if ipv6.startswith("::1"):
                        continue
                    # Si es link-local (fe80::), asegurar que tenga scope
                    if ipv6.startswith("fe80::") and "%" not in ipv6:
                        ipv6 = f"{ipv6}%{iface_name}"
                    return ipv6
        return "::1"  # Fallback a loopback IPv6
    except Exception:
        return "::1"

def parse_line(line: str):
    line = line.strip()
    if not line or ";" not in line:
        return None
    ts, value = line.split(";", 1)
    try:
        dist = float(value)
    except ValueError:
        return None
    return {"timestamp": ts, "distance_cm": dist}

def ipv6_urlsafe(ipv6: str) -> str:
    """
    Para URLs IPv6 hay que escapar el scope id: "%" -> "%25"
    """
    return ipv6.replace("%", "%25")

@app.get("/data")
def get_data(limit: int = 100):
    if not APP_FILE.exists():
        return JSONResponse(content=[])
    lines = APP_FILE.read_text(encoding="utf-8").strip().splitlines()
    sliced = lines[-limit:] if limit > 0 else lines
    out = []
    for ln in sliced:
        obj = parse_line(ln)
        if obj:
            out.append(obj)
    return out

@app.websocket("/ws")
async def websocket_endpoint(ws: WebSocket):
    await ws.accept()
    APP_FILE.touch(exist_ok=True)
    with APP_FILE.open("r", encoding="utf-8") as f:
        f.seek(0, 2)
        try:
            while True:
                line = f.readline()
                if not line:
                    await asyncio.sleep(0.2)
                    continue
                obj = parse_line(line)
                if obj:
                    await ws.send_json(obj)
        except WebSocketDisconnect:
            pass

@app.get("/")
def read_root():
    ipv6_addr = get_ipv6_with_scope()
    port = int(os.environ.get("PORT", 8000))
    ipv6_url = ipv6_urlsafe(ipv6_addr)  # <-- versión segura para URL

    return {
        "message": "Servidor de lecturas ultrasónicas funcionando en IPv6",
        "ipv6_address": ipv6_addr,             # crudo (para mostrar)
        "ipv6_address_url": ipv6_url,          # seguro para URL
        "websocket_url": f"ws://[{ipv6_url}]:{port}/ws",
        "data_url": f"http://[{ipv6_url}]:{port}/data",
        "local_url": f"http://[::1]:{port}",
        "port": port
    }

if __name__ == "__main__":
    ipv6_addr = get_ipv6_with_scope()
    port = 8000
    print(f"🚀 Iniciando servidor IPv6 en: [{ipv6_addr}]:{port}")
    uvicorn.run(
        app,
        host="::",  # Solo IPv6
        port=port,
        log_level="info"
    )
