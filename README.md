# Pulse — Dashboard mit Apple Health

Schwarzes, grünes Dashboard für Aktivitäten, Training, Herzfrequenz, Schlafphasen und Schritte. Die Datenquelle wurde von der geplanten Garmin-API auf **Apple Health / HealthKit** umgestellt.

## Webseite

https://bene872.github.io/Garmin-Connect-Dashboard-/

Die Webseite zeigt gekennzeichnete Beispieldaten. Auch als Home-Bildschirm-Verknüpfung kann sie Apple Health nicht auslesen. Der Verbindungsdialog erklärt den erforderlichen nativen App-Build.

## Native iPhone-App

SwiftUI-/WKWebView-Hülle und HealthKit-Leseanbindung liegen in `ios/`. Die App lädt das Dashboard aus dem lokalen Bundle und liest Daten nur auf dem Gerät. Es werden keine Gesundheitswerte auf GitHub oder einen Backend-Server übertragen. [Build-Anleitung und Grenzen](ios/README.md).

```sh
npm ci --cache /workspace/.npm-cache
npm run build:ios
```

Danach sind macOS, Xcode, ein geeignetes Signing-Team und ein iPhone erforderlich. In der aktuellen Linux-Umgebung wurde die Swift-App nicht kompiliert. Ein installierbares oder veröffentlichtes iOS-Paket ist noch nicht vorhanden.

## Entwicklung und Validierung

Node.js >=22.12 (hier Node 24).

```sh
npm run dev
npm run build:pages
npm run test:backend
```

`build:pages` erzeugt die eigenständige Demo in `docs/index.html`; GitHub Pages verwendet `main` und `/docs`. `build:ios` aktualisiert zusätzlich die gebündelte iPhone-Datei.

Die Weboberfläche wurde bei schmalen iPhone-Größen mit simulierten HealthKit-Daten, leeren Ergebnissen und Fehlern geprüft. Fehlende Daten werden im Health-Modus niemals durch Demo-Werte ersetzt. Garmin-Erholung, Stress und Schlafscore werden dort nicht erfunden. Der Schlafkreis zeigt verfügbare Schlafdauer und Schlafphasen. HRV aus Apple Health ist SDNN und nicht mit allen Garmin-HRV-Kennzahlen gleichzusetzen.

## Optionaler Webserver

`npm run build && npm start` liefert den Webclient auf Port 3000 aus. Dieser Server wird für HealthKit NICHT benötigt und kann keine Daten aus Apple Health lesen. `GET /api/health` prüft die Bereitschaft; `/api/health/status` erklärt die native Voraussetzung. `/api/dashboard` liefert keine Gesundheitsdaten. Die Dockerfile ist nur für optionales Webhosting vorgesehen.

## Garmin-Daten in Apple Health

Garmin Connect die angebotenen Apple-Health-Schreibrechte erteilen, Uhr synchronisieren und die tatsächlich vorhandenen Daten in Apple Health prüfen. Pulse liest nur vorhandene, freigegebene Daten. Nicht alle Garmin-Daten oder Schlafphasen werden übertragen. Keine Garmin-API-Freigabe und kein Garmin-Passwort werden für diesen Ansatz benötigt.

Health-Berechtigungen lassen sich jederzeit widerrufen. Pulse schreibt keine Health-Daten und speichert keine Zugangsdaten. Die App kann entfernt werden, ohne die Messwerte in Apple Health oder Garmin zu löschen.
