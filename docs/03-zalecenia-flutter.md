# 03 — Zalecenia implementacyjne (Flutter)

Dokument wiążący przy implementacji. Zasada nadrzędna: **najprostsze kompletne rozwiązanie** — bez abstrakcji na zapas, bez backendu do czasu multiplayera online (etap 3), jak najmniej pakietów.

## 1. Założenia

| Obszar | Decyzja |
|---|---|
| Platformy | Android i iOS, telefon + tablet. Web i desktop poza zakresem. |
| Orientacja | tylko pozioma (`SystemChrome.setPreferredOrientations`) |
| Sieć | aplikacja w pełni offline; do etapu 3 (multiplayer online) nie wykonuje żadnych połączeń |
| Języki | polski i angielski od pierwszej wersji; drugi język jako lektor „do osłuchania” |
| Flutter / Dart | bieżąca wersja stabilna; Dart 3 (rekordy, klasy `sealed`, dopasowanie wzorców) |
| Wersje pakietów | dodawać przez `flutter pub add` (najnowsze stabilne), nie przepisywać numerów z pamięci |
| Lint | `flutter_lints`, `flutter analyze` bez ostrzeżeń przed każdym commitem |
| Repozytorium | `https://github.com/nowackipawel/eulearn.git`; projekt Flutter w katalogu głównym, dokumenty w `docs/` |

## 2. Architektura

Trzy warstwy z jednokierunkowym przepływem: UI → logika → dane.

```
lib/
├── main.dart                   # ładuje dane i preferencje, blokuje orientację
├── app.dart                    # MaterialApp.router, trasy, język
├── providers.dart              # dostawcy Riverpod
├── l10n/                       # app_en.arb (szablon), app_pl.arb
├── data/                       # geo_repository, profile (+ zapis), speech_service
├── domain/                     # models, leitner, question_factory — czysty Dart
└── ui/
    ├── core/                   # theme (tokeny), widgets, map_screen (szkielet), map/geo_map
    └── features/               # onboarding, home (+ gry), round, explorer, passport, parent_zone
tool/build_geo.dart             # potok danych mapy
```

Reguły:

- **`domain/` to czysty Dart** — bez importów Fluttera, bez Riverpoda. Dzięki temu logikę gry testuje się zwykłym `dart test`, a w przyszłości można ją uruchomić po stronie serwera multiplayera.
- **Repozytoria** są jedynym źródłem prawdy; UI nie czyta zasobów ani `SharedPreferences` bezpośrednio.
- **Widoki są „głupie”**: układ, animacja, przekazanie zdarzenia. Stan i decyzje należą do notyfikatora (odpowiednik ViewModelu).
- Każdy ekran: plik widoku + plik notyfikatora w katalogu funkcji. Bez osobnych interfejsów dla klas z jedną implementacją i bez warstwy „use case” — logika wielokrotnego użytku to zwykłe funkcje w `domain/logic/`.

## 3. Stan: Riverpod

Pakiet `flutter_riverpod`, API `Notifier` / `AsyncNotifier` (nie przestarzałe `StateNotifier`/`ChangeNotifier`). Bez generatora kodu — dostawców jest kilkunastu, `build_runner` nie jest wart swojej ceny.

| Dostawca | Typ | Zakres |
|---|---|---|
| `geoProvider`, `prefsProvider`, `speechProvider` | `Provider`, nadpisane w `main()` gotowymi obiektami | cała aplikacja; dane ładowane raz przed pierwszą klatką |
| `profilesProvider` | `NotifierProvider` | lista profili, aktywny profil z postępem i ustawieniami |
| `pendingLangProvider` | `NotifierProvider` | język wybrany w pierwszym uruchomieniu, zanim powstanie profil |

Stan rundy (`GameSession`, zaznaczenia, animacja wstęgi) żyje lokalnie w `RoundScreen` — dotyczy jednego ekranu i znika razem z nim. Przenieść do dostawcy dopiero przy multiplayerze, gdy rundę będą współdzielić zdarzenia z sieci.

Zasady: stan niemutowalny (nowa instancja przy każdej zmianie); `ref.watch` z `select` w widżetach mapy, żeby zmiana jednego kraju nie przebudowywała całego ekranu; `setState` tylko dla stanu czysto lokalnego (np. pozycja przeciąganego klocka).

Modele: zwykłe klasy `final` z konstruktorami `const`, `copyWith` pisany ręcznie tam, gdzie potrzebny. Bez `freezed`.

## 4. Nawigacja

`go_router` z płaską listą tras: `/profiles`, `/onboarding`, `/home`, `/explorer`, `/round/:mode`, `/result`, `/passport`, `/parent`. Przekierowanie na `/profiles` lub `/onboarding`, gdy brak aktywnego profilu. Wybrany od początku, bo zaproszenie do gry online (etap 3) będzie linkiem do trasy.

## 5. Dane geograficzne

### 5.1 Źródła

| Dane | Źródło | Licencja |
|---|---|---|
| Granice krajów | Natural Earth, Admin 0 Countries, skala 1:50m | domena publiczna |
| Stolice i ich współrzędne | Natural Earth, Populated Places (cecha „Admin-0 capital”) | domena publiczna |
| Nazwy krajów po polsku i angielsku | pola `NAME_PL`, `NAME_EN` w Natural Earth; korekta ręczna | domena publiczna |
| Nazwy stolic | angielskie z Natural Earth; polskie z listy przygotowanej ręcznie (egzonimy: Rzym, Paryż, Pekin) | własna |
| Flagi SVG | zestaw `flag-icons` (pliki 4:3) | MIT |
| Skojarzenia | treść własna, pisana osobno dla każdego języka | własna |

Przed publikacją zweryfikować aktualne warunki licencji i dodać ekran „Licencje” w strefie rodzica (`showLicensePage` + wpisy dla danych).

### 5.2 Potok danych (uruchamiany przez programistę, nie w aplikacji)

Skrypt `tool/build_geo.dart` (plus `mapshaper` z linii poleceń) zamienia dane źródłowe w gotowe zasoby. Aplikacja nie zna współrzędnych geograficznych — dostaje punkty już zrzutowane na płaszczyznę.

Kroki:

1. Filtr do listy 197 krajów (klucz: kod ISO 3166-1 alpha-2, małymi literami — taki sam jak nazwy plików flag).
2. Uproszczenie geometrii w `mapshaper` z zachowaniem topologii (wspólne granice pozostają wspólne — bez szczelin i nakładek między krajami). Usunięcie wysepek poniżej progu powierzchni.
3. Wyliczenie sąsiedztwa z topologii (wspólny odcinek granicy) + ręczny plik poprawek `tool/overrides.json` (sąsiedzi przez most/tunel, „bliskie kraje” dla wysp, wyjątki).
4. Rzutowanie: świat w Equal Earth; każdy kontynent osobno w odwzorowaniu azymutalnym równopowierzchniowym wyśrodkowanym na kontynencie. Wynik w pikselach umownego płótna (np. szerokość 2000).
5. Przydział barwy tak, by sąsiedzi mieli różne: cztery barwy podstawowe, piąta (piaskowa) tylko gdy algorytm zachłanny po grafie sąsiedztwa nie zmieści się w czterech. Róż jest zarezerwowany dla „mojego kraju” i nadawany w aplikacji, nie w danych.
6. Dla każdego kraju: prostokąt otaczający, punkt etykiety (środek największego wielokąta), pozycja stolicy, flaga „mały kraj” (pole poniżej progu).
7. Zapis zasobów i raport kontrolny (kraje bez flagi, bez stolicy, bez nazw w którymś języku, niesymetryczne sąsiedztwo → błąd skryptu).

### 5.3 Zasoby wynikowe

```
assets/
├── geo/
│   ├── countries.json          # dane niezależne od widoku i języka
│   ├── view_world.json         # geometria: świat
│   └── view_europe.json …      # geometria: po jednym pliku na kontynent
├── i18n/
│   ├── geo_pl.json
│   └── geo_en.json
├── flags/pl.svg …
├── flag_templates.json         # opisy flag dla Malarza flag (etap 2)
├── audio/sfx/*.mp3
└── fonts/
```

`countries.json` (fragment):

```json
{
  "pl": {
    "continent": "europe",
    "neighbors": ["de", "cz", "sk", "ua", "by", "lt", "ru"],
    "near": [],
    "color": 2,
    "tiny": false,
    "similarFlags": ["id", "mc"]
  }
}
```

`geo_pl.json` i `geo_en.json` (fragmenty):

```json
{ "fr": { "name": "Francja", "nameAcc": "Francję", "nameGen": "Francji",
          "capital": "Paryż", "hook": "Francja ma kształt sześciokąta." } }
```

```json
{ "fr": { "name": "France", "capital": "Paris",
          "hook": "France looks like a hexagon." } }
```

`view_europe.json` (fragment): dla każdego kodu lista wielokątów jako płaskie tablice `[x0, y0, x1, y1, …]`, `bbox`, `label: [x, y]`, `capital: [x, y]`.

Kraj występuje w widoku świata i w widoku swojego kontynentu. Kraje leżące na dwóch kontynentach (Rosja, Turcja) mają jeden kontynent „paszportowy”, ale ich geometria jest w obu widokach, których dotyczą.

## 6. Renderowanie mapy

Własny widżet `GeoMap` na `CustomPainter` — bez pakietów mapowych (kafelki, serwery i odwzorowania w locie nie są tu potrzebne).

- **Ładowanie:** `GeoRepository` parsuje JSON (ok. 70 kB dla Europy; przenieść do izolatu `compute`, gdy dojdzie widok świata) i buduje dla każdego kraju obiekt `ui.Path` raz, przy starcie.
- **Warstwy** (każda w osobnym `RepaintBoundary`):
  1. baza — ocean i wszystkie kraje w kolorach wynikających z postępu; przemalowywana tylko przy zmianie postępu;
  2. wyróżnienia — zaznaczenie, pulsowanie, mój kraj; sterowana animacją;
  3. nakładki — etykiety, pinezki stolic, znaczniki małych krajów, przeciągany klocek (zwykłe widżety w `Stack`, pozycjonowane przez tę samą macierz przekształcenia).
- **Przybliżanie/przesuwanie:** `InteractiveViewer` z `TransformationController`; animowane przejście do prostokąta kraju lub regionu przez interpolację macierzy. Ograniczenia skali zależne od widoku.
- **Wstęga graniczna** (ruch firmowy z dokumentu 02): `canvas.clipPath(path)` + obrys tej samej ścieżki o podwójnej grubości daje pas po wewnętrznej stronie granicy. Długość wstęgi = liczba opanowanych umiejętności / 4 obwodu: `path.computeMetrics()` i `extractPath(0, length * n / 4)` na największym wielokącie kraju, start w najbardziej północnym punkcie (skrypt danych obraca listę punktów tak, by zaczynała się od niego). Animacja dorysowania = animowana długość.
- **Wzory wypełnienia** (kropki, szrafy) rysowane wprost w obszarze przycięcia kraju (`drawPoints`, `drawLine`). Krok wzoru jest przyciągany do potęg dwójki skali, żeby wzór stał w miejscu między poziomami przybliżenia.
- **Grubość linii** dzielona przez bieżącą skalę, żeby granice nie grubiały przy przybliżeniu.
- **Trafianie dotyku:** punkt ekranu → układ mapy (odwrócona macierz) → filtr po prostokątach otaczających → `Path.contains`. Gdy brak trafienia: najbliższy kraj w promieniu 16 dp (próbkowanie kilku punktów na okręgu wystarczy). Znaczniki małych krajów mają pierwszeństwo.
- **Klocki układanki:** ten sam `Path` kraju rysowany w osobnym małym `CustomPaint` z cieniem; pozycja docelowa = pozycja kraju w układzie mapy; „wskoczenie” przy odległości poniżej progu zależnego od skali.
- **Wydajność:** cel 60 kl./s na telefonie średniej klasy z całym światem na ekranie. Mierzyć w trybie `--profile` na fizycznym urządzeniu już w etapie 0; jeśli baza maluje się za wolno, zapisać ją do `ui.Picture`/obrazu i odświeżać tylko przy zmianie postępu.

API widżetu (jedno dla wszystkich trybów):

```dart
GeoMap(
  view: GeoView.europe,
  styleOf: (code) => CountryStyle(...),   // kolor/stan z postępu i trybu
  highlighted: {'fr'},
  showLabels: false,
  onCountryTap: (code) { ... },
  controller: mapController,              // focusOn(code), focusOnRegion(codes)
)
```

## 7. Silnik gry (czysty Dart)

Jedna pętla rundy dla wszystkich trybów; tryby różnią się tylko typem pytania i widżetem, który je rysuje.

```dart
enum Skill { location, shape, flag, capital }
enum Lang { pl, en }

sealed class Question {
  String get countryCode;
  Skill get skill;
  Lang get promptLang;      // język polecenia; inny niż interfejsu = pytanie „ze słuchu”
  bool get audioOnly;       // true: polecenie bez tekstu
}
class TapOnMapQuestion extends Question { ... }      // Gdzie to jest?, stolica → kraj
class ChoiceQuestion extends Question { ... }        // flaga/stolica z 3–4 opcji
class PlacePiecesQuestion extends Question { ... }   // Układanka granic
class NeighborsQuestion extends Question { ... }     // Sąsiedzi
// etap 2: PaintFlagQuestion, TraceBorderQuestion, RouteQuestion, ShadowQuestion

class GameSession {
  GameSession({required this.seed, required this.questions, required this.playerIds});
  // apply(Answer) → nowy GameSession; wynik zależy wyłącznie od wejścia
}
```

- `question_factory.dart`: z postępu profilu, trybu i ziarna losowości (`Random(seed)`) buduje listę pytań. Wyprawa dnia = zaległe powtórki + nowe kraje według kolejności „od domu na zewnątrz” (odległość w grafie sąsiedztwa od mojego kraju).
- **Tryb „Posłuchaj po angielsku”** nie ma własnego typu pytania: to `TapOnMapQuestion` / `ChoiceQuestion` z `promptLang` = drugi język i `audioOnly = true`. Fabryka ustawia tak część pytań w Wyprawie dnia dla par na poziomie 3+, gdy drugi język jest włączony. Wynik liczy się do `skill` pytania; osobnego postępu językowego nie zapisujemy.
- `distractors.dart`: błędne opcje — dla flag z `similarFlags`, dla stolic i położenia z sąsiadów i tego samego kontynentu; poziom opanowania decyduje o liczbie i podobieństwie.
- `leitner.dart`: poziomy 0–5 i odstępy 0/1/3/7/21 dni (tabela w dokumencie 01); funkcje `promote`, `demote`, `isDue`.
- **Determinizm** (ta sama lista pytań dla tego samego ziarna i ta sama punktacja dla tych samych odpowiedzi) jest jedynym przygotowaniem pod multiplayer wykonywanym teraz. `playerIds` ma w grze solo jeden element. Żadnych warstw sieciowych na zapas.
- Czas przekazywany z zewnątrz (`DateTime now` jako parametr), żeby testy powtórek nie zależały od zegara.

W UI: `RoundScreen` dobiera widżet przez `switch` po typie pytania (`sealed` wymusza obsłużenie wszystkich typów).

## 8. Zapis danych

`shared_preferences`, jeden wpis JSON na profil + wpis z listą profili i ustawieniami.

```json
{
  "id": "p1", "name": "Ola", "avatar": 3, "home": "pl",
  "lang": "pl", "secondLang": true, "readAloud": true,
  "streak": {"days": 3, "last": "2026-11-19"},
  "mastery": { "fr": {"location": [3, "2026-11-22"], "flag": [1, "2026-11-19"]} },
  "badges": ["my_borders"], "schema": 1
}
```

- 197 krajów × 4 umiejętności to kilkanaście kB — baza danych nie jest potrzebna. Zapis po każdej rundzie (i po każdej odpowiedzi w Wyprawie dnia), nie po każdym stuknięciu.
- Pole `schema` + funkcja migracji przy odczycie od pierwszej wersji.
- Uszkodzony wpis nie może wyzerować postępów po cichu: przy błędzie odczytu zachować surową kopię pod osobnym kluczem i pokazać informację w strefie rodzica.
- Przejście na bazę (np. `drift`) dopiero, gdy pojawi się synchronizacja między urządzeniami.

## 9. Lokalizacja i dwa języki

Dwa niezależne pojęcia, których nie wolno mieszać w kodzie:

| Pojęcie | Skąd | Steruje |
|---|---|---|
| **Język interfejsu** | `lang` aktywnego profilu → `MaterialApp.locale` | teksty ARB, nazwy wyświetlane, polecenia lektora |
| **Drugi język** | „ten drugi” z pary pl/en, gdy `secondLang = true` | dodatkowy lektor nazw, pytania ze słuchu, drugi podpis na karcie i pieczątce |

- Interfejs: `flutter_localizations` + `gen-l10n`, pliki `lib/l10n/app_pl.arb` i `app_en.arb`. Angielski jest językiem szablonu (klucze i opisy po angielsku), oba tłumaczenia powstają równolegle od pierwszego ekranu — żadnych tekstów wpisanych na sztywno w widżetach.
- Zmiana języka profilu przełącza `locale` bez restartu aplikacji.
- Treści geograficzne: `GeoRepository` ładuje **oba** pliki `geo_pl.json` i `geo_en.json` naraz (są małe) i udostępnia `name(code, lang)`, `capital(code, lang)`, `hook(code, lang)`.
- Polecenia budować z pełnych zdań w ARB z parametrem w odpowiednim przypadku. Polska odmiana („Pokaż **Francję**”, „stolica **Francji**”) wymaga pól `nameAcc` i `nameGen` w `geo_pl.json` — nie da się jej wygenerować automatycznie. Angielski korzysta z samego `name`; uwaga na rodzajnik („the Netherlands”, „the United Kingdom”) — pole opcjonalne `nameInSentence` w `geo_en.json`.
- Dodanie trzeciego języka = nowy plik ARB + nowy `geo_<język>.json`; wtedy „drugi język” staje się wyborem z listy zamiast przełącznika.

## 10. Dźwięk i lektor

- `SpeechService` na `flutter_tts` (systemowa synteza mowy, offline). Jedno wejście dla całej aplikacji:

```dart
Future<void> say(String text, Lang lang);
Future<void> sayCountry(String code, Lang lang);
Future<void> sayCapital(String code, Lang lang);
Future<void> sayBoth(String code, {required Lang first});  // „Niemcy … Germany”
Future<void> stop();
```

- **Język ustawiany przy każdej wypowiedzi** (`pl-PL` / `en-GB`), bo w jednej sekwencji padają oba. Wypowiedzi kolejkowane; nowe polecenie przerywa poprzednie. `sayBoth` czeka na zakończenie pierwszej wypowiedzi, robi pauzę ok. 400 ms i mówi drugą.
- **Nazwy zawsze czyta głos ich języka:** „Germany” głosem angielskim, „Niemcy” polskim. Nigdy nie podawać angielskiej nazwy polskiemu głosowi — to właśnie zniszczyłoby naukę wymowy.
- Angielski: preferować `en-GB`, zapasowo `en-US` (jedna stała w kodzie). Tempo mowy nieco wolniejsze niż domyślne.
- Przy starcie serwis sprawdza dostępność głosów dla obu języków. Brak głosu polskiego lub angielskiego → funkcje tego języka są ukryte, a strefa rodzica pokazuje instrukcję instalacji głosu w ustawieniach systemu. Aplikacja działa dalej.
- **Ryzyko jakości:** systemowe głosy różnie wymawiają nazwy własne i różnią się między urządzeniami. W etapie 0 przesłuchać pełną listę nazw na Androidzie i iOS. Ponieważ całe wywołanie przechodzi przez `sayCountry`/`sayCapital`, podmiana syntezy na nagrane pliki (`assets/audio/names/en/fr.mp3`) nie wymaga zmian w UI — decyzja w dokumencie 04.
- `SfxService` na `audioplayers`: krótkie efekty wczytane z wyprzedzeniem, tryb niskich opóźnień.
- Wibracja: `HapticFeedback` z SDK, bez dodatkowego pakietu.

## 11. Interfejs i motyw

- Tokeny (kolory, promienie, odstępy, czasy animacji, style pisma) w `ui/core/theme.dart` jako stałe klasy `Tok`; widżety nie zawierają surowych wartości. Jest jeden motyw, więc `ThemeExtension` nie jest potrzebny.
- Kilka własnych widżetów bazowych zamiast biblioteki komponentów: `AppButton` (obrys 3 dp, odwrócenie barw przy dotyku, dźwięk, min. 64 dp), `AppPanel`, `SpeakerButton` (żółty, z etykietą języka), `MapLegend` (objaśnienia stanów + postęp rundy), `BorderRibbon` (wstęga kraju w powiększeniu na karcie i w paszporcie). Bez cieni i gradientów (dokument 02).
- Animacje: wbudowane widżety niejawne (`AnimatedScale`, `AnimatedSlide`, `TweenAnimationBuilder`) i `AnimationController` tam, gdzie trzeba sekwencji. Pakiet `flutter_animate` dopuszczalny, jeśli kaskady i sekwencje zaczną zaśmiecać kod. Konfetti: własny prosty `CustomPainter` z cząsteczkami.
- Maskotka (bocian, dokument 02): widżet `Mascot` z własnym `CustomPainter` i stanem (`idle`, `talking`, `happy`, `pointing`, `waving`); `talking` sterowany przez `SpeechService`. Bez pakietów animacji.
- Flagi: `flutter_svg`. Jeśli lista flag będzie przycinać przy przewijaniu, przejść na prekompilację (`vector_graphics_compiler`).
- Skalowanie: układ liczony od wysokości ekranu (orientacja pozioma). Jeden próg: szerokość ≥ 900 dp → szersze panele boczne i większa karta kraju. Uwzględnić `SafeArea` (wycięcia ekranu po bokach).
- Teksty nazw mogą łamać się na dwie linie; żadnych stałych szerokości dobranych pod jeden język.
- Dostępność: `Semantics` z etykietą na elementach sterujących; `MediaQuery.disableAnimations` wyłącza ruch dekoracyjny; skala tekstu ograniczona do 1,3.

## 12. Pakiety

| Pakiet | Po co |
|---|---|
| `flutter_riverpod` | stan |
| `go_router` | nawigacja |
| `shared_preferences` | zapis profili i postępu |
| `flutter_svg` | flagi |
| `flutter_tts` | lektor w dwóch językach |
| `audioplayers` | efekty dźwiękowe (`SfxService`, pula odtwarzaczy na dźwięk, miksowanie z lektorem) |
| `flutter_localizations`, `intl` | lokalizacja |

Każdy kolejny pakiet wymaga uzasadnienia, że kilkadziesiąt linii własnego kodu nie wystarczy. Świadomie pominięte: pakiety mapowe, `freezed`, `build_runner`, bazy danych, analityka, SDK reklamowe, `google_fonts` (pobiera z sieci — czcionki dołączamy jako zasoby).

## 13. Testy

| Poziom | Co |
|---|---|
| Jednostkowe (`domain/`) | Leitner (awans, spadek, terminy); fabryka pytań (determinizm dla ziarna, brak powtórzeń, kolejność od mojego kraju, pytania w drugim języku tylko dla par na poziomie 3+ i tylko gdy włączony); dystraktory (poprawna odpowiedź zawsze obecna, brak duplikatów); punktacja `GameSession` |
| Spójność danych | test wczytujący prawdziwe zasoby: każdy kraj ma geometrię, flagę, stolicę, nazwy w obu językach (polskie z `nameAcc` i `nameGen`); sąsiedztwo symetryczne; sąsiedzi mają różne kolory; oba pliki ARB mają te same klucze |
| Widżety | po jednym teście na typ pytania: dobra i zła odpowiedź zmieniają stan; trafianie dotyku w `GeoMap` dla kraju dużego, małego i punktu w morzu; ekran startowy renderuje się w obu językach bez przepełnień |
| Ręczne | wydajność mapy na fizycznym telefonie i tablecie; odsłuch nazw w obu językach; sesje z dziećmi (dokument 04) |

Test spójności danych jest najważniejszy — większość błędów w takiej aplikacji to błędy w danych, nie w kodzie.

## 14. Prywatność i wymagania sklepów

- Aplikacja skierowana do dzieci: programy Google Play „Families” i kategoria „Kids” w App Store. Zakaz reklam behawioralnych i zewnętrznej analityki; linki zewnętrzne i zakupy tylko za bramką rodzica.
- Dane osobowe: nie zbieramy. Imię/pseudonim profilu zostaje na urządzeniu.
- Deklaracje prywatności w sklepach: „dane nie są zbierane” — prawdziwe, dopóki nie ma etapu 3.
- Multiplayer online zmienia ten stan: pojawia się anonimowy identyfikator gracza na serwerze (dokument 04).

## 15. Kolejność pierwszych kroków

1. `flutter create` w katalogu repozytorium, blokada orientacji, motyw z tokenami, czcionki, `gen-l10n` z oboma plikami ARB.
2. `tool/build_geo.dart` dla samej Europy → zasoby + test spójności danych.
3. `GeoMap`: rysowanie, przybliżanie, trafianie dotyku — pomiar wydajności na urządzeniu.
4. `SpeechService`: odsłuch nazw po polsku i angielsku na obu platformach.
5. Dopiero potem logika gry i ekrany (plan w dokumencie 04).
