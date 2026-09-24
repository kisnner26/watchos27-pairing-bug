# El Apple Watch nunca se reconecta después de emparejarse bien (watchOS 27 + Xcode 27 / Device Hub)

🇬🇧 [Read in English](README.md)

> **Estado: abierto · en investigación.** Última actualización: 2026-09-24.
> **Reportado a Apple:** Feedback Assistant **FB24924229** (2026-09-24). Si te pasa lo mismo, abre tu propio reporte y menciona ese número.
> Se repitió la prueba tras actualizar el reloj (**watchOS 27.2, compilación 24S5091f**): mismo comportamiento. Ver [`docs/status-log.md`](docs/status-log.md).
>
> ⚠️ **Corrección (2026-09-24):** una versión anterior de este texto trataba el corte de ~40 ms como la falla.
> Un control con el iPhone muestra que ese corte es **normal**; la falla real es que el reloj **nunca se reconecta después**.

Un Apple Watch Ultra 2 que funcionaba como destino de ejecución en Xcode **desapareció de la Mac**
(`devicectl` primero lo mostró como `unavailable` y luego dejó de listarlo). Al re-emparejarlo desde
**Device Hub** (*File ▸ Pair Nearby Device…*) el emparejamiento **sale bien**. El canal de configuración se cierra a los ~30–40 ms
(algo que también le pasa al iPhone, que **se reconecta ~1,3 s después** y queda disponible). El reloj **nunca se reconecta**:
no hay `verifyManualPairing`, no anuncia `_remotepairing._tcp` y CoreDevice nunca crea su registro.

Este repositorio documenta los síntomas, la evidencia en los registros, todo lo que se probó y un
reporte listo para Feedback Assistant. Los datos personales (UDID, nombres, direcciones de red) están ocultos.

## Entorno

| | |
|---|---|
| Mac | MacBook Pro (`MacBookPro17,1`, Apple M1), macOS 27.2 (`26B5086k`) |
| Xcode | 27.0 (`27A5237l`) — los dispositivos ahora se manejan en la app aparte **Device Hub** |
| iPhone | iPhone 15 Pro Max (`iPhone16,2`), iOS 27.0 |
| Reloj | Apple Watch Ultra 2 (`Watch7,5`), watchOS 27.0 → actualizado a **27.2 (24S5091f)** |
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
3. **El emparejamiento manual funciona, el canal se cierra y el reloj no vuelve.** Cinco intentos (10:02, 10:03, 10:14,
   10:15 con watchOS 27.0; 10:55 tras actualizar): PairSetup M1–M6 completo, `Pairing session … succeeded`, `authenticated`,
   y a los ~30–40 ms `received error reading message` → canal `invalidated`. CoreDevice nunca crea el dispositivo.
4. **Caso de control (iPhone, misma Mac, mismo minuto).** Tras *Restablecer ubicación y privacidad* el iPhone también hubo que
   re-emparejarlo. Los primeros 30 ms son idénticos y luego se recupera:

   | | setup exitoso | canal cerrado | reconexión |
   |---|---|---|---|
   | iPhone | 10:54:22.173 | 10:54:22.209 (**+36 ms**) | **10:54:23.592** `verifyManualPairing succeeded` → *disponible* |
   | Reloj  | 10:55:08.951 | 10:55:08.980 (**+29 ms**) | **ninguna**; nada se anuncia por Bonjour |

   Es decir, el corte de ~40 ms es lo esperado. Lo que falta es la reconexión (y el anuncio) del reloj.

## Lo que NO es el problema

* La app que se instala (firma, perfil con el UDID del reloj, IDs y versiones coinciden, build Release).
* Bluetooth / Wi-Fi / red (probado encendido y apagado, misma red y banda).
* El cable (con USB la Mac incluso ve el reloj; el fallo es el mismo).
* El Modo desarrollador (activo; también se apagó y encendió).

Lista completa en [`docs/what-i-tried.md`](docs/what-i-tried.md).

## Hipótesis

1. **El reloj no se anuncia después del setup** (nada en Bonjour; `remotepairingd` nunca resuelve un `NearbyInfo` Bluetooth a su identidad).
2. **CoreDevice necesita una conexión verificada para crear el dispositivo**, así que un reloj que no se reconecta queda invisible.
3. **Los relojes dependen de la ruta del iPhone acompañante**, que la Mac se salta (`Skipping companion proxy bootstrap pairing`).

Ninguna está confirmada. La prueba con la actualización no cambió el comportamiento.

## Reporte a Apple

Texto listo para Feedback Assistant: [`docs/feedback-assistant-report.md`](docs/feedback-assistant-report.md).
Si te pasa lo mismo, abre un issue con tus versiones de Xcode / macOS / watchOS.

## Licencia

[MIT](LICENSE). Sin relación con Apple Inc.
