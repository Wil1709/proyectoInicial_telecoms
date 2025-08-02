import re
import time
import sys
from datetime import datetime
from pathlib import Path

import serial  # pip install pyserial

SERIAL_PORT = "COM4"   # <-- tu puerto en Windows
BAUDRATE = 9600
OUTPUT_FILE = Path("lecturas.txt")

# Tu sketch imprime "Distancia: X cm", así que usamos regex para extraer el número
number_regex = re.compile(r"[-+]?\d*\.?\d+(?:[eE][-+]?\d+)?")

def parse_distance(line: str) -> float | None:
    line = line.strip()
    if not line:
        return None
    m = number_regex.search(line)
    return float(m.group()) if m else None

def main():
    print(f"Abriendo puerto {SERIAL_PORT} a {BAUDRATE} baudios...")
    try:
        with serial.Serial(SERIAL_PORT, BAUDRATE, timeout=2) as ser, OUTPUT_FILE.open("a", encoding="utf-8") as f:
            print(f"Escribiendo en {OUTPUT_FILE.resolve()}")
            while True:
                try:
                    raw = ser.readline().decode("utf-8", errors="ignore")
                    dist = parse_distance(raw)
                    if dist is None:
                        continue
                    ts = datetime.now().isoformat(timespec="seconds")
                    line_out = f"{ts};{dist:.2f}\n"  # timestamp;distancia_cm
                    f.write(line_out)
                    f.flush()  # asegura que quede en disco
                    print(line_out, end="")
                except KeyboardInterrupt:
                    print("\nSaliendo por teclado...")
                    break
                except Exception as e:
                    print(f"Error en lectura/escritura: {e}", file=sys.stderr)
                    time.sleep(0.5)
    except serial.SerialException as e:
        print(f"No se pudo abrir el puerto serie: {e}", file=sys.stderr)

if __name__ == "__main__":
    main()
