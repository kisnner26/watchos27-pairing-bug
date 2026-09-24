# El Apple Watch corta la conexión justo después de emparejarse bien (watchOS 27 + Xcode 27 / Device Hub)

🇬🇧 [Read in English](README.md)

> **Estado: abierto · en investigación.** Última actualización: 2026-09-24.
> Falta repetir la prueba en **watchOS 27.2 beta 2**. Los resultados irán en [`docs/status-log.md`](docs/status-log.md).

Un Apple Watch Ultra 2 que funcionaba como destino de ejecución en Xcode **desapareció de la Mac**
(`devicectl` primero lo mostró como `unavailable` y luego dejó de listarlo). Al re-emparejarlo desde
**Device Hub** (*File ▸ Pair Nearby Device…*) el emparejamiento **sale bien**, pero **~40 ms después el reloj
cierra la conexión TCP**, así que CoreDevice nunca crea el registro del dispositivo y el reloj no vuelve a estar disponible.

Este repositorio documenta los síntomas, la evidencia en los registros, todo lo que se probó y un
reporte listo para Feedback Assistant. Los datos personales (UDID, nombres, direcciones de red) están ocultos.

## Entorno

| | |
|---|---|
| Mac | MacBook Pro (`MacBookPro17,1`, Apple M1), macOS 27.2 (`26B5086k`) |
| Xcode | 27.0 (`27A5237l`) — los dispositivos ahora se manejan en la app aparte **Device Hub** |
| iPhone | iPhone 15 Pro Max (`iPhone16,2`), iOS 27.0 |
| Reloj | Apple Watch Ultra 2 (`Watch7,5`), watchOS 27.0 (actualizando a 27.2 beta 2) |
| Firma | Cuenta gratuita de Apple Developer (Personal Team) |
| Emparejamiento | El reloj es un dispositivo *emparejado manualmente* en CoreDevice (`manualPairing`) |

## Síntomas

1. `xcrun devicectl list devices` → el reloj aparece `unavailable`; luego **desaparece de la lista**.
2. `xcrun devicectl manage pair --device <reloj>` → `The specified device was not found (error 1000)`.
3. `xcdevice list` y `xctrace list devices` nunca lo listan.
4. Device Hub muestra **"Currently Unavailable — must be nearby to connect with this Mac"**.
5. El reloj **no anuncia** `_remotepairing._tcp` ni `_remotepairing-manual-pairing._tcp` por Bonjour en reposo
   (solo el iPhone y el iPad lo hacen).
6. Al instalar desde la **app Watch del iPhone** ▸ *Instalar*: la barra se llena a la mitad, no pasa nada,
   **el reloj (según el reporte) se reinicia** y no se instala nada.
7. La conexión iPhone ↔ reloj está sana (la duplicación del Apple Watch funciona).

## Lo que muestran los registros

Extractos completos (sin datos personales): [`logs/remotepairingd-excerpts.md`](logs/remotepairingd-excerpts.md).

1. **La Mac borró su registro del reloj** (09:33): `Unable to remove pairing record for UDID 00008310-… in usbmux`.
2. **watchOS 27 exige un emparejamiento iniciado por el usuario y se salta el automático:**
   `Device <private> supports user-driven network pairing flows. Skipping companion proxy bootstrap pairing`
   (con el iPhone por USB la Mac ve el reloj como *proxied device* y se rinde).
3. **El emparejamiento manual funciona y el reloj cuelga.** Cuatro intentos desde Device Hub (10:02, 10:03,
   10:14, 10:15) terminan igual: PairSetup M1–M6 completo, `Pairing session … succeeded`, estado
   `authenticated`, y **40 ms después** `received error reading message` → canal `invalidated`.
   Device Hub cierra la sesión y CoreDevice nunca crea el dispositivo.
4. **Caso de control:** con el iPad, el mismo servicio completa `verifyManualPairing` y mantiene el canal
   `authenticated`. Solo el reloj se cae.

## Lo que NO es el problema

* La app que se instala (firma, perfil con el UDID del reloj, IDs y versiones coinciden, build Release).
* Bluetooth / Wi-Fi / red (probado encendido y apagado, misma red y banda).
* El cable (con USB la Mac incluso ve el reloj; el fallo es el mismo).
* El Modo desarrollador (activo; también se apagó y encendió).

Lista completa en [`docs/what-i-tried.md`](docs/what-i-tried.md).

## Hipótesis

1. **Estado de emparejamiento desincronizado:** la Mac borró su registro sin que el reloj olvidara la Mac;
   el emparejamiento nuevo choca con el viejo y el reloj aborta tras M6.
2. **Bug de watchOS 27.0 beta** en el paso posterior a PairSetup. Encajaría con el reinicio del reloj al instalar.

Ninguna está confirmada.

## Reporte a Apple

Texto listo para Feedback Assistant: [`docs/feedback-assistant-report.md`](docs/feedback-assistant-report.md).
Si te pasa lo mismo, abre un issue con tus versiones de Xcode / macOS / watchOS.

## Licencia

[MIT](LICENSE). Sin relación con Apple Inc.
