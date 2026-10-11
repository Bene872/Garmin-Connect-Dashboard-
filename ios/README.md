# Pulse für iPhone — Apple Health

Native SwiftUI-/WKWebView-Hülle für das vorhandene Dashboard. HealthKit liest mit Zustimmung Daten vom Gerät. Keine Health-Daten werden an das Backend oder GitHub gesendet.

## Stand und Grenzen

- Implementiert: Leseberechtigungsanfrage, Tages-Schritte, letzte Tageswerte für Herzfrequenz, Ruhepuls, HRV (SDNN), Atemfrequenz und Sauerstoffsättigung; Herzfrequenzverlauf, Training der letzten sieben Tage, Schlaf der Nacht vor dem gewählten Tag.
- Schlafphasen: Core/Leicht, Tief, REM sowie nicht zugeordneter Schlaf. Ein einzelner Datenanbieter wird ausgewählt; überlappende Intervalle werden nicht doppelt gezählt. Bei widersprüchlichen Phasen bleibt der Zeitraum nicht zugeordnet. Tagesschlaf außerhalb des Nachtfensters 18:00–12:00 wird hier nicht angezeigt.
- Kein Garmin-Schlafscore, Erholungsscore oder Stresswert wird erfunden. Der Schlafkreis zeigt im Health-Modus Stunden und Phasen, keinen berechneten Score.
- HealthKit bestätigt keine verweigerten Leserechte: fehlende Daten können bedeuten, dass keine Messung oder kein Lesezugriff vorhanden ist.
- Die Weboberfläche wurde mit simulierten nativen Daten getestet. Swift-Dateien, HealthKit-Dialog und iOS-App wurden in dieser Linux-Umgebung NICHT kompiliert oder auf einem iPhone getestet. Kein signiertes Installationspaket ist vorhanden.
- Nicht implementiert: Hintergrundsynchronisierung, Cloud-Upload, App-Store-/TestFlight-Veröffentlichung, vollständige Trainingsanalysen oder Garmin-spezifische Metriken.

## Build auf einem Mac

Voraussetzungen: macOS mit Xcode und iOS-SDK, Node.js >=22.12, XcodeGen (`brew install xcodegen`), Apple-Signing-Team mit HealthKit-Unterstützung. Die Verfügbarkeit dieser Capability für dein Team muss Xcode bestätigen; eine kostenlose Installation wird nicht garantiert.

```sh
npm ci
npm run build:ios
cd ios
xcodegen generate
open Pulse.xcodeproj
```

In Xcode:

1. Target **Pulse → Signing & Capabilities** öffnen. Eigenes Team auswählen; Bundle-Identifier ggf. auf einen eigenen eindeutigen Wert ändern.
2. Prüfen, ob **HealthKit** aktiviert ist und vom Signing-Profil unterstützt wird. Keine Hintergrundzustellung aktivieren.
3. iPhone per Kabel verbinden, als Ziel auswählen, ggf. Entwicklermodus/Vertrauen bestätigen, dann **Run**.
4. In Pulse **Apple Health verbinden** antippen und gewünschte Leserechte erlauben.
5. Gegenprüfung: ausgewähltes Datum in Apple Health prüfen; fehlende/entzogene Rechte, doppelte Quellen und fehlende Schlafphasen testen. Die Health-Werte sollten nie in Netzwerkanfragen auftauchen.

`npm run build:ios` aktualisiert die gebündelte `Pulse/Resources/dashboard.html`. Diese Datei muss nach Webänderungen neu erzeugt werden. Die Projektdatei entsteht aus `project.yml`; Info.plist und Entitlements werden von XcodeGen erzeugt. Die WKWebView lädt nur das lokale Bundle. Externe HTTPS-Navigation öffnet außerhalb der HealthKit-Brücke.

## Garmin über Apple Health

Garmin Connect muss zuerst die von Garmin unterstützten Daten nach Apple Health schreiben dürfen. In Apple Health unter Profil → Apps/Datenzugriff & Geräte → Connect die angebotenen Schreibrechte prüfen; Menübezeichnungen können je nach iOS-Version variieren. Connect öffnen und die Garmin-Uhr synchronisieren, danach die gewünschten Kategorien in Apple Health prüfen. Nur tatsächlich dort vorhandene und für Pulse freigegebene Werte können gelesen werden. Garmin-Schlafphasen, HRV und Scores sind nicht garantiert übertragbar.

## Datenschutz und Entfernen

Die Berechtigung lässt sich in Apple Health beim Eintrag Pulse widerrufen. Die App schreibt nichts in HealthKit. Das Löschen der Pulse-App löscht keine Garmin-/Apple-Health-Messwerte. Das Home-Bildschirm-Symbol der Webseite ist keine native App und hat keinen HealthKit-Zugriff.
