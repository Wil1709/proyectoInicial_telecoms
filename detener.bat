@echo off
REM ==========================================================
REM Script para detener Logger (Arduino) y Backend FastAPI
REM ==========================================================

echo.
echo === Cerrando procesos Logger y Backend ===

REM Cerrar ventana del Logger
taskkill /FI "WINDOWTITLE eq Logger - Arduino*" /T /F >nul 2>&1

REM Cerrar ventana del Backend
taskkill /FI "WINDOWTITLE eq Backend - FastAPI*" /T /F >nul 2>&1

echo.
echo ===============================================
echo Procesos finalizados (si estaban en ejecución).
echo ===============================================
pause
