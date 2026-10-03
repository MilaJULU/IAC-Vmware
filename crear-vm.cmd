@echo off
setlocal EnableExtensions EnableDelayedExpansion

REM ============================================================
REM crear-vm.cmd
REM Infraestructura como Codigo (IaC) con VirtualBox
REM Adaptacion del taller IAC-Vmware
REM ============================================================

set "VBOXMANAGE=C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"

set "NAME=VM_Taller"
set "BASE_DIR=%USERPROFILE%\Documents\Virtual Machines"
set "ISO="
set "CPUS=2"
set "MEM=2048"
set "DISK=20"
set "NET=nat"
set "START=0"
set "DRYRUN=0"
set "FORCE=0"

REM ============================================================
REM AYUDA
REM ============================================================

if "%~1"=="" goto :main

if /I "%~1"=="-h" goto :help
if /I "%~1"=="--help" goto :help

REM ============================================================
REM LECTURA DE PARAMETROS
REM ============================================================

:parse

if "%~1"=="" goto :main

if /I "%~1"=="--name" (
    if "%~2"=="" goto :invalid
    set "NAME=%~2"
    shift
    shift
    goto :parse
)

if /I "%~1"=="--dir" (
    if "%~2"=="" goto :invalid
    set "BASE_DIR=%~2"
    shift
    shift
    goto :parse
)

if /I "%~1"=="--iso" (
    if "%~2"=="" goto :invalid
    set "ISO=%~2"
    shift
    shift
    goto :parse
)

if /I "%~1"=="--cpus" (
    if "%~2"=="" goto :invalid
    set "CPUS=%~2"
    shift
    shift
    goto :parse
)

if /I "%~1"=="--mem" (
    if "%~2"=="" goto :invalid
    set "MEM=%~2"
    shift
    shift
    goto :parse
)

if /I "%~1"=="--disk" (
    if "%~2"=="" goto :invalid
    set "DISK=%~2"
    shift
    shift
    goto :parse
)

if /I "%~1"=="--net" (
    if "%~2"=="" goto :invalid
    set "NET=%~2"
    shift
    shift
    goto :parse
)

if /I "%~1"=="--start" (
    set "START=1"
    shift
    goto :parse
)

if /I "%~1"=="--dry-run" (
    set "DRYRUN=1"
    shift
    goto :parse
)

if /I "%~1"=="--force" (
    set "FORCE=1"
    shift
    goto :parse
)

echo ERROR: Parametro desconocido: %~1
exit /b 2


REM ============================================================
REM VALIDACIONES
REM ============================================================

:main

echo.
echo ==============================================
echo       IaC - CREACION DE VM CON VIRTUALBOX
echo ==============================================
echo.

if not exist "%VBOXMANAGE%" (
    echo ERROR: No se encontro VBoxManage.exe
    echo Ruta esperada:
    echo %VBOXMANAGE%
    exit /b 1
)

REM Validar nombre
echo(%NAME%| findstr /r /x /c:"[A-Za-z0-9._-][A-Za-z0-9._-]*" >nul
if errorlevel 1 (
    echo ERROR: Nombre de VM invalido: %NAME%
    echo Use solamente letras, numeros, punto, guion y guion bajo.
    exit /b 2
)

REM Validar CPU
echo(%CPUS%| findstr /r /x /c:"[0-9][0-9]*" >nul
if errorlevel 1 goto :invalid_cpus

if "%CPUS%"=="0" goto :invalid_cpus

REM Validar memoria
echo(%MEM%| findstr /r /x /c:"[0-9][0-9]*" >nul
if errorlevel 1 goto :invalid_mem

if "%MEM%"=="0" goto :invalid_mem

REM Validar disco
echo(%DISK%| findstr /r /x /c:"[0-9][0-9]*" >nul
if errorlevel 1 goto :invalid_disk

if "%DISK%"=="0" goto :invalid_disk

REM Validar red
if /I not "%NET%"=="nat" if /I not "%NET%"=="bridged" if /I not "%NET%"=="hostonly" (
    echo ERROR: Modo de red invalido: %NET%
    echo Valores permitidos: nat, bridged, hostonly
    exit /b 2
)

REM Validar ISO
if not "%ISO%"=="" (
    if not exist "%ISO%" (
        echo ERROR: La ISO indicada no existe:
        echo %ISO%
        exit /b 2
    )
)

set "VM_DIR=%BASE_DIR%\%NAME%"
set "DISK_PATH=%VM_DIR%\%NAME%.vdi"

echo Configuracion:
echo   Nombre : %NAME%
echo   Carpeta: %VM_DIR%
echo   CPU    : %CPUS%
echo   RAM    : %MEM% MB
echo   Disco  : %DISK% GB
echo   Red    : %NET%

if not "%ISO%"=="" echo   ISO    : %ISO%

if "%START%"=="1" echo   Inicio : SI
if "%START%"=="0" echo   Inicio : NO

echo.

REM ============================================================
REM DRY RUN
REM ============================================================

if "%DRYRUN%"=="1" (
    echo [DRY-RUN] No se creara ni modificara ninguna VM.
    echo.
    echo Pasos que se ejecutarian:
    echo 1. Crear carpeta de la VM.
    echo 2. Crear disco virtual de %DISK% GB.
    echo 3. Crear VM Ubuntu 64 bits.
    echo 4. Configurar %CPUS% CPU y %MEM% MB RAM.
    echo 5. Configurar red %NET%.
    if not "%ISO%"=="" echo 6. Conectar ISO.
    if "%START%"=="1" echo 7. Encender VM.
    echo.
    echo DRY-RUN finalizado correctamente.
    exit /b 0
)

REM ============================================================
REM COMPROBAR SI LA VM YA EXISTE
REM ============================================================

"%VBOXMANAGE%" showvminfo "%NAME%" >nul 2>&1

if not errorlevel 1 (

    if "%FORCE%"=="0" (
        echo ERROR: La VM "%NAME%" ya existe.
        echo Use --force si desea recrearla.
        exit /b 1
    )

    echo La VM ya existe. Se eliminara por --force.

    "%VBOXMANAGE%" showvminfo "%NAME%" --machinereadable 2>nul | findstr /I "VMState=" | findstr /I "running" >nul

    if not errorlevel 1 (
        echo ERROR: La VM esta encendida.
        echo No se puede recrear una VM encendida.
        exit /b 1
    )

    echo Eliminando VM existente...

    "%VBOXMANAGE%" unregistervm "%NAME%" --delete

    if errorlevel 1 (
        echo ERROR: No se pudo eliminar la VM existente.
        exit /b 1
    )
)

REM ============================================================
REM CREAR CARPETA
REM ============================================================

echo [1/6] Creando carpeta...

if not exist "%VM_DIR%" mkdir "%VM_DIR%"

if errorlevel 1 (
    echo ERROR: No se pudo crear la carpeta.
    exit /b 1
)

REM ============================================================
REM CONVERTIR GB A MB
REM ============================================================

set /A DISK_MB=DISK*1024

REM ============================================================
REM CREAR DISCO
REM ============================================================

echo [2/6] Creando disco virtual de %DISK% GB...

"%VBOXMANAGE%" createmedium disk --filename "%DISK_PATH%" --size %DISK_MB% --format VDI

if errorlevel 1 (
    echo ERROR: No se pudo crear el disco.
    exit /b 1
)

REM ============================================================
REM CREAR VM
REM ============================================================

echo [3/6] Creando maquina virtual...

"%VBOXMANAGE%" createvm --name "%NAME%" --ostype Ubuntu_64 --basefolder "%BASE_DIR%" --register

if errorlevel 1 (
    echo ERROR: No se pudo crear la VM.
    exit /b 1
)

REM ============================================================
REM CONFIGURAR VM
REM ============================================================

echo [4/6] Configurando CPU y memoria...

"%VBOXMANAGE%" modifyvm "%NAME%" --cpus %CPUS% --memory %MEM% --ioapic on

if errorlevel 1 (
    echo ERROR: No se pudo configurar CPU/RAM.
    exit /b 1
)

REM ============================================================
REM CONTROLADOR SATA Y DISCO
REM ============================================================

echo [5/6] Configurando almacenamiento...

"%VBOXMANAGE%" storagectl "%NAME%" --name "SATA Controller" --add sata --controller IntelAhci

if errorlevel 1 (
    echo ERROR: No se pudo crear el controlador SATA.
    exit /b 1
)

"%VBOXMANAGE%" storageattach "%NAME%" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "%DISK_PATH%"

if errorlevel 1 (
    echo ERROR: No se pudo conectar el disco.
    exit /b 1
)

REM ============================================================
REM ISO
REM ============================================================

if not "%ISO%"=="" (
    echo Conectando ISO...

    "%VBOXMANAGE%" storagectl "%NAME%" --name "IDE Controller" --add ide

    "%VBOXMANAGE%" storageattach "%NAME%" --storagectl "IDE Controller" --port 0 --device 0 --type dvddrive --medium "%ISO%"

    if errorlevel 1 (
        echo ERROR: No se pudo conectar la ISO.
        exit /b 1
    )
)

REM ============================================================
REM RED
REM ============================================================

echo [6/6] Configurando red...

if /I "%NET%"=="nat" (
    "%VBOXMANAGE%" modifyvm "%NAME%" --nic1 nat

    if errorlevel 1 (
        echo ERROR: No se pudo configurar la red NAT.
        exit /b 1
    )
)

if /I "%NET%"=="bridged" (
    for /f "tokens=2 delims=:" %%A in ('"%VBOXMANAGE%" list bridgedifs ^| findstr /B /C:"Name:"') do (
        if not defined BRIDGE_IF set "BRIDGE_IF=%%A"
    )

    if not defined BRIDGE_IF (
        echo ERROR: No se encontro un adaptador puente.
        exit /b 1
    )

    set "BRIDGE_IF=!BRIDGE_IF:~1!"

    echo Adaptador puente: !BRIDGE_IF!

    "%VBOXMANAGE%" modifyvm "%NAME%" --nic1 bridged --bridgeadapter1 "!BRIDGE_IF!"

    if errorlevel 1 (
        echo ERROR: No se pudo configurar la red puente.
        exit /b 1
    )
)

if /I "%NET%"=="hostonly" (
    for /f "tokens=2 delims=:" %%A in ('"%VBOXMANAGE%" list hostonlyifs ^| findstr /B /C:"Name:"') do (
        if not defined HOSTONLY_IF set "HOSTONLY_IF=%%A"
    )

    if not defined HOSTONLY_IF (
        echo ERROR: No se encontro un adaptador host-only.
        exit /b 1
    )

    set "HOSTONLY_IF=!HOSTONLY_IF:~1!"

    echo Adaptador host-only: !HOSTONLY_IF!

    "%VBOXMANAGE%" modifyvm "%NAME%" --nic1 hostonly --hostonlyadapter1 "!HOSTONLY_IF!"

    if errorlevel 1 (
        echo ERROR: No se pudo configurar la red host-only.
        exit /b 1
    )
)

REM ============================================================
REM VALIDACION FINAL
REM ============================================================

echo.
echo ==============================================
echo VM CREADA CORRECTAMENTE
echo ==============================================
echo Nombre : %NAME%
echo Carpeta: %VM_DIR%
echo Disco  : %DISK_PATH%
echo.

"%VBOXMANAGE%" showvminfo "%NAME%" --machinereadable | findstr /I "name=ostype=memory cpus="

if "%START%"=="1" (
    echo.
    echo Encendiendo VM...

    "%VBOXMANAGE%" startvm "%NAME%" --type gui

    if errorlevel 1 (
        echo ERROR: No se pudo iniciar la VM.
        exit /b 1
    )

    echo VM iniciada correctamente.
)

exit /b 0


REM ============================================================
REM ERRORES
REM ============================================================

:invalid_cpus
echo ERROR: --cpus debe ser un entero positivo.
exit /b 2

:invalid_mem
echo ERROR: --mem debe ser un entero positivo.
exit /b 2

:invalid_disk
echo ERROR: --disk debe ser un entero positivo.
exit /b 2

:invalid
echo ERROR: Falta un valor para el parametro.
exit /b 2


REM ============================================================
REM AYUDA
REM ============================================================

:help

echo.
echo ============================================================
echo       CREAR VM - INFRAESTRUCTURA COMO CODIGO
echo ============================================================
echo.
echo Uso:
echo   crear-vm.cmd [parametros]
echo.
echo Parametros:
echo   --name NOMBRE       Nombre de la VM.
echo   --dir RUTA          Carpeta base de las VM.
echo   --iso RUTA          ISO de instalacion.
echo   --cpus N            Numero de CPU virtuales.
echo   --mem MB            Memoria RAM en MB.
echo   --disk GB           Tamano del disco en GB.
echo   --net MODO          nat, bridged o hostonly.
echo   --start             Inicia la VM al finalizar.
echo   --dry-run           Simula la ejecucion sin crear nada.
echo   --force             Permite recrear una VM existente.
echo   -h, --help          Muestra esta ayuda.
echo.
echo Valores por defecto:
echo   name = VM_Taller
echo   dir  = %%USERPROFILE%%\Documents\Virtual Machines
echo   cpus = 2
echo   mem  = 2048 MB
echo   disk = 20 GB
echo   net  = nat
echo.
echo Ejemplo:
echo   crear-vm.cmd --name MiVM --cpus 2 --mem 2048 --disk 20 --net nat
echo.
exit /b 0