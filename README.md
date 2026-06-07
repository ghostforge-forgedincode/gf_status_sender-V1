# GhostForge Status Sender

Eine kleine FiveM-Resource, die Live-Statusdaten deines Servers an einen externen API-Endpunkt sendet.

Erstellt von **B2D2 | GhostForge**

## Funktionen

- Sendet aktuelle Spielerzahl und maximale Spieleranzahl
- Sendet Laufzeit, Resource-Anzahl, Server-Build und Connect-Befehl
- Unterstützt txAdmin Shutdown- und Restart-Events
- Enthält manuelle Konsolenbefehle zum Testen
- Konfigurierbarer API-Endpunkt, Secret und Restart-Zeiten

## Installation

# Wir empfehlen immer den letzten Release herunterzuladen!

1. Lege den Resource-Ordner in deinen FiveM-`resources`-Ordner.
2. Füge die Resource in deiner Server-Konfiguration hinzu:

```cfg
ensure gf_status_sender
```

3. Öffne die `config.lua` und passe die Werte an:

```lua
Config.ApiUrl = "https://example.com/fivem/status"
Config.Secret = "CHANGE_ME"
Config.ConnectCommand = "connect 127.0.0.1:30120"
```

4. Starte deinen Server neu.

## Konsolenbefehle

```txt
gfstatus_send
```

Sendet den aktuellen Live-Status sofort.

```txt
gfstatus_offline shutdown Manueller Test
```

Sendet manuell einen Offline-Status.

```txt
gfstatus_debug
```

Gibt den erzeugten Payload in der Serverkonsole aus.

## Lizenz und Nutzung

Diese Resource darf kostenlos genutzt werden, Credits sind jedoch verpflichtend.

Pflichtangabe:

```txt
Created by B2D2 | GhostForge
```

Die Nutzung dieser Resource unterliegt den enthaltenen Dateien `LICENSE` und `TERMS_OF_USE.md`.

Für die Nutzung auf einem öffentlichen Server ist eine kostenlose Lizenz über den offiziellen GhostForge Discord erforderlich.

Discord: https://discord.gg/AS3wHDneKS
