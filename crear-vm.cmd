@echo off
setlocal EnableExtensions EnableDelayedExpansion

title IaC - VMware Workstation

REM ============================================================
REM CREAR-VM.CMD - INFRAESTRUCTURA COMO CODIGO
REM VMware Workstation
REM ============================================================

set "VMWARE_DIR=%ProgramFiles%\VMware\VMware Workstation"
set "VDISK=%VMWARE_DIR%\vmware-vdiskmanager.exe"
set "VMRUN=%VMWARE_DIR%\vmrun.exe"

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

if "%~1"=="" goto :show_config
if /I "%~1"=="-h" goto :help
if /I "%~1"=="--help" goto :help

REM ============================================================
REM PARAMETROS
REM ============================================================

:parse
if "%~1"=="" goto :validate

if /I "%~1"=="--name" (
    if "%~2"=="" goto :badparams
    set "NAME=%~2"
    shift
    shift
    goto :parse
)

if /I "%~1"=="--dir" (
    if "%~2"=="" goto :badparams
    set "BASE_DIR=%~2"
    shift
    shift
    goto :parse
)

if /I "%~1"=="--iso" (
    if "%~2"=="" goto :badparams
    set "ISO=%~2"
    shift
    shift
    goto :parse
)

if /I "%~1"=="--cpus" (
    if "%~2"=="" goto :badparams
    set "CPUS=%~2"
    shift
    shift
    goto :parse
)

if /I "%~1"=="--mem" (
    if "%~2"=="" goto :badparams
    set "MEM=%~2"
    shift
    shift
    goto :parse
)

if /I "%~1"=="--disk" (
    if "%~2"=="" goto :badparams
    set "DISK=%~2"
    shift
    shift
    goto :parse
)

if /I "%~1"=="--net" (
    if "%~2"=="" goto :badparams
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

:validate

if not exist "%VDISK%" (
    echo ERROR: No se encontro VMware Workstation.
    echo Ruta esperada: %VDISK%
    exit /b 1
)

if not exist "%VMRUN%" (
    echo ERROR: No se encontro vmrun.exe.
    exit /b 1
)

echo(%NAME%| findstr /R /X "[A-Za-z0-9._-][A-Za-z0-9._-]*" >nul
if errorlevel 1 (
    echo ERROR: Nombre de VM invalido: %NAME%
    echo Use solamente letras, numeros, punto, guion y guion bajo.
    exit /b 2
)

echo %CPUS%| findstr /R /X "[1-9][0-9]*" >nul
if errorlevel 1 (
    echo ERROR: --cpus debe ser un entero positivo.
    exit /b 2
)

echo %MEM%| findstr /R /X "[1-9][0-9]*" >nul
if errorlevel 1 (
    echo ERROR: --mem debe ser un entero positivo.
    exit /b 2
)

echo %DISK%| findstr /R /X "[1-9][0-9]*" >nul
if errorlevel 1 (
    echo ERROR: --disk debe ser un entero positivo.
    exit /b 2
)

if /I not "%NET%"=="nat" if /I not "%NET%"=="bridged" if /I not "%NET%"=="hostonly" (
    echo ERROR: Modo de red invalido: %NET%
    echo Valores permitidos: nat, bridged, hostonly
    exit /b 2
)

if not "%ISO%"=="" (
    if not exist "%ISO%" (
        echo ERROR: La ISO indicada no existe:
        echo %ISO%
        exit /b 2
    )
)

set "VM_DIR=%BASE_DIR%\%NAME%"
set "VMX=%VM_DIR%\%NAME%.vmx"
set "VMDK=%VM_DIR%\%NAME%.vmdk"

echo.
echo ============================================================
echo      IaC - CREACION DE VM CON VMWARE WORKSTATION
echo ============================================================
echo.
echo Configuracion:
echo   Nombre : %NAME%
echo   Carpeta: %VM_DIR%
echo   CPU    : %CPUS%
echo   RAM    : %MEM% MB
echo   Disco  : %DISK% GB
echo   Red    : %NET%
echo   Inicio : %START%
echo.

REM ============================================================
REM EXISTENCIA / IDEMPOTENCIA
REM ============================================================

if exist "%VMX%" (
    if "%FORCE%"=="0" (
        echo ERROR: La VM "%NAME%" ya existe.
        echo Use --force si desea recrearla.
        exit /b 1
    )

    echo La VM ya existe. Se eliminara por --force.

    "%VMRUN%" -T ws list | findstr /I /C:"%VMX%" >nul
    if not errorlevel 1 (
        echo ERROR: La VM esta encendida.
        echo No se puede usar --force sobre una VM encendida.
        exit /b 1
    )

    if "%DRYRUN%"=="0" (
        echo Eliminando VM existente...
        rmdir /S /Q "%VM_DIR%"
    )
)

REM ============================================================
REM DRY RUN
REM ============================================================

if "%DRYRUN%"=="1" (
    echo [DRY-RUN] No se creara ni modificara ninguna VM.
    echo.
    echo Pasos que se ejecutarian:
    echo 1. Crear carpeta de la VM.
    echo 2. Crear disco virtual VMDK de %DISK% GB.
    echo 3. Generar archivo VMX.
    echo 4. Configurar %CPUS% CPU y %MEM% MB RAM.
    echo 5. Configurar red %NET%.
    if not "%ISO%"=="" echo 6. Conectar ISO de instalacion.
    if "%START%"=="1" echo 7. Encender la VM.
    echo.
    echo DRY-RUN finalizado correctamente.
    exit /b 0
)

REM ============================================================
REM CREACION
REM ============================================================

echo [1/6] Creando carpeta...
if not exist "%VM_DIR%" mkdir "%VM_DIR%"
if errorlevel 1 (
    echo ERROR: No se pudo crear la carpeta.
    exit /b 1
)

echo [2/6] Creando disco virtual de %DISK% GB...
"%VDISK%" -c -s %DISK%GB -a lsilogic -t 0 "%VMDK%"
if errorlevel 1 (
    echo ERROR: No se pudo crear el disco VMDK.
    exit /b 1
)

echo [3/6] Generando archivo de configuracion VMX...

(
echo .encoding = "UTF-8"
echo config.version = "8"
echo virtualHW.version = "20"
echo displayName = "%NAME%"
echo guestOS = "ubuntu-64"
echo memsize = "%MEM%"
echo numvcpus = "%CPUS%"
echo firmware = "bios"
echo.
echo scsi0.present = "TRUE"
echo scsi0.virtualDev = "lsilogic"
echo scsi0:0.present = "TRUE"
echo scsi0:0.fileName = "%NAME%.vmdk"
echo scsi0:0.deviceType = "disk"
echo.
echo ethernet0.present = "TRUE"
echo ethernet0.connectionType = "%NET%"
echo ethernet0.virtualDev = "e1000e"
echo ethernet0.wakeOnPcktRcv = "FALSE"
echo.
echo usb.present = "TRUE"
echo sound.present = "FALSE"
echo.
) > "%VMX%"

if not "%ISO%"=="" (
    >>"%VMX%" echo ide1:0.present = "TRUE"
    >>"%VMX%" echo ide1:0.deviceType = "cdrom-image"
    >>"%VMX%" echo ide1:0.fileName = "%ISO%"
    >>"%VMX%" echo ide1:0.startConnected = "TRUE"
) else (
    >>"%VMX%" echo ide1:0.present = "TRUE"
    >>"%VMX%" echo ide1:0.deviceType = "cdrom-raw"
    >>"%VMX%" echo ide1:0.startConnected = "FALSE"
)

echo [4/6] Configuracion de CPU y memoria...
echo [5/6] Configuracion de almacenamiento...
echo [6/6] Configuracion de red...

if not exist "%VMX%" (
    echo ERROR: No se genero el archivo VMX.
    exit /b 1
)

if not exist "%VMDK%" (
    echo ERROR: No se genero el disco VMDK.
    exit /b 1
)

echo.
echo ============================================================
echo VM CREADA CORRECTAMENTE
echo ============================================================
echo Nombre : %NAME%
echo Carpeta: %VM_DIR%
echo VMX    : %VMX%
echo Disco  : %VMDK%
echo.

REM ============================================================
REM START
REM ============================================================

if "%START%"=="1" (
    echo Encendiendo VM...
    "%VMRUN%" -T ws start "%VMX%" nogui

    if errorlevel 1 (
        echo ERROR: No se pudo encender la VM.
        exit /b 1
    )

    echo VM encendida correctamente.

    "%VMRUN%" -T ws list | findstr /I /C:"%VMX%" >nul
    if errorlevel 1 (
        echo ERROR: No se pudo comprobar que la VM este ejecutandose.
        exit /b 1
    )

    echo Validacion: VM en ejecucion.
)

exit /b 0

REM ============================================================
REM AYUDA
REM ============================================================

:help
echo.
echo ============================================================
echo      CREAR VM - INFRAESTRUCTURA COMO CODIGO
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
echo   --dry-run           Simula sin crear archivos.
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
exit /b 0

:badparams
echo ERROR: Falta un valor para el parametro.
exit /b 2

:show_config
goto :help