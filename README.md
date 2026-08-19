# StarkBoy

Grywalny pixelartowy beat ’em up 2D w Godot 4.7. StarkBoy przemierza leśną drogę, współczesną ulicę i tor motocrossowy na czerwonym motocyklu elektrycznym, a następnie kończy transmisję neutralnego MediaBossa.

## Uruchomienie

Gotowy build Windows: `build/windows/StarkBoy.exe`. Nie wymaga zainstalowanego edytora Godot.

1. Otwórz ten folder w Godot 4.7.x.
2. Naciśnij **F6/F5** albo użyj przycisku Play.
3. W menu naciśnij **Enter**, przeczytaj intro i ponownie naciśnij **Enter**.

Scena główna: `res://scenes/main.tscn`.

## Sterowanie

| Akcja | Klawiatura | Gamepad |
|---|---|---|
| Ruch | WASD / strzałki | lewy drążek / D-pad |
| Szybki atak | J | dolny przycisk |
| Wheelie / mocny kopniak | K | prawy przycisk |
| Pistolet | L | lewy przycisk |
| Unik | Space | górny przycisk |
| Zejście / dosiadanie | E | lewy bumper |
| Pauza | Escape | Start / systemowe UI Cancel |
| Menu / Continue | Enter | standardowe UI Accept |

Z motocykla można zejść wyłącznie po zatrzymaniu. Wheelie, przyspieszenie i unik zużywają baterię, która regeneruje się podczas spokojnej jazdy lub postoju. Pistolet ma sześć nabojów, a amunicja jest uzupełniana za postęp w walce.

Pistolet ma osobną czteroklatkową animację strzału na motocyklu i pieszo. Na trasie znajdują się trzy czerwone skrzynki amunicji (las, miasto i tor); każda po podniesieniu otwiera się i dodaje 3 naboje.

Struktura kampanii: las — 3 fale grzybiarzy i psów oraz Mushroom King; miasto — 3 fale dresiarzy/bottle throwers oraz Tracksuit King; tor — 3 fale spalinowych motocyklistów oraz Quad Warlord; finał — MediaBoss z operatorami kamer i media dronami. Każdy etap ma skrzynkę amunicji. Zwykłe fale nie tworzą niewidzialnych ścian.

## Test automatyczny

```powershell
& "<ścieżka-do-Godot.exe>" --headless --path . --script res://tests/smoke_test.gd
```

Test sprawdza ładowanie sceny, HUD, statystyki gracza, fale, obrażenia, score, respawn, drugą fazę bossa i zwycięstwo.

Test obejmuje również pełną progresję i zabezpiecza przejścia Forest → City → Motocross → Boss przed ponownym soft-lockiem.

## Dokumentacja produkcyjna

- `MASTER_PROMPT.md` — pełna specyfikacja gry.
- `SESSION_HANDOFF.md` — stan implementacji i wyniki checkpointów.
