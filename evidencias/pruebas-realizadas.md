\# Evidencias de pruebas - IaC



\## T1 - Ayuda



Comando:



.\\crear-vm.cmd --help



Resultado:



La ayuda del script se mostró correctamente con los parámetros disponibles.



---



\## T2 - Dry Run



Comando:



.\\crear-vm.cmd --name prueba --dry-run



Resultado:



DRY-RUN finalizado correctamente.



No se creó ni modificó ninguna máquina virtual.



---



\## T3 - Nombre inválido



Comando:



.\\crear-vm.cmd --name "mi vm"



Resultado:



ERROR: Nombre de VM invalido: mi vm



El script rechazó correctamente el nombre con espacios.



---



\## T4 - CPU inválida



Comando:



.\\crear-vm.cmd --name VM\_Error --cpus abc --mem 2048 --disk 10 --net nat



Resultado:



ERROR: --cpus debe ser un entero positivo.



---



\## T4 - Memoria inválida



Comando:



.\\crear-vm.cmd --name VM\_Error2 --cpus 2 --mem abc --disk 10 --net nat



Resultado:



ERROR: --mem debe ser un entero positivo.



---



\## T4 - Disco inválido



Comando:



.\\crear-vm.cmd --name VM\_Error3 --cpus 2 --mem 2048 --disk abc --net nat



Resultado:



ERROR: --disk debe ser un entero positivo.



---



\## T5 - Red inválida



Comando:



.\\crear-vm.cmd --name VM\_Error4 --cpus 2 --mem 2048 --disk 10 --net wifi



Resultado:



ERROR: Modo de red invalido: wifi



Valores permitidos: nat, bridged, hostonly



---



\## T6 - ISO inexistente



Comando:



.\\crear-vm.cmd --name VM\_ISO --iso "C:\\NO\_EXISTE\\ubuntu.iso"



Resultado:



ERROR: La ISO indicada no existe.



---



\## T8 - Idempotencia



Comando:



.\\crear-vm.cmd --name VM\_Prueba --dir "$PWD\\VMs" --cpus 2 --mem 2048 --disk 10 --net nat



Resultado:



ERROR: La VM "VM\_Prueba" ya existe.



Use --force si desea recrearla.



El script evita sobrescribir una VM existente.



---



\## T9 - Force



Comando:



.\\crear-vm.cmd --name VM\_Prueba --dir "$PWD\\VMs" --cpus 2 --mem 2048 --disk 10 --net nat --force



Resultado:



La VM existente fue eliminada y posteriormente recreada correctamente.



---



\## T11 - Parámetros personalizados



Comando:



.\\crear-vm.cmd --name VM\_Personalizada --dir "$PWD\\VMs" --cpus 3 --mem 3072 --disk 12 --net nat



Resultado:



VM creada correctamente.



Configuración verificada mediante VBoxManage:



Nombre: VM\_Personalizada

Memoria: 3072 MB

CPU: 3

Red: NAT



---



\## Pruebas pendientes



T7 y T10 requieren VMware Workstation y una ISO de instalación.



VMware Workstation no se encontraba instalado en el equipo utilizado para las pruebas.



Las pruebas realizadas con VirtualBox se documentan como pruebas de funcionamiento del script, pero no se presentan como pruebas ejecutadas sobre VMware Workstation.

## 7. Verificación de ejecución

Se intentó iniciar la máquina virtual VM_Start mediante VMware Workstation y mediante vmrun.

Comando utilizado:

vmrun -T ws start "VM_Start.vmx" nogui

Resultado observado:
La máquina virtual no quedó ejecutándose. La creación y configuración de la VM se completaron correctamente, pero la ejecución mediante vmrun no pudo ser verificada.

Comando de verificación:

vmrun -T ws list

Resultado:

Total running VMs: 0
