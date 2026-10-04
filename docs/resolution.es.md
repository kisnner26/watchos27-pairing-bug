# Resolución: actualizar el iPhone a iOS 27.2

**Estado: resuelto en mi equipo (2026-10-03). La causa raíz no está probada.** El reporte a Apple (FB24924229) sigue abierto.

## Qué lo arregló

1. Actualizar el **iPhone** a **iOS 27.2** para que coincida con el reloj (watchOS 27.2).
2. Con el iPhone conectado a la Mac, emparejar el reloj desde **Device Hub** (*File ▸ Pair Nearby Device…*).

Después el reloj volvió a estar disponible y `devicectl` pudo instalarle apps.

## Qué *no* lo arregló

Todo lo de [`what-i-tried.md`](what-i-tried.md), y dos cosas que conviene destacar:

* **Actualizar solo el reloj** (watchOS 27.0 → 27.2). El iPhone siguió en iOS 27.0, así que el reloj quedó *más nuevo* que su compañero.
* **Desvincular y volver a vincular el reloj en la app Watch** con el iPhone todavía en iOS 27.0. El enlace iPhone ↔ reloj estaba sano,
  pero Device Hub seguía sin poder llegar al reloj.

Síntoma que mostraba Device Hub mientras fallaba:

```
DeviceKitError, errorCode 4002
"Live device view took longer than expected to connect."
```

## Evidencia en los logs de analítica del iPhone

El iPhone guarda archivos de diagnóstico `.ips` durante semanas (*Ajustes ▸ Privacidad y seguridad ▸ Analítica y mejoras ▸ Datos de analítica*).
Se pueden copiar a la Mac sin herramientas extra:

```sh
xcrun devicectl device info files --device <iphone> --domain-type systemCrashLogs
xcrun devicectl device copy from  --device <iphone> --domain-type systemCrashLogs --source <archivo> --destination <ruta>
```

La cabecera de cada `JetsamEvent-*.ips` lleva la compilación del sistema en ese momento, así que reconstruyen el historial de versiones (hora local, UTC−6):

| Cuándo | Qué muestran los logs | Archivo |
|---|---|---|
| hasta el 2026-10-02 17:19 | iPhone en **iOS 27.0 (24A5418b)** | `JetsamEvent-*` |
| 2026-10-02 22:06 → 22:41 | cambia la identidad de emparejado del reloj en el iPhone (una carpeta `ProxiedDevice-*` termina y empieza otra): el reloj se desvinculó y se vinculó de nuevo | `ProxiedDevice-*/` |
| 2026-10-02 23:45 – 23:54 | emparejado limpio iPhone ↔ reloj: activación ~11 s, código y desbloqueo hechos, sincronización inicial, sin errores | `DiagnosticLogs/Bridge-Pair-Performance-Report-*` |
| 2026-10-03 00:26 | **el iPhone se actualiza a iOS 27.2 (24B5089g)**, resultado OTA `success` | `ota_patch.txt` |
| desde 2026-10-03 10:27 | iPhone en iOS 27.2; la misma identidad del reloj continúa hasta el final de los logs, sin más re-emparejados | `JetsamEvent-*` |

El reloj estuvo en **watchOS 27.2 (24S5091f)** con las dos identidades de emparejado.

Estado del reloj después (`devicectl device info details`): `pairingState: paired`, `transportType: localNetwork`,
`authenticationType: manualPairing`, `developerModeStatus: enabled`.

## Qué muestra y qué no

* Muestra que durante toda la falla el reloj (27.2) era **más nuevo que el iPhone (27.0)**, que el emparejado iPhone ↔ reloj estaba sano,
  y que la mejora coincide con subir el iPhone a 27.2, sin más re-emparejados del reloj después.
* **No** muestra el lado de CoreDevice. Los mensajes de `remotepairingd` y `verifyManualPairing` no se guardan en estos archivos y el log unificado de la Mac
  caduca en horas, así que el motivo por el que el reloj pedía un emparejamiento nuevo en bucle ([ver el bucle](README.es.md#el-bucle-de-emparejamiento)) sigue sin probarse.
  Un desajuste de versiones entre el iPhone y el reloj es la hipótesis de trabajo, no un diagnóstico.

## Si te pasa

Comprueba antes que nada que el **iPhone y el reloj tengan versiones a juego** (iOS 27.2 con watchOS 27.2). Si sigue fallando, captura el log
**antes** de emparejar para no perder la evidencia:

```sh
log stream --predicate 'process == "remotepairingd" OR process == "CoreDeviceService"' --style compact > pairing.log
```

y adjúntalo a tu reporte de Feedback mencionando **FB24924229**.
