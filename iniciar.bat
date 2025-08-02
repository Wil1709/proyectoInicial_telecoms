@echo off
REM ==========================================================
REM Iniciar Logger (Arduino) + Backend FastAPI (Windows)
REM Ruta del proyecto: C:\xampp\htdocs\proyecto_inicial
REM ==========================================================

set "ROOT=C:\xampp\htdocs\proyecto_inicial"

REM Ir a la carpeta del proyecto
cd /d "%ROOT%" || (
  echo [ERROR] No se pudo acceder a %ROOT%
  pause
  exit /b 1
)

REM Elegir comando de Python (py o python)
where py >nul 2>nul
if %errorlevel%==0 (
  set "PYCMD=py"
) else (
  set "PYCMD=python"
)

echo.
echo === Verificando/instalando dependencias (puede tardar la primera vez) ===
%PYCMD% -m pip --version >nul 2>nul || (
  echo [ADVERTENCIA] pip no encontrado. Asegurate de tener Python en PATH.
)

REM FastAPI
%PYCMD% -m pip show fastapi >nul 2>nul || %PYCMD% -m pip install fastapi
REM Uvicorn con soporte WebSocket
%PYCMD% -m pip show uvicorn >nul 2>nul || %PYCMD% -m pip install "uvicorn[standard]"
REM Por si uvicorn ya estaba sin extra, aseguramos websockets
%PYCMD% -m pip show websockets >nul 2>nul || %PYCMD% -m pip install websockets
REM PySerial para el logger
%PYCMD% -m pip show pyserial >nul 2>nul || %PYCMD% -m pip install pyserial

echo.
echo === Preparando archivo de lecturas ===
if not exist "lecturas.txt" type nul > "lecturas.txt"

echo.
echo === Iniciando procesos ===
echo (Recuerda cerrar el Monitor Serial del IDE de Arduino para liberar COM4)

REM Iniciar logger en una ventana separada
start "Logger - Arduino" cmd /k "title Logger - Arduino & %PYCMD% logger.py"

REM Pequeña espera para que el logger arranque primero
timeout /t 2 /nobreak >nul

REM Iniciar backend FastAPI en otra ventana
start "Backend - FastAPI" cmd /k %PYCMD% -m uvicorn backend:app --reload --port 8000

echo.
echo ===============================================
echo Procesos levantados:
echo   - Logger leyendo COM4 (ventana "Logger - Arduino")
echo   - Backend en http://127.0.0.1:8000 (ventana "Backend - FastAPI")
echo Cierra esas ventanas para detenerlos.
echo ===============================================
pause
