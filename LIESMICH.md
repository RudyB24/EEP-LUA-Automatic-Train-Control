Im November 2021 bin ich in ein neues Haus gezogen. Neben den vielen Vorteilen, die das neue Haus bietet, gibt es ein kleines Problem: Es gibt keinen Platz mehr für meine Modelleisenbahn. EEP kam zur Rettung ... Ich kann immer noch Modelleisenbahnen entwerfen und 'bauen', und auf meinem 4k-Bildschirm macht es Spaß, daran herumzubasteln.

Meine alte Modelleisenbahn war computergesteuert mit einem Programm namens Traincontroller. Es ermöglicht einen automatischen Zugverkehr, wobei es sich um das Schalten von Weichen und Signalen sowie das Beschleunigen und Abbremsen der Züge kümmert.

Mir ist aufgefallen, dass EEP keine automatische Zugsteuerung eingebaut hat ... oder zumindest nicht in einer Weise, die benutzerfreundlich ist. Es gibt jedoch Lua, mit dem wir Code schreiben können, um diese Aufgaben auszuführen. Ich habe mich gefragt, ob es möglich wäre, ein Lua-Programm zu schreiben, das den automatischen Zugverkehr in EEP steuert, so wie es Traincontroller mit einer echten Modellbahnanlage tut.

Ich habe mir folgende Ziele gesetzt:
 - Die Züge sollen automatisch von Block zu Block fahren
 - Es sollte möglich sein, festzulegen, welche Züge in welchen Blöcken fahren dürfen
 - Es soll möglich sein, Haltezeiten zu definieren, pro Zug und Block
 - Es soll möglich sein, einzelne Züge zu starten / zu stoppen
 - Es soll für jede (Modell-)Bahnanlage funktionieren, ohne dass Lua-Code (neu) geschrieben werden muss
 - Die Anlage wird ausschließlich durch die Eingabe von Daten über Züge, Signale, Weichen und Strecken definiert
 - Das Ergebnis dieses EEP Lua Automatic Traffic Control Projekts kann hier heruntergeladen werden.

Eine Erklärung, wie es funktioniert und wie man die Lua-Tabellen mit Daten füllt, die das eigene Layout definieren, liegt bei:
 - English: EEP_Lua_Automatic+Train_Control.pdf
 - Deutsch: EEP_Lua_Automatische_Zugsteuerung.pdf

Der EEP-Ordner enthält 5 funktionierende EEP-Demo-Layouts mit dem Lua-Code und der Layoutdefinition.

Der LUA-Ordner enthält 5 Dateien mit dem Lua-Code, um die Bearbeitung des Codes z.B. in Notepad++ zu erleichtern.

Der GBS-Ordner enthält 5 Dateien mit den Gleisbildstellpulten, die man sich selber in die Anlagen einfügen kann.
Unter dem Start/Stopp-Signal befinden sich die Zugsignale. Diese Signale können auch im automatischen Betrieb betätigt werden.
Die Block-Signale (in Fahrtrichtung am Rand der Kacheln) und die Speicher-Signale (in Fahrtrichtung in der Mitte der Kacheln) sowie die Weichen dürfen im automatischen Betrieb nicht verstellt werden.

Der TC-Ordner enthält die 5 Layouts in Traincontroller, für diejenigen, die vielleicht mit TC basteln möchten. Kostenlose Demo-Version: https://www.freiwald.com/pages/download.htm

Der Ordner Images enthält Bildschirmfotos der 5 Layouts in EEP, SCARM und Traincontroller.

Der SCARM-Ordner enthält 2 SCARM-Dateien, eine mit den Layouts 1-4 (öffnen Sie das Menü Ansicht > Ebenen, um die Ebenen zu wechseln) und eine mit Layout 5, für diejenigen, die vielleicht mit SCARM basteln möchten. Kostenlose Demo-Version: https://www.scarm.info/index.php

Eine Reihe von YouTube-Videos ist in Arbeit.

Alle Fragen, Kommentare und Ideen sind willkommen. In der Zwischenzeit ... viel Spaß.

Übersetzt mit www.DeepL.com/Translator
