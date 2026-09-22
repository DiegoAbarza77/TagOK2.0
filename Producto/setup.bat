@echo off
setlocal

echo =======================================================
echo    Configuracion y Ejecucion del Proyecto TAG OK
echo =======================================================
echo.

rem Ir al directorio donde se encuentra este script
cd /d "%~dp0"

echo [1/3] Verificando archivos .env (requeridos, ya no se generan automaticamente)...
echo.
if not exist "tag_ok\.env" (
    (
        echo # Completa estos valores antes de ejecutar la app -- sin ellos no arranca.
        echo # SUPABASE_URL y SUPABASE_ANON_KEY: Supabase Dashboard -^> Project Settings -^> API
        echo SUPABASE_URL=
        echo SUPABASE_ANON_KEY=
        echo MAPBOX_ACCESS_TOKEN=
    ) > "tag_ok\.env"
    echo - Creado tag_ok\.env con plantilla vacia -- debes completarlo a mano
)
if not exist "admin\.env" (
    (
        echo # Completa estos valores antes de ejecutar la app -- sin ellos no arranca.
        echo # SUPABASE_URL y SUPABASE_ANON_KEY: Supabase Dashboard -^> Project Settings -^> API
        echo SUPABASE_URL=
        echo SUPABASE_ANON_KEY=
    ) > "admin\.env"
    echo - Creado admin\.env con plantilla vacia -- debes completarlo a mano
)
echo.

echo [2/3] Instalar/Actualizar dependencias del proyecto...
echo.
echo Instalando dependencias de la app principal (tag_ok)...
cd /d "%~dp0tag_ok"
call flutter pub get

echo.
echo Instalando dependencias del panel de administrador (admin)...
cd /d "%~dp0admin"
call flutter pub get

echo.
echo =======================================================
echo    Instalacion y configuracion completadas con exito
echo =======================================================
echo IMPORTANTE: este proyecto usa Supabase (ya no Firebase).
echo Antes de ejecutar la app, completa tag_ok\.env y admin\.env
echo con tu SUPABASE_URL y SUPABASE_ANON_KEY (y MAPBOX_ACCESS_TOKEN
echo en tag_ok\.env). Sin esos valores la app no va a arrancar.
echo.

:menu
cd /d "%~dp0"
echo Selecciona la aplicacion que deseas ejecutar:
echo 1) App Principal (tag_ok) - Ejecutar en Windows Desktop
echo 2) App Principal (tag_ok) - Ejecutar en Chrome (Web)
echo 3) Panel Administrador (admin) - Ejecutar en Windows Desktop
echo 4) Panel Administrador (admin) - Ejecutar en Chrome (Web)
echo 5) Salir
echo.
set "opcion="
set /p opcion="Introduce el numero de tu opcion (1-5): "

if "%opcion%"=="1" goto opt1
if "%opcion%"=="2" goto opt2
if "%opcion%"=="3" goto opt3
if "%opcion%"=="4" goto opt4
if "%opcion%"=="5" goto opt5

echo Opcion no valida, por favor intenta de nuevo.
echo.
goto menu

:opt1
findstr /R "^SUPABASE_URL=." "%~dp0tag_ok\.env" >nul 2>&1
if errorlevel 1 (
    echo.
    echo ERROR: tag_ok\.env no tiene SUPABASE_URL configurado.
    echo Completa tag_ok\.env con tus credenciales de Supabase antes de continuar.
    echo.
    goto menu
)
echo Ejecutando App Principal (tag_ok) en Windows...
cd /d "%~dp0tag_ok"
call flutter run -d windows
goto menu

:opt2
findstr /R "^SUPABASE_URL=." "%~dp0tag_ok\.env" >nul 2>&1
if errorlevel 1 (
    echo.
    echo ERROR: tag_ok\.env no tiene SUPABASE_URL configurado.
    echo Completa tag_ok\.env con tus credenciales de Supabase antes de continuar.
    echo.
    goto menu
)
echo Ejecutando App Principal (tag_ok) en Chrome...
cd /d "%~dp0tag_ok"
call flutter run -d chrome
goto menu

:opt3
findstr /R "^SUPABASE_URL=." "%~dp0admin\.env" >nul 2>&1
if errorlevel 1 (
    echo.
    echo ERROR: admin\.env no tiene SUPABASE_URL configurado.
    echo Completa admin\.env con tus credenciales de Supabase antes de continuar.
    echo.
    goto menu
)
echo Ejecutando Panel Administrador (admin) en Windows...
cd /d "%~dp0admin"
call flutter run -d windows
goto menu

:opt4
findstr /R "^SUPABASE_URL=." "%~dp0admin\.env" >nul 2>&1
if errorlevel 1 (
    echo.
    echo ERROR: admin\.env no tiene SUPABASE_URL configurado.
    echo Completa admin\.env con tus credenciales de Supabase antes de continuar.
    echo.
    goto menu
)
echo Ejecutando Panel Administrador (admin) en Chrome...
cd /d "%~dp0admin"
call flutter run -d chrome
goto menu

:opt5
echo Saliendo del script. Adios.
pause
exit /b 0