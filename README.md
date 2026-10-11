# Pulse — Garmin Connect Dashboard

Ein responsives Dashboard in Schwarz und Lila mit React, Vite und Lucide Icons.

## Entwicklung

Node.js 22.12 oder neuer (hier mit Node.js 24 getestet).

```sh
npm ci --cache /workspace/.npm-cache
npm run dev
```

Produktionsbuild: `npm run build`. Vorschau: `npm run preview`.

## Funktionen

- Wochenübersicht für aktive Minuten
- Aktivitäten mit Filter und Detaildialog
- Herzfrequenzverlauf (Beispieldaten; keine medizinische Auswertung)
- Schlafdauer, Schlafscore und Schlafphasen
- Schritte mit anpassbarem Tagesziel
- Responsive Navigation und reduzierte Animationen bei entsprechender Systemeinstellung

Alle Werte sind ausdrücklich als Demo gekennzeichnet. Zeitraum und Wochennavigation demonstrieren die Oberfläche. Das Schrittziel bleibt während der aktuellen Sitzung erhalten.

## Garmin-Anbindung

Diese Version enthält keine Anmeldung oder Garmin-Verbindung. Für echte Daten ist als nächster Schritt ein Backend mit sicherer Authentifizierung und Datenimport erforderlich. Keine Garmin-Zugangsdaten im Frontend speichern. Die Daten liegen aktuell in `src/main.jsx`.

Schriftarten werden optional von Google Fonts geladen; lokale Systemschriften dienen als Fallback.

## GitHub Pages

Die sofort nutzbare Demo liegt als eigenständige Datei in `docs/index.html`.

GitHub → Repository → Settings → Pages → Build and deployment:

- Source: Deploy from a branch
- Branch: main
- Folder: /docs
- Save

Die Demo verwendet Beispieldaten und benötigt keine Garmin-Zugangsdaten. Nach Änderungen am React-Code `npm run build` ausführen und die eigenständige HTML-Datei neu erzeugen, bevor die Pages-Demo aktualisiert wird.
