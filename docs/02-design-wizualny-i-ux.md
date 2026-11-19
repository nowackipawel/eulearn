# 02 — Design wizualny i UX

Kierunek wybrany przez właściciela produktu w rundzie decyzyjnej skilla `impeccable` (szkic wybranego ekranu: `.impeccable/mocks/decision/assigned.html`; kontrakt kierunku: `.impeccable/surfaces/`). Zasady UX dla dzieci pochodzą z bazy `ui-ux-pro-max`. Wcześniejsza propozycja — pulchny, pastelowy styl z miękkimi cieniami — została odrzucona jako nieodróżnialna od innych aplikacji edukacyjnych.

## 1. Kierunek: „mapa ścienna z klasy”

**Granica jest bohaterem.** Wzorem jest szkolna mapa polityczna: płaskie, nasycone barwy krajów, a wzdłuż każdej granicy gruba wstęga w ciemniejszym odcieniu tej samej barwy. W aplikacji ta wstęga jest językiem postępu — nauka kraju domyka jego wstęgę.

Świat mapy ściennej daje aplikacji cztery rzeczy i tylko te: **paletę, pismo, gęstość i jeden ruch firmowy** (wstęgę graniczną). Nie daje układu ani kontrolek — przyciski, paski i nawigacja są zwykłe i czytelne. Nie rysujemy drewnianych listew, sznurków, pinezek ani faktury papieru: ekran ma być działającą aplikacją, nie obrazkiem mapy.

Cechy stylu:

- płaskie barwy, **bez cieni i gradientów**;
- białe panele z granatowym obrysem 3 dp, małe promienie (panele 6 dp, przyciski 14 dp);
- stany jako znaki drukarskie (wzór wypełnienia, obrys, znaczek), nie efekty świetlne;
- jedno stałe miejsce na postęp i objaśnienia: **legenda mapy** w rogu ekranu;
- nazwy krajów rozstrzelonymi wersalikami, nazwy mórz kursywą — jak na mapie.

## 2. Ruch firmowy: wstęga graniczna

| Stan kraju | Wypełnienie | Wstęga wzdłuż granicy |
|---|---|---|
| nie widziany | białe („mapa konturowa”) | cienka linia w barwie kraju |
| nowy (poznany, 0–1 opanowana umiejętność) | kropki w barwie kraju | do ćwierci wstęgi |
| uczę się (2–3 opanowane umiejętności) | szrafy (ukośne pasy) | połowa do trzech ćwierci |
| znam (wszystkie 4 umiejętności) | pełna barwa | wstęga zamknięta |
| mój kraj | róż | podwójnej grubości, sygnałowa czerwień, znak domku |

- **Długość wstęgi = liczba opanowanych umiejętności** (położenie, kształt, flaga, stolica): każda dodaje ćwierć obwodu, licząc od północy zgodnie z ruchem wskazówek zegara. Cztery umiejętności zamykają pętlę.
- Umiejętność liczy się jako opanowana od poziomu 3 w systemie powtórek (dokument 01).
- **Wzór wypełnienia = etap nauki kraju.** Postęp czyta się bez rozróżniania kolorów.
- Na karcie kraju ta sama wstęga jest pokazana w powiększeniu, z czterema podpisanymi ćwiartkami.
- Zaznaczenie kraju: wstęga grubieje, pozostałe kraje przygasają do 40%.
- Domknięcie wstęgi jest najważniejszą animacją nagrody w aplikacji.

## 3. Kolory

### Mapa

| Element | Barwa | Wstęga / uwagi |
|---|---|---|
| Morze (tło całej aplikacji) | `#8CC6EC` | nazwy mórz `#2D6E9E`, kursywa |
| Kraj — żółty | `#F7D860` | `#D9A90F` |
| Kraj — zielony | `#A6D48A` | `#4E9A2E` |
| Kraj — pomarańczowy | `#F5A65B` | `#D46A10` |
| Kraj — fioletowy | `#B8A2DC` | `#7650B8` |
| Kraj — piaskowy (rezerwa) | `#E8D2B0` | `#B08A4A`; używany tylko, gdy cztery barwy nie wystarczą |
| Mój kraj | `#F4A3B5` | `#D7263D`; róż i czerwień zarezerwowane wyłącznie dla mojego kraju |
| Linia graniczna | `#FFFFFF`, 2 dp | między wstęgami sąsiadów |

Sąsiedzi nigdy nie mają tej samej barwy; przydział liczy skrypt danych (dokument 03).

### Interfejs

| Rola | Barwa | Użycie |
|---|---|---|
| Atrament | `#17324D` | tekst, obrysy, pasek polecenia, przyciski główne |
| Papier | `#FFFFFF` | panele, legenda, przyciski zwykłe |
| Sygnał | `#D7263D` | mój kraj, pasek postępu rundy |
| Głos | `#F7D860` | przycisk głośnika — zawsze ten sam, zawsze żółty |
| Dobrze | `#2E8B3D` | zawsze ze znakiem ✓ i dźwiękiem |
| Pomyłka | `#D46A10` | zawsze ze znakiem i dźwiękiem; nie czerwony alarm |

Tło ekranów bez mapy (paszport, ustawienia) to ten sam błękit morza — aplikacja jest w całości „na mapie”. Kontrast tekstu co najmniej 4,5:1 (granat na bieli, żółci i barwach krajów spełnia; biały tekst tylko na granacie i czerwieni). Barwy są tokenami motywu; w widżetach nie ma surowych wartości. Tryb ciemny: nie robimy.

## 4. Typografia

| Rola | Krój | Ustawienie |
|---|---|---|
| Polecenia, przyciski, nagłówki | **Sofia Sans Semi Condensed** 800 | 28–40 sp |
| Nazwy krajów na mapie i w legendzie | **Sofia Sans Semi Condensed** 800 | wersaliki, rozstrzelenie ok. 0,2 em |
| Tekst, opisy, skojarzenia | **Andika** 400/700 | min. 18 sp |
| Nazwy mórz | **Andika** kursywa | rozstrzelona |

- Andika została zaprojektowana dla osób uczących się czytać: wyraźnie różne litery (a, g, l, I, 1), duże światła. To czcionka dla dziecka, które dopiero składa litery.
- Wersaliki tylko w krótkich nazwach własnych na mapie i etykietach; zdania i polecenia zwykłym pismem.
- Oba kroje na licencji OFL, dołączone do aplikacji jako pliki. Przy dołączaniu sprawdzić na urządzeniu znaki `ąćęłńóśźż` i `ĄĆĘŁŃÓŚŹŻ`.
- Najwyżej dwa zdania tekstu naraz; resztę mówi lektor.
- Nazwy mogą łamać się na dwie linie, nigdy nie są ucinane („Zjednoczone Emiraty Arabskie”, „Bosnia and Herzegovina”).

## 5. Mapa — zasady interakcji

- **Orientacja pozioma, zablokowana.** Telefon i tablet różnią się skalą i wielkością legendy.
- **Odwzorowanie o wiernych powierzchniach** (Equal Earth dla świata); widoki kontynentów mają własne odwzorowanie (dokument 03).
- **Przybliżanie i przesuwanie** dwoma palcami oraz przyciskami +/−. Podwójne stuknięcie przybliża do kraju.
- **Szczegółowość podpisów zmienia się płynnie z przybliżeniem:** z daleka tylko duże kraje, bliżej mniejsze, potem stolice. Podpisy pojawiają się i znikają przenikaniem, nigdy skokowo.
- **Małe kraje** (Luksemburg, Malta, Watykan): poniżej progu wielkości kraj dostaje okrągły znacznik min. 48 dp w swojej barwie z własną wstęgą; znacznik jest polem dotyku.
- **Tolerancja stuknięcia:** palec na morzu lub granicy wybiera najbliższy kraj w promieniu 16 dp.
- **Przeciąganie ma zawsze alternatywę:** w Układance granic można stuknąć klocek, potem miejsce. Przeciągany klocek jest uniesiony ponad palec.
- W pytaniach sprawdzających podpisy są ukryte.

## 6. Zasady UX dla dzieci

1. **Duże cele dotyku:** min. 64 × 64 dp, odstęp min. 16 dp.
2. **Wszystko mówi.** Każde polecenie, nazwa i odpowiedź ma głos. Żółty przycisk głośnika powtarza polecenie.
3. **Ikona + słowo** na przyciskach nawigacji.
4. **Natychmiastowa reakcja** na dotyk (do 100 ms): zmiana obrysu lub wypełnienia i dźwięk.
5. **Płytka nawigacja:** z ekranu startowego do gry najwyżej dwa stuknięcia; „wróć” zawsze w lewym górnym rogu.
6. **Brak pułapek:** bez wyskakujących okien, bez „czy na pewno?” w zabawie, bez gestów krawędziowych, bez linków zewnętrznych.
7. **Wyjście z rundy** jednym stuknięciem, postęp zapisany.
8. **Błąd zostaje jako znak, nie znika:** w pasku rundy pomyłka ma swój znaczek, a pytanie wraca później. Nic nie jest odbierane.
9. **Języki oznaczane literami** „PL” / „EN”, nigdy flagami.
10. **Dostępność:** etykiety dla czytników ekranu, systemowe „ogranicz ruch” (animacje zastąpione przenikaniem), tekst do 130% bez psucia układu. Postęp i stany zawsze mają wzór lub znak, nie tylko barwę.

## 7. Ruch

Ruch jest płaski i rzeczowy: rysowanie linii, wypełnianie wzorem, przesunięcie. Bez podskoków, sprężyn i świecenia.

| Zdarzenie | Animacja | Czas |
|---|---|---|
| Dotknięcie przycisku | wypełnienie zmienia się na granat, napis na biały | 80 ms |
| Stuknięcie kraju | wstęga grubieje, reszta mapy przygasa | 180 ms |
| Dobra odpowiedź | wstęga kraju dorysowuje się o ćwierć obwodu; znak ✓ | 500 ms |
| Kraj opanowany | wstęga domyka pętlę, wypełnienie przechodzi w pełną barwę | 800 ms |
| Zła odpowiedź | stuknięty kraj pokazuje swoją nazwę; właściwy miga obrysem | 400 ms + 2 mignięcia |
| Klocek trafia na miejsce | dosunięcie po prostej, biała linia graniczna zamyka się wokół | 220 ms |
| Lektor mówi | przycisk głośnika pulsuje obrysem | czas wypowiedzi |
| Koniec rundy | kraje z tej rundy kolejno dorysowują wstęgi na mapie | do 2 s, do pominięcia |
| Nowa pieczątka | odbicie stempla (skala 1,15 → 1, bez sprężyny) | 300 ms |

Zasady: wyjścia szybsze niż wejścia; animowane tylko rysowanie ścieżki, przezroczystość, przesunięcie i skala; nic nie blokuje dotyku dłużej niż 600 ms; nagrody można pominąć stuknięciem.

## 8. Dźwięk

- **Głos należy do bociana:** gdy lektor mówi, bocian rusza dziobem.
- **Lektor w dwóch językach:** nazwy po polsku i angielsku, polecenia w języku interfejsu. Po dobrej odpowiedzi: nazwa w języku interfejsu, pauza ok. 400 ms, nazwa w drugim języku. W MVP synteza systemowa; docelowo nagrania (dokument 04).
- **Efekty:** stuknięcie, dobra odpowiedź, pomyłka (miękki, nie brzęczyk), dosunięcie klocka, stempel, domknięcie wstęgi. 8–10 krótkich plików.
- **Muzyka:** cicha pętla tylko na ekranie startowym i w Odkrywcy.
- Osobne przełączniki: lektor / drugi język / efekty / muzyka. Wibracja przy dosunięciu klocka i stemplu.

## 9. Ekrany

Wspólny szkielet każdego ekranu z mapą: mapa na całą powierzchnię, „wróć” w lewym górnym rogu, pasek polecenia u góry na środku, legenda w lewym dolnym rogu, przybliżanie w prawym dolnym.

```
RUNDA („Gdzie to jest?”)               ODKRYWCA + KARTA KRAJU
+----------------------------------+   +----------------------------------+
| [<]   [ Pokaż Czechy  (głośnik)] |   | [<]              +-------------+ |
|                                  |   |                  | [flaga]     | |
|            M A P A               |   |                  | WŁOCHY      | |
|        (cały ekran, morze)       |   |     M A P A      |  [PL)] [EN)]| |
|                                  |   |                  |  Italy      | |
| +-LEGENDA---+                    |   |                  | Rzym [PL)][EN)]|
| | mój kraj  |               [+]  |   | +-LEGENDA--+     | wstęga: 3/4 | |
| | znam      |               [-]  |   | | ...      |     | „jak but”   | |
| | uczę się  |                    |   | +----------+     +-------------+ |
| | nowy      |                    |   +----------------------------------+
| | ▮▮▮▯▯▯▯   |  (postęp rundy)    |
| +-----------+                    |   PASZPORT (jeden arkusz = kontynent)
+----------------------------------+   +----------------------------------+
                                       | [<]  EUROPA   12 / 44            |
START                                  | wszystkie kraje na jednym        |
+----------------------------------+   | arkuszu: kształt ze wstęgą,      |
| [Ola]     mapa mojego kontynentu |   | nazwa PL + EN, stempel gdy       |
|           z moim krajem          |   | wstęga zamknięta                 |
| [ WYPRAWA DNIA ]                 |   +----------------------------------+
| [Odkrywca] [Gry] [Paszport]  [R] |
+----------------------------------+
```

`[PL)]` i `[EN)]` to przyciski głośnika z etykietą języka; `[R]` to wejście do strefy rodzica. Ikony są rysowane (wektorowe), nie emoji.

| Ekran | Zawartość |
|---|---|
| Wybór profilu | awatary dzieci na tle mapy; „dodaj” prowadzi przez bramkę rodzica |
| Pierwsze uruchomienie | język → imię/awatar → wybór mojego kraju na mapie (kraj dostaje czerwoną wstęgę) → mini-runda o moim kraju |
| Start | mapa kontynentu jako tło i zarazem obraz postępu; Wyprawa dnia, Odkrywca, Gry, Paszport |
| Gry | kafelki trybów; zablokowane pokazują, co trzeba zrobić, by je otworzyć |
| Runda | szkielet z mapą; w pytaniach wyboru (flagi, stolice) mapa zostaje w tle, a odpowiedzi leżą w białym panelu po prawej |
| Wynik rundy | mapa z dorysowanymi wstęgami, nowe stemple, „jeszcze raz” / „do domu” |
| Odkrywca | mapa + karta kraju po prawej |
| Paszport | cały kontynent na jednym arkuszu, bez stronicowania; stemple |
| Pokój gry online | kod pokoju dużymi znakami, gracze jako awatar + flaga mojego kraju; bez pól tekstowych |
| Strefa rodzica | bramka → postępy, ustawienia, profile; ten sam styl, gęstszy układ |

## 10. Zasoby graficzne do przygotowania

| Zasób | Źródło |
|---|---|
| Kształty krajów, wstęgi, wzory wypełnień | rysowane w kodzie z danych Natural Earth (dokument 03) |
| Flagi | gotowy zestaw SVG na licencji MIT (dokument 03) |
| Ikony trybów i nawigacji (ok. 15) | do narysowania: płaskie, granatowy obrys 3 dp, wypełnienia z palety mapy |
| Awatary (ok. 12) | do narysowania w tym samym stylu |
| Maskotka-przewodnik | **Bocian-podróżnik** — ptak, który co roku przelatuje nad granicami. Płaski, zbudowany z prostych kształtów w barwach mapy, granatowy obrys 3 dp, bez cieni. Mieszka przy legendzie i nie zasłania mapy. Stany: czeka, mówi (rusza dziobem), cieszy się, pokazuje (wskazuje dziobem właściwy kraj po pomyłce), macha. Rysowany w kodzie, żeby mógł się ruszać bez plików animacji. Czerwony dziób i nogi to jedyny wyjątek od zasady, że czerwień należy do mojego kraju. |
| Stemple paszportowe | generowane: kształt kraju + nazwa w dwóch językach w ramce stempla |
| Ikona aplikacji, ekran startowy | do zaprojektowania: kraj z czerwoną wstęgą na błękicie |

## 11. Czego nie robimy

- cieni, gradientów, szkła, połysku;
- pastelowych, „pulchnych” kart i przycisków-pigułek;
- dekoracji udających przedmiot (listwy mapy, papier, pinezki, sznurki);
- czerwieni i różu poza moim krajem i paskiem postępu;
- flag jako oznaczenia języka;
- emoji w roli ikon.
