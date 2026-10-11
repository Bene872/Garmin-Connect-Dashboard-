# Pulse — Garmin Connect Dashboard

Ein responsives Dashboard in Schwarz und Grün mit React, Vite und Lucide Icons.

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

Die Demo verwendet Beispieldaten und benötigt keine Garmin-Zugangsdaten. Nach Änderungen `npm run build:pages` ausführen. Damit wird `docs/index.html` automatisch aus dem aktuellen Build erstellt.

## Mobile Ansicht

Für iPhone-Bildschirmgrößen optimiert: feste Navigation unten, Safe-Area-Abstände, große Touch-Flächen und Eingabefelder ohne automatischen Zoom. Die Funktionen wurden im Chromium-Browser bei 320, 375, 390 und 430 Pixeln Breite geprüft. Safari auf einem echten iPhone wurde noch nicht getestet.

Health-, Belastungs- und Erholungskarten orientieren sich an der vom Nutzer gelieferten Vorlage. Alle Gesundheitswerte und Scores sind reine Beispieldaten und keine medizinische Bewertung.

## Auf dem iPhone verwenden

1. https://bene872.github.io/Garmin-Connect-Dashboard-/ in Safari öffnen.
2. Teilen-Menü öffnen, dann „Zum Home-Bildschirm“ wählen (ggf. unter „Aktionen bearbeiten“ hinzufügen).
3. Wenn angeboten, „Als Web-App öffnen“ aktivieren, dann „Hinzufügen“.

Der Home-Bildschirm-Eintrag öffnet das Dashboard. Eine Internetverbindung ist erforderlich; Offline-Unterstützung und Hintergrundsynchronisierung sind nicht implementiert.

## Echte Garmin-Daten

Eine Webseite kann wegen der App-Isolation von iOS nicht direkt auf Daten in der Connect-App zugreifen. Für die offizielle automatische Synchronisierung ist eine freigegebene Garmin-Connect-Developer-Anbindung mit einem Backend und einem unterstützten Autorisierungsablauf nötig. Umfang und Verfügbarkeit der Daten hängen vom API-Zugang ab; ein Zugriff auf alle Connect-Daten kann nicht zugesichert werden. Übersicht: https://developer.garmin.com/gc-developer-program/overview/

Alternativ kann ein gesonderter Import für Garmin-Exportdateien entwickelt werden. Er ist aktuell nicht vorhanden. Apple Health stellt Webseiten keinen direkten HealthKit-Zugriff bereit; dafür wäre eine native iOS-Komponente erforderlich, und nicht alle Garmin-Werte werden an Apple Health übertragen.

Keine Garmin-Passwörter oder API-Schlüssel im öffentlichen Repository oder Frontend speichern. Derzeit sind alle Scores und Schlafphasen Beispieldaten; es gibt keine Garmin-Verbindung.
