@echo off
setlocal

REM ================================================
REM Gestor: Logger (Arduino) + Backend FastAPI  [v2]
REM Ruta del proyecto:
set "ROOT=C:\xampp\htdocs\proyecto_inicial"
REM ================================================

:menu
cls
echo ===============================================
echo   GESTOR DE PROCESOS - SENSOR ULTRASONICO (v2)
echo   Ruta: %ROOT%
echo ===============================================
echo   [1] Iniciar Logger y Backend
echo   [2] Detener Logger y Backend
echo   [3] Ver estado
echo   [4] Ver ultimas lecturas (lecturas.txt)
echo   [5] Salir
echo ===============================================
choice /C 12345 /N /M "Selecciona opcion [1-5]: "
set "opt=%errorlevel%"

if %opt%==5 goto :fin
if %opt%==4 goto :verlogs
if %opt%==3 goto :estado
if %opt%==2 goto :detener
if %opt%==1 goto :iniciar
goto :menu

:iniciar
echo.
echo === Iniciando ===
cd /d "%ROOT%" || (echo [ERROR] No se pudo acceder a %ROOT% & pause & goto :menu)

REM Detectar comando de Python
where py >nul 2>nul && (set "PYCMD=py") || (set "PYCMD=python")

echo - Verificando/instalando dependencias (solo primera vez)...
%PYCMD% -m pip show fastapi >nul 2>nul || %PYCMD% -m pip install fastapi
%PYCMD% -m pip show uvicorn >nul 2>nul || %PYCMD% -m pip install "uvicorn[standard]"
%PYCMD% -m pip show websockets >nul 2>nul || %PYCMD% -m pip install websockets
%PYCMD% -m pip show pyserial >nul 2>nul || %PYCMD% -m pip install pyserial

if not exist "lecturas.txt" type nul > "lecturas.txt"

echo - Lanzando Logger (COM4)...
REM Lanzar DIRECTAMENTE python/py y guardar PID real del proceso Python
powershell -NoProfile -Command ^
  "$p = Start-Process -FilePath '%PYCMD%' -ArgumentList 'logger.py' -WorkingDirectory '%ROOT%' -WindowStyle Normal -PassThru; Set-Content -Path 'logger.pid' -Value $p.Id"

timeout /t 2 /nobreak >nul

echo - Lanzando Backend (Uvicorn)...
powershell -NoProfile -Command ^
  "$p = Start-Process -FilePath '%PYCMD%' -ArgumentList '-m','uvicorn','backend:app','--reload','--port','8000' -WorkingDirectory '%ROOT%' -WindowStyle Normal -PassThru; Set-Content -Path 'backend.pid' -Value $p.Id"

echo.
echo Listo. Backend en: http://127.0.0.1:8000
echo (Recuerda cerrar el Monitor Serial del IDE de Arduino para liberar COM4)
pause
goto :menu

:detener
echo.
echo === Deteniendo ===
cd /d "%ROOT%" || (echo [ERROR] No se pudo acceder a %ROOT% & pause & goto :menu)

REM PID del propio gestor (para no matarnos)
for /f "tokens=* usebackq" %%P in (`powershell -NoProfile -Command "$PID"`) do set "SELF_PID=%%P"

setlocal enabledelayedexpansion
set "KILLED_ANY="

REM --- Funcion auxiliar: KillSeguro <PID> <regex-CommandLine>
goto :KillSeguro_end
:KillSeguro
set "KP=%~1"
set "NEEDLE=%~2"
for /f "tokens=* usebackq" %%C in (`powershell -NoProfile -Command "(Get-CimInstance Win32_Process -Filter 'ProcessId=%~1' | Select-Object -ExpandProperty CommandLine) 2>$null"`) do set "CMDLINE=%%C"
if "%KP%"=="%SELF_PID%" (
  echo - Omitiendo PID %KP% (es el propio gestor).
  goto :eof
)
if not defined CMDLINE (
  echo - PID %KP% no existe (ya estaba cerrado).
  goto :eof
)
echo   PID %KP% => !CMDLINE!
echo   Verificando que haga match: %NEEDLE%
powershell -NoProfile -Command ^
  "$cl='%CMDLINE%'; if ($cl -match '%NEEDLE%') { exit 0 } else { exit 1 }"
if errorlevel 1 (
  echo   [Aviso] El PID %KP% no parece ser %NEEDLE%. Omitiendo.
  goto :eof
)
taskkill /PID %KP% /T /F >nul 2>&1 && (echo   OK: terminado && set "KILLED_ANY=1") || echo   [Aviso] No se pudo terminar PID %KP%.
goto :eof
:KillSeguro_end

REM --- Cerrar por PID verificando que sea el proceso correcto
if exist "logger.pid" (
  set /p LPID=<"logger.pid"
  for /f "tokens=1" %%P in ("!LPID!") do call :KillSeguro %%P "logger\.py"
  if defined KILLED_ANY del /q "logger.pid" >nul 2>&1
) else (
  echo - logger.pid no existe.
)

if exist "backend.pid" (
  set /p BPID=<"backend.pid"
  for /f "tokens=1" %%P in ("!BPID!") do call :KillSeguro %%P "uvicorn.*backend:app"
  if defined KILLED_ANY del /q "backend.pid" >nul 2>&1
) else (
  echo - backend.pid no existe.
)

REM --- Fallback SIEMPRE: cerrar cualquier python/py que ejecute logger.py o uvicorn backend:app
echo - Fallback: cerrando posibles rezagos por CommandLine...
powershell -NoProfile -Command ^
  "$self=$PID; Get-CimInstance Win32_Process | Where-Object { ($_.CommandLine -match 'logger\.py') -or ($_.CommandLine -match 'uvicorn.*backend:app') } | Where-Object { $_.ProcessId -ne $self } | ForEach-Object { try { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue } catch {} }"

echo.
echo Procesos detenidos (si estaban en ejecucion).
endlocal
pause
goto :menu

:estado
echo.
echo === Estado de procesos ===
cd /d "%ROOT%" || (echo [ERROR] No se pudo acceder a %ROOT% & pause & goto :menu)

call :status_one "Logger" "logger.pid"
call :status_one "Backend" "backend.pid"

echo.
pause
goto :menu

:status_one
REM %1=Nombre amigable, %2=archivo PID
set "NAME=%~1"
set "PIDFILE=%~2"

if not exist "%PIDFILE%" (
  echo - %NAME%: SIN PID (no iniciado o ya detenido)
  goto :eof
)
set /p PID=<"%PIDFILE%"
for /f "tokens=1" %%P in ("%PID%") do set "PID=%%P"

for /f "tokens=*" %%A in ('powershell -NoProfile -Command "try { (Get-Process -Id %PID%).Id } catch { '' }"') do set "FOUND=%%A"

if "%FOUND%"=="" (
  echo - %NAME%: PID %PID% NO ENCONTRADO (limpiando %PIDFILE%)
  del /q "%PIDFILE%" >nul 2>&1
) else (
  for /f "tokens=* usebackq" %%C in (`powershell -NoProfile -Command "(Get-CimInstance Win32_Process -Filter 'ProcessId=%PID%' | Select-Object -ExpandProperty CommandLine) 2>$null"`) do set "CMDL=%%C"
  echo - %NAME%: corriendo (PID %PID%)
  if defined CMDL echo   CMD: %CMDL%
)
goto :eof

:verlogs
echo.
echo === Ultimas 20 lecturas (lecturas.txt) ===
cd /d "%ROOT%" || (echo [ERROR] No se pudo acceder a %ROOT% & pause & goto :menu)
powershell -NoProfile -Command ^
  "if (Test-Path 'lecturas.txt') { Get-Content 'lecturas.txt' -Tail 20 } else { 'lecturas.txt no existe.' }"
echo.
pause
goto :menu

:fin
endlocal
exit /b 0
