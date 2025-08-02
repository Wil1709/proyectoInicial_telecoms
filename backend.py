import asyncio
from pathlib import Path
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.responses import JSONResponse

APP_FILE = Path("lecturas.txt")
app = FastAPI(title="Lecturas Ultrasonico")

def parse_line(line: str):
    # Espera "timestamp;distancia"
    line = line.strip()
    if not line or ";" not in line:
        return None
    ts, value = line.split(";", 1)
    try:
        dist = float(value)
    except ValueError:
        return None
    return {"timestamp": ts, "distance_cm": dist}

@app.get("/data")
def get_data(limit: int = 100):
    """
    Devuelve las últimas N lecturas del archivo como JSON.
    Ej: GET /data?limit=50
    """
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
    """
    Emite nuevas lecturas en tiempo (casi) real, "taileando" el archivo.
    Un mensaje JSON por lectura: {"timestamp": "...", "distance_cm": 123.45}
    """
    await ws.accept()
    APP_FILE.touch(exist_ok=True)
    with APP_FILE.open("r", encoding="utf-8") as f:
        f.seek(0, 2)  # EOF
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
