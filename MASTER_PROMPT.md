# StarkBoy — master prompt wykonawczy

> Aktualna rewizja kampanii zastępuje pierwotny układ jednego przejazdu: trzy pełne poziomy mają po trzy sekwencyjne fale i własnego bossa. Las kończy Mushroom King, miasto Tracksuit King, tor motocrossowy Quad Warlord. Po nich następuje krótki finał z neutralnym `MediaBoss`. Dawna nazwa i charakterystyczne okrzyki finałowego bossa nie są używane w grze. Każdy poziom oraz finał zawiera skrzynkę amunicji.

Stwórz kompletny, grywalny vertical slice gry 2D beat ’em up pod tytułem „StarkBoy” w aktualnie otwartym projekcie Godot.

Pracuj autonomicznie aż do uzyskania działającego rezultatu. Nie zatrzymuj się po stworzeniu samego szkieletu projektu. Jeśli jakiś szczegół nie został określony, przyjmij rozsądne rozwiązanie pasujące do automatowych gier Capcomu z lat 90. Nie kopiuj jednak bezpośrednio cudzych postaci, poziomów, muzyki ani grafik.

Używaj Godot MCP do pracy z edytorem, scenami, węzłami, zasobami, uruchamianiem gry, wykonywaniem zrzutów ekranu i sprawdzaniem błędów. Kod napisz w GDScript. Po każdym większym etapie waliduj skrypty, uruchamiaj grę i naprawiaj wykryte problemy.

## Koncepcja i fabuła

„StarkBoy” to jednoosobowy beat ’em up 2D o rytmie i czytelności automatowych gier akcji z lat 90. Gracz porusza się swobodnie w lewo/prawo oraz w ograniczonym zakresie góra/dół. Kamera śledzi gracza, a finałowa arena zostaje zamknięta.

StarkBoy czerpie frajdę z jazdy czerwonym elektrycznym motocyklem terenowym po lasach. Lokalny ekscentryczny reporter „KelpinskiKonkretnie” prowadzi absurdalną kampanię oczerniającą to hobby. StarkBoy przemierza leśną drogę, ulicę i tor motocrossowy, by zakończyć konflikt w komediowej walce. Ton: lekki, satyryczny, bez wulgaryzmów, krwi i gore.

Docelowa długość: 8–12 minut. Kolejność: leśna droga → współczesna ulica → tor motocrossowy → arena bossa.

## Referencje

Najpierw sprawdź `res://graphics/`:

- `starkboy.jpg`
- `kelpinskikonkretnieboss.jpg`
- `kelpinskikonkretnieboss2.jpg`
- `kelpinskikonkretnieboss_pixel_art.jpg`

`starkboy.jpg` jest planszą referencyjną, nie gotowym spritesheetem. Zawiera opisy, ramki, zielone tło i nierówne kadry. Przygotuj na jej podstawie spójne sprite’y z przezroczystością. Zachowaj czarny strój i kask, czerwone akcenty i czerwony elektryczny motocykl. Nie używaj logotypów ani znaków prawdziwych producentów.

Fotografie bossa są referencją do dozwolonej, przekształconej karykatury. Nie umieszczaj zdjęć bezpośrednio w grze. Główną referencją wizualną jest `kelpinskikonkretnieboss_pixel_art.jpg`: większy starszy łysy reporter, ciemnoniebieski sweter, szare spodnie, okulary na szyi, mikrofon i duża kamera. Pozostałe assety wykonaj jako spójny pixel art. Dopuszczalne są przejściowe placeholdery, ale bohater, motocykl, boss i podstawowi wrogowie muszą otrzymać czytelną finalną oprawę.

## Technologia

- Godot 4.x, GDScript.
- Bazowa rozdzielczość 640×360.
- Ostre skalowanie pixel art, filtrowanie tekstur wyłączone, zachowanie proporcji.
- PC: klawiatura i standardowy gamepad; architektura gotowa na późniejsze sterowanie dotykowe.
- UI i większość dialogów po angielsku; polskie okrzyki bossa pozostają po polsku.
- Modułowo oddziel sterowanie, walkę, motocykl, AI, level flow, HUD, arcade state, bossa i audio. Używaj sygnałów, grup i zasobów, unikaj jednego monolitycznego skryptu.

## Sterowanie

Klawiatura: WASD/strzałki ruch, J szybki atak, K mocny atak/wheelie, L strzał, Space unik, E zejście/dosiadanie, Escape pauza, Enter zatwierdzanie/continue.

Gamepad: drążek/D-pad ruch, face buttons ataki/strzał/unik, bumper zejście/dosiadanie, Start pauza. Dodaj ekran sterowania.

## Motocykl i ruch

Gracz zaczyna na motocyklu. Może swobodnie jeździć po pasie walki, przyspieszać, wykonać ofensywne wheelie, uderzać pięścią lub nogą podczas przejazdu, strzelać i robić unik. Motocykl ma zręcznościową bezwładność, ale responsywne sterowanie.

Zejście jest ręczne i możliwe tylko po niemal pełnym zatrzymaniu. Pozostawiony motocykl bezpiecznie czeka; wrogowie go nie kradną i nie niszczą. Gracz może ponownie dosiąść.

Wheelie zużywa baterię, zadaje wysokie obrażenia, odrzuca małych wrogów i ma czytelne startup/active/recovery. Nie może być bezkarnie spamowane.

## Walka pieszo

StarkBoy chodzi w czterech kierunkach, wykonuje szybkie combo pięściami, mocny odrzucający kopniak, strzela, robi unik z krótkimi i-frames i może dosiąść motocykla. Dodaj hitstop, delikatny screen shake, błysk trafienia, efekty uderzeń, odrzut i krótką nietykalność po obrażeniach. Mocne ataki wrogów muszą być telegrafowane.

## Bateria i pistolet

HUD pokazuje baterię. Zużywają ją przyspieszenie, wheelie i unik na motocyklu. Regeneruje się podczas spokojnej jazdy i postoju. Zero baterii nie zatrzymuje pojazdu, lecz czasowo blokuje/osłabia akcje specjalne. Dodaj sygnał niskiej baterii.

Pistolet działa na motocyklu i pieszo, ma 6 nabojów, krótki cooldown i czytelny licznik. Amunicja wypada z wrogów lub skrzynek. Broń ma wspierać walkę wręcz, nie zastępować jej.

## Przeciwnicy

Dodaj co najmniej pięć typów:

1. Street Thug — prosty wróg wręcz.
2. Thrower — zachowuje dystans, rzuca puszkami/butelkami.
3. Hostile Rider — telegrafowana szarża motocyklem.
4. Mushroom Picker — leśny grzybiarz rzucający grzybami o humorystycznym zachowaniu.
5. Dog — szybki pościg i skok; po pokonaniu ucieka lub zostaje ogłuszony, bez drastyczności.

AI ma rozstawiać wrogów wokół gracza i ograniczać jednoczesne ataki, aby walka była uczciwa.

## Poziom

### Forest Road

Leśna droga, spokojny tutorial jazdy, pierwszy wróg, grzybiarze, psy, pnie, kamienie i kałuże.

### City Street

Współczesna ulica z graffiti, znakami, kontenerami i ławkami. Zbiry, throwerzy, większa fala i skrzynki.

### Motocross Track

Ziemia, rampy i przeszkody, hostile riders, nacisk na przyspieszenie i wheelie, finałowa fala.

### Boss Arena

Po wejściu zamknij wyjścia, zatrzymaj dalsze przewijanie kamery i pokaż boss health bar. Po zwycięstwie uruchom ending i results.

## Boss: KelpinskiKonkretnie

Wyświetlana nazwa: `KELPINSKIKONKRETNIE` (możliwy krótszy wariant w pasku, pełna nazwa w intro). Boss jest większą przerysowaną wersją reportera i walczy mikrofonem oraz kamerą. Ma dwie fazy.

Faza 1:

- Microphone Shout: „PRECZ Z MOTORAMI!”, widoczna fala odpychająca/ogłuszająca.
- Camera Flash: krótka dezorientacja bez długiego białego ekranu.
- Camera Smash: „KONKRETNIE!”, uderzenie kamerą i lokalna fala.
- Short Charge: szarża, po chybieniu okno podatności.

Faza 2 od około 50% HP:

- szybszy ruch i łączenie ataków;
- Broadcast Summon: maksymalnie dwóch pomocników lub media drones;
- Feedback Beam inspirowany pixelartową referencją;
- uczciwe telegraphy i okna kontrataku.

Kwestie: “Let’s make this concrete!”, “Look into the camera!”, “Breaking news!”, „PRECZ Z MOTORAMI!”, „KONKRETNIE!”. Wyświetlaj je krótko nad bossem bez zatrzymywania gry. Boss musi być możliwy do pokonania na motocyklu i pieszo. Po przegranej upuszcza sprzęt w kreskówkowej animacji.

## Arcade systems

- Score za trafienia, pokonania, wheelie i dobre uniki.
- Combo resetowane po przerwie lub obrażeniach.
- Wynik końcowy D/C/B/A/S zależny od score, combo, czasu, żyć i continue.
- 3 życia, 2 continue.
- Po życiu: bezpieczny respawn w bieżącej sekcji.
- Po utracie żyć: Continue countdown; continue odnawia 3 życia i wraca na początek sekcji.
- Po wyczerpaniu: Game Over, restart poziomu lub menu.

HUD: health, lives, continues, battery, ammo, score, combo oraz boss HP. Ekrany: title/menu, intro, controls, pause, continue, Game Over, ending i results.

## Audio

Dodaj oryginalne lub bezpieczne placeholdery muzyczne i SFX: cios, kopnięcie, trafienie, unik, strzał, empty gun, ammo pickup, wheelie, kontakt motocykla, pies, grzyb, camera flash, microphone wave, camera smash, boss intro, victory, Game Over i Continue.

Motocykl jest elektryczny: żadnego silnika spalinowego. Użyj wysokiego whine zależnego od prędkości, subtelnego falownika, szumu opon i nawierzchni oraz elektrycznego akcentu przy przyspieszeniu/wheelie. Jeśli brak plików, utwórz proste syntetyczne placeholdery. Nie pobieraj przypadkowych chronionych nagrań.

## Jakość i kolejność pracy

Najpierw audyt projektu i assetów, potem: konfiguracja/Input Map → ruch na motocyklu → zejście i walka pieszo → obrażenia/HUD/bateria/pistolet → jeden wróg → pozostałe AI → cztery sekcje → boss → arcade systems → intro/ending/UI → grafiki/audio/polish → pełny test.

Po każdym większym etapie zapisz sceny, waliduj wszystkie GDScripty, sprawdź logi, uruchom grę, sprawdź runtime errors i wykonaj screenshot. Nie uznawaj braku logów za dowód poprawności.

Gra ma mieć stabilne kolizje, Y-sorting, ograniczenie pasa walki i kamery, czytelne telegraphy oraz możliwość ukończenia całej pętli menu → poziom → boss → ending/results na klawiaturze i gamepadzie.

## Kryteria ukończenia

Projekt uruchamia się bez błędów; wszystkie opisane akcje gracza, bateria i amunicja działają; występuje pięć typów wrogów i cztery sekcje; boss ma dwie fazy oraz wymagane ataki/kwestie; działają score, combo, życia i continue; można wygrać, przegrać i zrestartować; obecne są podstawowe grafiki, VFX i audio; pełne przejście nie ma błędów blokujących.

Na końcu podsumuj utworzone sceny/skrypty, uruchomienie, sterowanie, wykonane testy i znane ograniczenia/placeholdery. Rozpocznij teraz od inspekcji projektu oraz `res://graphics/` i implementuj, nie zatrzymując się na samym planie.
