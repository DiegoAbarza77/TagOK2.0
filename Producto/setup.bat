@echo off
setlocal

echo =======================================================
echo    Configuracion y Ejecucion del Proyecto TAG OK
echo =======================================================
echo.

rem Ir al directorio donde se encuentra este script
cd /d "%~dp0"

echo [1/3] Creando archivos .env vacios (requerido por Flutter)...
echo.
if not exist "tag_ok\.env" (
    echo. > "tag_ok\.env"
    echo - Creado tag_ok\.env vacio
)
if not exist "admin\.env" (
    echo. > "admin\.env"
    echo - Creado admin\.env vacio
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
echo (Nota: Las claves de Firebase y Gemini se cargan en 
echo  memoria automaticamente. No necesitas archivos .env)
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
echo Ejecutando App Principal (tag_ok) en Windows...
cd /d "%~dp0tag_ok"
call flutter run -d windows
goto menu

:opt2
echo Ejecutando App Principal (tag_ok) en Chrome...
cd /d "%~dp0tag_ok"
call flutter run -d chrome
goto menu

:opt3
echo Ejecutando Panel Administrador (admin) en Windows...
cd /d "%~dp0admin"
call flutter run -d windows
goto menu

:opt4
echo Ejecutando Panel Administrador (admin) en Chrome...
cd /d "%~dp0admin"
call flutter run -d chrome
goto menu

:opt5
echo Saliendo del script. Adios.
pause
exit /b 0