# StarkBoy — session handoff

## Źródło prawdy

- Pełna specyfikacja: `MASTER_PROMPT.md`.
- Projekt: Godot 4.7.1, katalog `C:\projects\starkboyz`.
- Implementacja: GDScript, 2D, 640×360, PC keyboard + gamepad.
- Referencje: `graphics/starkboy.jpg`, `graphics/kelpinskikonkretnieboss_pixel_art.jpg` oraz dwa zdjęcia bossa.

## Stan na 2026-08-18

- Vertical slice jest zaimplementowany i grywalny od ekranu tytułowego do wyników.
- Godot MCP odpowiada i raportuje Godot 4.7.1-stable.
- Master prompt, README, sceny, skrypty, assety i smoke test są zapisane w repo.

## Checkpoint 1 — fundament uruchomiony

- `project.godot`: tytuł StarkBoy, main scene, viewport 640×360, nearest filtering i komplet bazowego Input Map dla klawiatury/gamepada.
- Dodano `scenes/main.tscn` oraz `scripts/main.gd`, `scripts/player.gd`, `scripts/hud.gd`.
- Działa swobodny ruch po pasie, kamera, stan mounted/on-foot, zejście tylko na postoju, ride-by punch, wheelie/kick, strzał, unik, bateria, amunicja i HUD.
- MCP otworzył i uruchomił `res://scenes/main.tscn`; stan edytora potwierdził aktywny play-run.
- Lokalne uruchomienie Godot 4.7.1 headless zakończyło się kodem 0 bez komunikatów parsera/runtime.
- Screenshot viewportu potwierdził poprawny HUD 640×360.
- Znane ograniczenie narzędziowe: MCP `script_validate` błędnie raportuje coarse ParseError dla `player.gd` i `hud.gd`, choć Godot 4.7.1 ładuje i uruchamia scenę bez błędów. Weryfikować równolegle rzeczywistym uruchomieniem Godota.
- Runtime capture MCP nie jest jeszcze dostępny w grze; brak wpisów runtime nie jest dowodem braku błędów.

## Checkpoint 2–4 — vertical slice funkcjonalny

- Pełna pętla: title → intro → cztery wizualne strefy → zamykane fale → boss → ending/results; Game Over i restart.
- Gracz: jazda 4-kierunkowa po pasie, ręczne zejście na postoju, dosiadanie, szybki atak, ride-by attack, heavy kick, wheelie, strzał, unik, bateria i amunicja.
- Walka: obrażenia, odrzut, i-frames, hit feedback, score, combo, grade D–S, 3 życia i 2 continue.
- Wrogowie: thug, thrower, hostile rider, mushroom picker i dog.
- Boss: dwie fazy, microphone shout, camera flash, camera smash, charge, feedback beam i broadcast summon; wymagane kwestie polskie/angielskie.
- Lokacje proceduralne: forest road, city street, motocross track, boss arena; kamera i arena są ograniczone.
- UI: HUD, boss bar, title, intro, pause, Game Over i results.
- Audio: syntetyczny whine elektrycznego motocykla zależny od prędkości oraz proceduralne krótkie SFX dla podstawowych akcji.
- Assety ImageGen zapisane lokalnie: `assets/sprites/starkboy_sheet.png` oraz `assets/sprites/kelpinski_sheet.png`; chroma key usunięty i alpha zweryfikowana. Źródła chroma zachowane obok.
- Smoke test: `tests/smoke_test.gd`; wszystkie testy PASS w Godot 4.7.1 headless.
- Godot MCP: filesystem scan, scena otwarta, play-run potwierdzony, screenshot viewportu wykonany.
- Końcowy audyt MCP: Play i Stop działają; filtrowane logi z ostatnich 5 minut zawierają 0 błędów.

## Znane ograniczenia

- Street thug, thrower i hostile rider nadal używają czytelnych proceduralnych sylwetek; StarkBoy, boss, grzybiarz i pies mają właściwe spritesheety, a lokacje używają pełnej panoramy pixel art.
- Ranged attacks są uproszczone do natychmiastowego trafienia w pasie zamiast osobnych fizycznych pocisków.
- Muzyka i SFX są syntetyzowane proceduralnie; nadają grze spójny arcade’owy podkład, ale mogą później zostać zastąpione nagranymi/skomponowanymi assetami audio.
- MCP `script_validate` zwraca fałszywe coarse ParseError dla części poprawnych skryptów; rzeczywisty parser Godot i smoke test przechodzą.

## Kontynuacja polishu

Priorytety opcjonalne: osobne sprite’y thug/thrower/rider, fizyczne pociski, więcej klatek pośrednich i dłuższe wielofalowe sekcje.

## Checkpoint 5 — poprawki po playteście użytkownika

- Naprawiono soft-lock Forest → City: po leśnej fali limit kończył się na `x=1000`, a próg miasta wynosił `x>1120`.
- Naprawiono analogiczne blokady City → Motocross i Motocross → Boss. Każda fala otwiera teraz obszar za kolejnym progiem.
- Smoke test przechodzi pełny łańcuch Forest → City → Motocross → Boss i sprawdza wszystkie wartości limitów.
- Animacje gracza korzystają z właściwych klatek dla ride-by punch, wheelie, dodge, on-foot punch, heavy kick i strzału; dodano ruch/bob, przesunięcia ataków, hit sparks i screen shake.
- Audio ulepszono: wielowarstwowy whine elektryczny zależny od prędkości, falownik, filtrowany szum opon, 16-bitowe warstwowe SFX i cicha muzyka arcade.
- Nowe assety ImageGen (built-in): `assets/sprites/forest_enemies_v2.png` oraz `assets/backgrounds/world_panorama_v2.png`.
- Grzybiarz ma idle/throw/hurt/defeat; pies idle/run/leap/retreat. Oba spritesheety mają zweryfikowane alpha i są podłączone w runtime.
- Proceduralne tło zastąpiono ciągłą panoramą pixel art pokazującą las, miasto, tor i arenę medialną.
- Wizualny render kontrolny: `tmp/screenshots/visual_regression_v2.png`.
- Końcowy MCP Play/Stop po wyczyszczeniu cache logów: 0 błędów.

## Zasady kontynuacji

- Aktualizuj ten plik po każdym materialnym checkpointcie.
- Nie usuwaj ani nie nadpisuj referencji użytkownika.
- Narzędzia/dependencies instaluj wyłącznie lokalnie w projekcie, jeśli staną się konieczne.
- Każdy checkpoint kończ: script validation → play test → logs/runtime errors → screenshot → wpis tutaj.

## Checkpoint 15 — pickupy, HUD i ładowanie motocykla

- Na każdej fali może losowo pojawić się estetyczny pickup: apteczka z czerwonym krzyżem albo napój energetyczny uzupełniający baterię; pojawienie nie jest gwarantowane.
- HUD pokazuje czerwony pasek życia, żółty pasek baterii oraz amunicję jako graficzne naboje zamiast samej liczby.
- Bateria nie regeneruje się podczas jazdy ani samego postoju na motocyklu. Ładowanie działa wyłącznie po zejściu StarkBoya z motocykla.
- Zaparkowany motocykl pozostaje dokładnie w miejscu zejścia. Obok pojawia się pixel-artowa ładowarka inspirowana `graphics/charger.jpg`, połączona widocznym przewodem z motocyklem.
- Główne assety: `assets/sprites/supply_pickups_v10.png`, `assets/ui/bullet_icon_v10.png`, `assets/sprites/parked_starkboy_bike_v11.png`, `assets/sprites/stark_charger_v12.png`.

## Checkpoint 16 — konsola kodów

- Tilde (`~`) otwiera pole wpisywania kodów w lewym górnym rogu ekranu.
- `alpha 1` / `alpha 0`: włącza lub wyłącza nieskończone życie.
- `hunter 1` / `hunter 0`: włącza lub wyłącza nieskończoną amunicję.
- `energy 1` / `energy 0`: włącza lub wyłącza utrzymywanie pełnego poziomu baterii.
- Konsola przechwytuje tekst bez uruchamiania akcji bojowych gracza.

## Checkpoint 17 — czytelność walk bossów i balans trafień

- Ataki bossów dostały wind-up, recovery oraz dłuższą blokadę gwałtownego odwracania się, aby gracz mógł podejść od tyłu i realizować strategię bez automatycznej kontry przy każdym zbliżeniu.
- Obrażenia i wytrzymałość zwykłych przeciwników oraz bossów zostały ujednolicone względem długości kampanii.
- Ataki dystansowe bossów są możliwe do uniknięcia ruchem lub dodge’em i mają widoczne, tematyczne odpowiedniki zamiast niewidzialnego trafienia.
- Atlas `assets/sprites/boss_attacks_v15.png` zawiera m.in. grzyby/zarodniki, miejski pocisk energetyczny, oponę quada i medialne pociski.

## Checkpoint 18 — straż leśna przed MediaBossem

- Przed wejściem MediaBossa pojawia się fala straży leśnej.
- Podczas właściwej walki MediaBoss jeden raz przywołuje dodatkową falę strażników.
- Strażnicy mają zielone mundury, czapki z daszkiem, pałki, pełne sprite’y i animacje; atlas: `assets/sprites/forest_guards_v16.png`.
- Fala przed bossem i wezwanie w trakcie starcia są osobnymi elementami encounter directora i nie zastępują innych pomocników finału.

## Checkpoint 19 — wyłącznie graficzne i faktycznie lecące ataki bossów

- Usunięto proceduralny placeholder ataku bossa: czerwone okręgi, łuki, pierścienie i promienie nie są już rysowane.
- Boss przekazuje teraz do efektu zarówno punkt startowy przy swojej postaci, jak i zapamiętaną pozycję docelową.
- Opona Quad Warlorda oraz ataki miasta i MediaBossa fizycznie przemieszczają się od bossa do celu; nie pojawiają się już od razu w miejscu trafienia.
- Grafika pocisku odwraca się zgodnie z kierunkiem lotu, animuje klatki podczas przemieszczania i znika po rozwiązaniu ataku.
- Leśne ataki grzybowe celowo wyrastają w miejscu docelowym, zamiast lecieć, co odpowiada ich wizualnemu charakterowi.
- Obrażenia następują na końcu widocznej trajektorii i są powiązane z pozycją grafiki ataku.
- Smoke test sprawdza przemieszczenie opony oraz brak placeholderowej metody `_draw()`; pełny zestaw testów przechodzi w Godot 4.7.1 headless.
- Aktualny build Windows: `build/windows/StarkBoy_v17.exe` (119 597 160 bajtów), wyeksportowany 2026-08-19.

## Aktualny punkt startowy następnej sesji

- Najnowszy zweryfikowany build to `StarkBoy_v17.exe`.
- Ostatnie zmieniane pliki logiki: `scripts/boss_attack.gd`, `scripts/enemy.gd`, `scripts/main.gd`, `tests/smoke_test.gd`.
- Eksport release zakończył się kodem 0. Ostrzeżenia widoczne na końcu eksportu dotyczą wyłącznie zamykania połączenia Godot MCP po zakończeniu procesu, nie kompilacji ani zawartości buildu.
- Najnowsza prośba użytkownika została wykonana: brak placeholdera ataku, opona i pozostałe właściwe pociski lecą widocznie po trajektorii.

## Checkpoint 7 — finał bossa, dodge i build Windows

- Śmierć KelpinskiKonkretnie nie otwiera już wyników natychmiast: najpierw odtwarza się animacja pokonania i fanfara, a ekran wyników pojawia się po 2,4 s.
- Dodano sześciodźwiękową fanfarę zwycięstwa w proceduralnym 16-bitowym audio.
- Okrąg trafienia motocykla zastąpiono atlasem pixel-artowych efektów `assets/sprites/combat_vfx_v4.png`.
- Unik na motocyklu jest teraz kontrolowanym przejazdem prosto w kierunku jazdy, bez składowej pionowej. Usuwa to blokowanie przy górnej krawędzi areny bossa.
- Smoke test sprawdza opóźniony ekran wyników i brak pionowego dryfu podczas mounted dodge; wszystkie asercje PASS.
- Gotowy samodzielny build Windows x86-64: `build/windows/StarkBoy.exe` (PCK wbudowany w EXE).
- Wyeksportowany EXE uruchomiono headless i zakończył pracę z kodem 0.

## Checkpoint 8 — pistolet i skrzynki amunicji

- Usunięto błędne użycie klatki punch dla strzału.
- Dodano osobny atlas `assets/sprites/starkboy_gun_v5.png`: cztery klatki draw/aim/muzzle-flash/recoil na motocyklu oraz cztery pieszo.
- Dodano atlas `assets/sprites/ammo_crate_v5.png` i trzy fizyczne skrzynki rozmieszczone w lesie, mieście i na torze.
- Skrzynka animuje otwarcie, dodaje 3 naboje i znika po krótkim czasie.
- Smoke test sprawdza dedykowaną teksturę pistoletu, liczbę skrzynek i faktyczne uzupełnienie amunicji.

## Checkpoint 9 — płynność i attack director

- Jazda ma łagodniejsze przyspieszanie i hamowanie; ruch pieszy zachowuje szybszą reakcję właściwą beat'em-upowi.
- Przeciwnicy używają płynnego sterowania prędkością oraz separation steering, więc nie sklejają się w jednej pozycji.
- Ataki mają czytelny wind-up, zatrzymanie przed ciosem/ruchem dystansowym i krótki recovery zamiast natychmiastowego zadawania obrażeń.
- Wszystkie moby dystansowe (grzybiarze, bottle throwers i drony) korzystają ze wspólnej kolejki. W torze lotu może znajdować się tylko jeden wrogi pocisk dystansowy naraz.
- Ataki wręcz również są globalnie rozsunięte, lecz korzystają z krótszego interwału, aby zachować presję grupy.
- Smoke test zabezpiecza osobne kolejkowanie grzybiarzy oraz wspólną kolejkę wszystkich mobów dystansowych.

## Checkpoint 10 — animacja chodzenia StarkBoya

- Dodano dedykowany atlas `assets/sprites/starkboy_walk_v6.png` z czteroklatkowym cyklem chodzenia pieszo.
- Nogi, kolana, biodra i ramiona pracują naprzemiennie; cykl jest zapętlony przy ruchu w dowolnym kierunku pasa.
- Idle i ataki nadal używają dotychczasowych atlasów, a przełączenie walk/idle zachowuje spójną skalę oraz linię podłoża.
- Smoke test sprawdza automatyczne użycie czteroklatkowego walk cycle po zejściu z motocykla.

## Checkpoint 11 — combat audio i respawn

- Punch i heavy kick używają wielowarstwowego karate SFX: ruch rękawa/nogi, suchy slap oraz niski body impact.
- Pistolet ma osobny report z primer crack, pressure blast, niskim wystrzałem i krótkim echem ulicznym.
- Po stracie życia gracz wraca na lewy checkpoint aktualnej sekcji: las, miasto, tor albo arena bossa.
- Respawn zeruje ruch i akcje, natychmiast ustawia kamerę oraz uruchamia dokładnie 2 s migania zsynchronizowanego z niewrażliwością.
- Smoke test zabezpiecza limit 2 s oraz pozycje checkpointów.

## Checkpoint 12 — animacje mobów, kierunek, Game Over i title art

- Wszystkie atlasy przeciwników przełączają klatki 0/1 podczas ruchu; psy, dresiarze, grzybiarze i pomocnicy pokazują pracę nóg, a motocykliści ruch maszyny/dym.
- Sprite przeciwnika i spalinowego motocykla zapamiętuje kierunek i używa `flip_h`, więc nigdy nie jedzie tyłem.
- Game Over zatrzymuje całe drzewo sceny i nie respawnuje gracza; moby oraz pociski pozostają zamrożone do restartu.
- Restart najpierw bezpiecznie usuwa pauzę, dzięki czemu nowa scena startuje normalnie.
- Ekran tytułowy używa pełnoekranowej grafiki ImageGen `assets/backgrounds/title_forest_ride_v7.png` ze StarkBoyem na czerwonym elektrycznym motocyklu w lesie.

## Checkpoint 13 — nowoczesna typografia i logo

- Cały interfejs używa osadzonego fontu Oxanium (Google Fonts, SIL OFL), technicznego kroju inspirowanego HUD-ami i grami.
- Font i licencja znajdują się w `assets/fonts/Oxanium.ttf` oraz `assets/fonts/OFL.txt`; globalny theme to `assets/ui/starkboy_theme.tres`.
- Dodano własne graficzne logo `assets/ui/starkboy_logo_v8.png`: kanciasty pixel-artowy wordmark STARKBOY, czerwono-żółty piorun i cyjanowe iskry.
- Logo jest osobnym transparentnym elementem nad leśnym title artem; tekstowy nagłówek jest ukryty wyłącznie na ekranie tytułowym i wraca na intro/Game Over/results.

## Checkpoint 14 — kampania 3×3, bossowie poziomów i MediaBoss

- Kampania ma 13 sekwencyjnych spotkań: trzy fale lasu + Mushroom King, trzy fale miasta + Tracksuit King, trzy fale toru + Quad Warlord oraz finałowy MediaBoss.
- Nowe pełne atlasy bossów: `forest_boss_v9.png`, `city_boss_v9.png`, `quad_boss_v9.png` (po 8 klatek: idle, ruch, cztery charakterystyczne ataki, hurt, defeat).
- Mushroom King: giant mushroom throw, spore slam, basket bash i forest charge.
- Tracksuit King: triple combo, street kick, pavement slam i tracksuit tackle.
- Quad Warlord: quad wheelie, power slide, exhaust burst i crushing jump.
- Każdy z trzech poziomów oraz finał mają widoczną skrzynkę amunicji (+3).
- Zwykłe fale pozostają bez niewidzialnych ścian; spotkania uruchamiają się sekwencyjnie po pokonaniu poprzedniego.
- Dawny finał został całkowicie przemianowany w runtime na `MediaBoss`; HUD, intro, wyniki i okrzyki są neutralne i nie zawierają dawnej nazwy ani charakterystycznych cytatów.

## Checkpoint 6 — pełny roster bez proceduralnych sylwetek

- Usunięto niewidzialne blokady ze zwykłych fal. Las, miasto i tor są całkowicie przejezdne; zamykana jest tylko arena bossa.
- Las zawiera wyłącznie grzybiarzy i psy.
- Miasto zawiera dresiarzy wręcz, osobnych dresiarzy rzucających butelkami oraz psy; brak grzybiarzy.
- Tor zawiera wyłącznie motocyklistów na spalinowych motorach z animowanym dymem wydechowym.
- Boss przywołuje dwa różne typy pomocników: operatora kamery i latającego media drona.
- Wszystkie typy przeciwników występujące w grze mają pełne sprite’y ImageGen; proceduralne sylwetki nie są używane przez roster tej iteracji.
- Nowe atlasy: `urban_media_enemies_v3.png`, `combustion_rider_v3.png`, `projectiles_v3.png`.
- Grzyby i butelki są widocznymi fizycznymi pociskami z animacją obrotu; butelka pokazuje klatkę rozbicia.
- Rozbudowany smoke test sprawdza roster, obecność sprite’ów, brak ścian, widoczne pociski, dym i pomocników bossa.
- Wizualne QA: `zone_forest_v3.png`, `zone_city_v3.png`, `zone_track_v3.png`, `zone_boss_v3.png` w `tmp/screenshots/`.
- Edytor został przełączony na inną scenę i ponownie otworzył świeży `main.tscn`, więc nie trzyma już starszej kopii w pamięci.
- Końcowy MCP Play/Stop po wyczyszczeniu logów: 0 błędów.

## Checkpoint 15 — wheelie, combo, fale i menu

- Wheelie zużywa 24 energii, przyspiesza motocykl do przodu i daje pełną niewrażliwość na czas ataku.
- Aktywny hitbox wheelie działa przez cały przejazd: wróg napotkany już po rozpoczęciu ataku otrzymuje obrażenia, ale najwyżej raz na jedno wheelie.
- Dwa szybko wciśnięte jaby uruchamiają combo. Na motocyklu finisher jest bocznym uślizgiem tylnego koła, odrzuca przeciwnika do tyłu i tworzy cztery kłęby kurzu.
- Zwykłe fale mają 1,5 s przerwy po pokonaniu ostatniego moba. Po bossach poziomów obowiązuje 3,5 s przejścia; następna strefa pozostaje pusta przez co najmniej 2 s.
- Po starcie można wybrać czerwony, biały albo Forest Grey kolor motocykla. Menu pokazuje duży podgląd motocykla, a instrukcje są renderowane przed nim.
- Menu ma dźwięki zmiany i zatwierdzania opcji. Escape cofa do poprzedniego ekranu; podczas gry otwiera pauzę z Resume, Main Menu i Exit Game.
- Dodano proceduralną dynamiczną muzykę 8-bit do menu i rozgrywki. `M` wycisza/włącza muzykę, a końcowy poziom miksu to -12 dB.
- Pełny `tests/smoke_test.gd` sprawdza powyższe funkcje i kończy wynikiem `SMOKE TEST RESULT: PASS`.

## Checkpoint 16 — kandydat wydania Steam

- Poprawiono `export_presets.cfg`: eksport release korzysta z oficjalnego `windows_release_x86_64.exe`, a nie szablonu debug.
- Release wyklucza testy, MCP/addony edytora, pliki robocze, źródłowe grafiki chroma/uncropped oraz katalogi build/tmp/output.
- Oficjalny szablon Godot 4.7.1 znajduje się w `tmp/export_templates/templates/windows_release_x86_64.exe`.
- Skrypt `tools/build_steam_release.ps1` uruchamia smoke test, eksportuje czysty depot, kopiuje licencje, tworzy ZIP i zapisuje SHA-256.
- Gotowy depot: `build/steam/StarkBoy/`.
- Gotowa paczka: `build/steam/StarkBoy_Windows_Steam.zip` (55 724 903 B).
- SHA-256 ZIP-a: `3a5519968b4094c6a15263debbfe449aa1b1f569e2879f3f8ac74c1971cc3705`.
- Finalny `StarkBoy.exe` ma 125 681 976 B, uruchamia się headless w Godot 4.7.1 stable release.
- Paczka zawiera `THIRD_PARTY_NOTICES.txt` oraz pełną licencję Oxanium w `LICENSES/OXANIUM_OFL.txt`.
- Dodano `AI_CONTENT_DISCLOSURE.md`, `ASSET_PROVENANCE.md`, `STEAM_RELEASE_CHECKLIST.md` oraz szablony SteamPipe w `steamworks/scripts/`.
- Wszystkie grafiki zostały zadeklarowane przez użytkownika jako stworzone z użyciem AI. Przed wysłaniem do Valve trzeba uzupełnić narzędzie/model, daty, warunki komercyjne i lokalizację archiwum promptów.
- Do publikacji nadal potrzeba prawdziwych APPID/DEPOTID, danych wydawcy, grafik kapsuł Steam i co najmniej pięciu screenshotów z rozgrywki.

## Checkpoint 17 — bieżący status Steamworks (19 sierpnia 2026)

- Konto/onboarding Steamworks jest zakładane jako `RedCloud Tomasz Wybraniec`.
- Valve/TaxIdentity poprosiło o dodatkową weryfikację KYC: dokument tożsamości oraz selfie z tym samym dokumentem.
- Użytkownik przesłał wymagane zdjęcia przez wskazany kanał. Obecnie należy czekać na wynik; typowy deklarowany czas to 2–7 dni roboczych.
- Nie ponawiać uploadu, dopóki TaxIdentity nie poprosi o nowe materiały. Monitorować dashboard Steamworks, e-mail i spam.
- Po akceptacji KYC trzeba ponownie sprawdzić/wykonać Tax Interview i podać właściwy polski Foreign TIN: co do zasady NIP dla działalności albo PESEL dla osoby prywatnej bez działalności/VAT.
- Powiadomienie o treaty benefits nie jest odrzuceniem konta. Bez poprawnego TIN Valve tymczasowo stosuje maksymalne 30% potrącenia od części przychodu ze źródeł USA; finalną stawkę pokaże ukończony Tax Interview.
- W repozytorium ani w tym handoffie nie zapisano żadnych dokumentów KYC, numerów PESEL/NIP ani innych wrażliwych danych.

## Checkpoint 18 — v29 arcade combat feel

- Dodano zależny od siły trafienia hit-stop: lekki dla jabów, mocniejszy dla finisherów, wheelie i obrażeń gracza. Implementacja używa bezpiecznego Timera ignorującego skalę czasu i zawsze przywraca `Engine.time_scale` przy wyjściu ze sceny.
- Trafienia mają osobny impact SFX, ciężkie ataki mocniejszy dźwięk oraz istniejący screen shake i efekt graficzny.
- Heavy kick, wheelie oraz oba finishery jab combo przewracają zwykłych przeciwników. Powalony i szybko odrzucony wróg może zderzyć się z kolejnym mobem, zadając obrażenia i przewracając go.
- Reżyser walki dopuszcza najwyżej dwóch przygotowujących atak przeciwników wręcz; wróg stojący za StarkBoyem czeka, jeśli inny napastnik już atakuje. Zachowano wspólną kolejkę pocisków dystansowych.
- Specjalny atak bossa otwiera po animacji 0,72 s złotego punish window. Trafienie w tym czasie zadaje 35% więcej obrażeń.
- HUD pokazuje `COMBO xN` od drugiego trafienia. Obrażenia gracza kończą combo i czyszczą premię za różnorodność.
- Wynik premiuje używanie różnych ataków. Wheelie trafiające co najmniej trzech różnych przeciwników daje jednorazowo `WHEELIE CROWD BREAK +750`.
- Zapisywany jest rzeczywisty `best_combo`, używany na ekranie wyników zamiast bieżącego combo.
- Po każdym bossie poziomu przyznawana jest ocena sekcji S/A/B/C oraz bonus punktowy zależny od wyniku i otrzymanych obrażeń.
- Fale są krótsze i mają konkretne role/motywy: break the line, hound pincer, mushroom crossfire, protect the thrower, alley crossfire, split lanes i pack breaker.
- Rozszerzony smoke test sprawdza powalenia, hit-stop, best combo, premię za różnorodność i okno kontry bossów. Pełny wynik: PASS.
- Wersja projektu: `VERSION` = `v29`.
- Debug: `build/windows/StarkBoy_v29_debug.exe`, 119 597 192 B, SHA-256 `3d84cfd4dfc75ef2adf9eadd0ea30f71644357b9e8decf2e0714ab498230cd9f`.
- Steam release EXE: `build/steam/StarkBoy/StarkBoy.exe`, 125 686 408 B, SHA-256 `1ee4ed60a3396348fea7928513eb05b41a42904edd56f54001ef265b4f134f98`.
- Steam ZIP: `build/steam/StarkBoy_v29_Windows_Steam.zip`, 55 729 297 B, SHA-256 `b0e6fdff9c554bdc69bdfa87a65b92ebf259ab1c2b6e58396330ee977cf54a13`.
- Oba EXE uruchomiono headless z `--quit-after 3`; oba zakończyły się kodem 0.
