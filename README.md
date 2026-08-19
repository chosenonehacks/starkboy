# StarkBoy

| Informacja | Wartość |
|---|---|
| Wersja | v29 |
| Silnik | Godot 4.7.1 Mono |
| Platforma docelowa | Windows x86-64 / Steam |

StarkBoy to pixelartowy beat’em up 2D inspirowany automatowymi grami akcji z lat 90. Gracz walczy pieszo i na elektrycznym motocyklu, przemierzając las, miasto, tor motocrossowy oraz finałową arenę MediaBossa.

## Najważniejsze elementy

- walka pieszo i na motocyklu,
- szybkie ciosy, ciężki atak, pistolet i unik,
- combo dwóch szybkich jabów zakończone odrzucającym finisherem,
- wheelie z aktywnym hitboxem, przyspieszeniem i chwilową niewrażliwością,
- powalenia oraz zderzenia odrzucanych przeciwników,
- hit-stop, screen shake i osobne efekty mocnych trafień,
- system combo, premia za różnorodność ataków i oceny etapów,
- wybór czerwonego, białego albo Forest Grey koloru motocykla,
- proceduralna muzyka 8-bit i efekty dźwiękowe,
- obsługa klawiatury oraz gamepada.

## Kampania i bossowie

Kampania składa się z krótkich fal o różnych układach taktycznych:

1. **Forest** — grzybiarze i szybkie psy; boss: **Mushroom King**.
2. **City** — dresiarze i przeciwnicy rzucający butelkami; boss: **Tracksuit King**.
3. **Motocross** — motocykliści spalinowi; boss: **Quad Warlord**.
4. **Media Finale** — leśna straż, operatorzy i drony; boss: **MediaBoss**.

Po specjalnym ataku boss przez krótki czas świeci na złoto. Jest to okno kontry, w którym otrzymuje zwiększone obrażenia.

## Sterowanie

| Akcja | Klawiatura | Gamepad |
|---|---|---|
| Ruch | WASD / strzałki | lewy drążek / D-pad |
| Szybki atak / jab combo | J | dolny przycisk |
| Wheelie / ciężki kopniak | K | prawy przycisk |
| Pistolet | L | lewy przycisk |
| Unik | Spacja | górny przycisk |
| Zejście / dosiadanie motocykla | E | lewy bumper |
| Wyciszenie muzyki | M | — |
| Pauza / powrót | Escape | Start / UI Cancel |
| Zatwierdzenie | Enter | UI Accept |

Wheelie i unik na motocyklu zużywają baterię. Aby ją naładować, należy zatrzymać motocykl, zejść z niego i walczyć pieszo, pozostawiając maszynę przy przenośnej ładowarce. Pistolet mieści sześć nabojów; amunicję zapewniają skrzynki oraz postęp w walce.

## Uruchomienie projektu

Wymagany jest **Godot 4.7.1 Mono**.

1. Sklonuj prywatne repozytorium.
2. Otwórz `project.godot` w Godot.
3. Uruchom projekt klawiszem **F6/F5** lub przyciskiem Play.
4. Na ekranie tytułowym naciśnij **Enter**, wybierz kolor motocykla i rozpocznij grę.

Scena główna: `res://scenes/main.tscn`.

Katalogi `.godot/`, `build/`, `tmp/` oraz lokalna wtyczka MCP są celowo wykluczone z repozytorium. Godot odtworzy cache importu przy pierwszym otwarciu projektu.

## Test automatyczny

```powershell
& (Get-Command Godot_v4.7.1-stable_mono_win64_console.exe).Source `
  --headless --path . --script res://tests/smoke_test.gd
```

Smoke test obejmuje między innymi ekran startowy, walkę, wszystkie fale, bossów, przejścia między obszarami, respawn, Game Over oraz zakończenie kampanii. Sprawdza również wheelie, jab combo, powalenia, hit-stop i punktację.

Prawidłowy wynik kończy się komunikatem `SMOKE TEST RESULT: PASS`.

## Budowanie

### Debug

```powershell
& (Get-Command Godot_v4.7.1-stable_mono_win64_console.exe).Source `
  --headless --path . --export-debug "Windows Desktop" `
  "build/windows/StarkBoy_v29_debug.exe"
```

### Steam release

Oficjalny szablon `windows_release_x86_64.exe` dla Godot 4.7.1 musi znajdować się w:

```text
tmp/export_templates/templates/windows_release_x86_64.exe
```

Następnie uruchom:

```powershell
.\tools\build_steam_release.ps1
```

Skrypt wykonuje smoke test, eksportuje release, tworzy czysty depot Steam, dołącza licencje, buduje ZIP oraz zapisuje sumę SHA-256.

## Dokumentacja

- `SESSION_HANDOFF.md` — historia checkpointów i aktualny stan projektu.
- `STEAM_RELEASE_CHECKLIST.md` — czynności wymagane przed publikacją.
- `AI_CONTENT_DISCLOSURE.md` — robocza deklaracja treści AI dla Steam.
- `ASSET_PROVENANCE.md` — rejestr pochodzenia assetów.
- `THIRD_PARTY_NOTICES.txt` — informacje o Godot Engine i użytych licencjach.

## Treści AI i licencje

Grafiki projektu zostały stworzone z użyciem generatywnej AI, a następnie wybrane, obrobione, animowane i zintegrowane przez dewelopera. Przed publicznym wydaniem należy uzupełnić rejestr narzędzi, modeli, dat i warunków użycia komercyjnego opisany w `AI_CONTENT_DISCLOSURE.md`.

Gra wykorzystuje Godot Engine na licencji MIT oraz font Oxanium na licencji SIL Open Font License 1.1. Informacje licencyjne są dołączane do paczki Steam przez skrypt wydania.
