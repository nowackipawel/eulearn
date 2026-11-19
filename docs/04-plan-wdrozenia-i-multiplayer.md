# 04 — Plan wdrożenia i multiplayer

Etapy są uporządkowane według ryzyka: najpierw to, co może się nie udać (mapa, dane, lektor), potem to, co jest pewne (ekrany). Każdy etap kończy się czymś, co można dać dziecku do ręki.

## Etap 0 — Dowód techniczny

Cel: potwierdzić trzy ryzykowne założenia, zanim powstanie jakikolwiek ekran gry.

| Zadanie | Kryterium ukończenia |
|---|---|
| Szkielet projektu: `flutter create`, orientacja, motyw, czcionki, ARB pl/en | aplikacja startuje na Androidzie i iOS, przełącza język |
| Potok danych dla Europy (`tool/build_geo.dart`) | zasoby wygenerowane, test spójności danych przechodzi |
| `GeoMap`: rysowanie, przybliżanie, trafianie dotyku, małe kraje | 60 kl./s na telefonie średniej klasy; stuknięcie w Luksemburg i Maltę działa |
| Ten sam widżet z widokiem świata | płynność zmierzona; decyzja, czy potrzebne buforowanie warstwy bazowej |
| `SpeechService` w dwóch językach | odsłuchana pełna lista nazw Europy po polsku i angielsku na obu platformach; spisane nazwy wymawiane źle |

Wynik etapu: decyzja „synteza czy nagrania” (decyzje otwarte, punkt 2).

## Etap 1 — MVP: Europa

Zakres:

- pierwsze uruchomienie: język → profil → mój kraj → mini-runda o moim kraju;
- tryby 1–8 z dokumentu 01: Odkrywca, Gdzie to jest?, Układanka granic, Czyja to flaga?, Stolice, Sąsiedzi, Posłuchaj po angielsku, Wyprawa dnia;
- ścieżka „mój kraj → sąsiedzi → kontynent”, odznaka „Znam swoje granice” (bez obrysowywania);
- powtórki Leitnera, podpowiedzi, gwiazdki;
- paszport ze stroną Europy;
- polski i angielski interfejs, drugi język na karcie kraju i po dobrej odpowiedzi;
- profile (do 4), strefa rodzica: postępy, ustawienia, reset;
- zapis lokalny, pełne działanie offline.

Kolejność budowy:

1. `domain/`: modele, Leitner, fabryka pytań, dystraktory — z testami.
2. Szkielet rundy + `TapOnMapQuestion` (tryb „Gdzie to jest?”) — pierwsza grywalna pętla.
3. `ChoiceQuestion` (flagi, stolice), następnie warianty ze słuchu w drugim języku.
4. Odkrywca z kartą kraju.
5. `PlacePiecesQuestion` (układanka) i `NeighborsQuestion`.
6. Profile, pierwsze uruchomienie, mój kraj.
7. Wyprawa dnia, paszport, ekran wyniku.
8. Strefa rodzica, dźwięki, dopracowanie animacji.

Kryterium ukończenia: test z 5–8 dziećmi w wieku 6–10 lat (sekcja „Testy z dziećmi”). Poza zakresem: reszta świata, tryby kreatywne, multiplayer, konta, synchronizacja.

## Etap 2 — Cały świat i tryby kreatywne

- pozostałe kontynenty: dane, widoki, strony paszportu; widok świata jako ekran wyboru kontynentu;
- skojarzenia dla krajów spoza Europy (praca redakcyjna w dwóch językach — planować równolegle z etapem 1);
- tryby 9–13: Malarz flag, Rysuję granicę, Podróż, Cień, Memory;
- wyzwanie „na czas” dla zaawansowanych;
- nagrania lektora zamiast syntezy, jeśli tak zdecydowano po etapie 0;
- publikacja w sklepach (jeśli nie nastąpiła po etapie 1).

Tryby kreatywne są od siebie niezależne — można je wydawać pojedynczo, w kolejności wynikającej z testów z dziećmi.

## Etap 3 — Multiplayer online

Multiplayer powstaje od razu jako gra online — bez osobnego etapu gry lokalnej. Rozgrywka solo nadal nie wymaga sieci; sieć jest potrzebna tylko po wejściu do pokoju.

### Bezpieczeństwo: brak kanału rozmowy

Założenie: **w pokoju nie da się rozmawiać**, więc nie ma kontaktu dziecka z obcą osobą. Żeby to założenie było prawdziwe, żaden element gry nie może przenosić dowolnej treści między graczami:

| Element | Zasada |
|---|---|
| Czat tekstowy, głosowy, obraz | nie istnieje |
| Reakcje | tylko gotowy zestaw (kilka min bociana) |
| Pseudonim | losowany z list („Wesoły Lis”), nie wpisywany — wpisywany pseudonim to czat w przebraniu |
| Awatar | z zestawu; bez zdjęć |
| Nazwa pokoju | brak; pokój ma tylko kod |
| Co widzi przeciwnik | pseudonim, awatar, flagę „mojego kraju”, punkty |

Przy tych zasadach bezpieczne są oba sposoby łączenia graczy:

- **pokój na kod** (5 znaków lub 3 obrazki) albo link — gra ze znajomymi i rodziną;
- **szybka gra z losowym przeciwnikiem** — możliwa właśnie dlatego, że nie ma jak się porozumieć.

Pozostaje jedna rzecz, której brak czatu nie rozwiązuje: **dane**. Gra online wymaga identyfikatora urządzenia/gracza na serwerze, a to zmienia deklarację „nie zbieramy danych” w sklepach. Ograniczenie: logowanie anonimowe, na serwerze tylko identyfikator, pseudonim i wynik, pokoje usuwane po grze, włączenie gry online przełącznikiem w strefie rodzica. Przed publikacją sprawdzić wymagania sklepów dla aplikacji dziecięcych z funkcją online (Google Play Families, App Store Kids).

### Architektura

- **Supabase**: logowanie anonimowe, kanały Realtime dla pokoju (obecność graczy + rozgłaszanie zdarzeń), jedna mała tabela pokoi. Jedna usługa zamiast własnego serwera.
- **Przebieg gry:** gospodarz tworzy pokój → serwer zapisuje ziarno losowości i ustawienia → każdy klient buduje tę samą listę pytań lokalnie (determinizm z dokumentu 03) → klienci wysyłają tylko zdarzenia odpowiedzi (numer pytania, odpowiedź, czas) → wynik liczy ten sam kod `GameSession`.
- **Rozstrzyganie:** każdy klient liczy wynik z tych samych zdarzeń. Rozstrzyganie po stronie serwera (funkcja brzegowa uruchamiająca kod `domain/`) dodać dopiero przy rankingach lub turniejach, gdy oszukiwanie zacznie mieć znaczenie.
- **Losowy przeciwnik:** kolejka oczekujących w tabeli; pierwszy wolny gracz z tym samym zakresem (np. Europa) trafia do pokoju. Gdy nikt nie czeka dłużej niż kilkanaście sekund — propozycja gry solo.
- **Zerwanie połączenia:** gracz może wrócić do pokoju w trakcie; po przekroczeniu limitu czasu gra toczy się bez niego.
- **Zmiany w aplikacji:** nowa funkcja `ui/features/multiplayer/`, nowe repozytorium `RoomRepository`, trasa `/room/:code`, pakiet `supabase_flutter`. Reszta kodu bez zmian.

### Tryby

| Tryb | Opis |
|---|---|
| **Wyścig** | 2–4 graczy, te same pytania w tej samej kolejności; punkt za poprawną odpowiedź, premia za pierwszą. Czas odpowiedzi mierzony lokalnie, żeby opóźnienia sieci nie decydowały o wyniku. |
| **Wspólna układanka** | gracze razem układają kontynent na czas; każdy widzi klocki wkładane przez innych. Współpraca, bez przegranych. |
| **Kto zna sąsiadów?** | na zmianę po jednym sąsiedzie wskazanego kraju; kto się pomyli, odpada z rundy. |

Wyrównanie szans: pytania dobierane z krajów, które znają wszyscy gracze w pokoju (część wspólna poznanych krajów), a gdy jest pusta — z poziomu kontynentu gospodarza.

Później, jeśli będzie potrzeba: gra kilku osób przy jednym urządzeniu, synchronizacja postępów między urządzeniami (konto rodzica), tryb klasowy dla nauczycieli.

## Testy z dziećmi

Po etapie 1 i po każdym nowym trybie: 5–8 dzieci, w tym co najmniej dwoje sześciolatków i dwoje dziesięciolatków, po 15 minut, bez instrukcji od dorosłego.

Obserwować:

- czy dziecko samo przejdzie pierwsze uruchomienie i znajdzie swój kraj;
- gdzie stuka obok celu (rozmiary, małe kraje);
- czy rozumie polecenia lektora i czy używa przycisku powtórzenia;
- reakcję na błąd (zniechęcenie czy ponowna próba);
- w grze online: czy rozumie, że gra z innym dzieckiem, i czy przegrana nie zniechęca;
- czy powtarza na głos angielskie nazwy, czy je ignoruje;
- czy po rundzie chce następną;
- po tygodniu: ile krajów wskaże na pustej mapie bez aplikacji.

## Ryzyka

| Ryzyko | Skutek | Ograniczenie |
|---|---|---|
| Płynność mapy świata na słabszych telefonach | zacinanie przy przybliżaniu | pomiar w etapie 0; mocniejsze uproszczenie geometrii; buforowanie warstwy bazowej |
| Jakość syntezy mowy (nazwy własne, różnice między urządzeniami, brak głosu) | zła wymowa podważa cel językowy | odsłuch w etapie 0; możliwość podmiany na nagrania bez zmian w UI |
| Małe kraje i wyspy nie do trafienia palcem | frustracja | znaczniki, automatyczne przybliżenie, tolerancja stuknięcia |
| Terytoria sporne | odrzucenie w sklepie w części krajów, skargi | jawna decyzja (niżej), ewentualnie wariant danych na region |
| Błędy w danych (stolice, sąsiedzi, odmiana nazw) | uczenie błędów | test spójności, ręczny przegląd przez drugą osobę, plik poprawek |
| Rozrost zakresu (13 trybów) | MVP nie powstaje | MVP = 8 trybów, z czego 2 nie wymagają nowej mechaniki; kreatywne pojedynczo |
| Praca redakcyjna (skojarzenia × 197 krajów × 2 języki) | wąskie gardło | Europa w etapie 1; brak skojarzenia nie blokuje kraju |
| Gra online zmienia deklarację prywatności w sklepach | opóźnienie publikacji etapu 3 | brak kanału rozmowy, logowanie anonimowe, minimum danych; sprawdzenie wymagań sklepów przed publikacją |

## Decyzje otwarte

Każda ma zalecenie, które obowiązuje, dopóki właściciel produktu nie zdecyduje inaczej.

| # | Decyzja | Zalecenie |
|---|---|---|
| 1 | Terytoria sporne (Kosowo, Tajwan, Palestyna, Sahara Zachodnia, Krym) | granice według domyślnego wariantu Natural Earth; 197 krajów jak w dokumencie 01; Sahara Zachodnia widoczna, ale bez pytań; przegląd przed publikacją w sklepach poza UE |
| 2 | Lektor: synteza systemowa czy nagrania | MVP na syntezie; po odsłuchu w etapie 0 zdecydować o nagraniach nazw (ok. 400 krótkich plików na język) — w pierwszej kolejności dla angielskiego, bo tam wymowa jest celem nauki |
| 3 | Odmiana angielska: brytyjska czy amerykańska | `en-GB` (bliżej szkolnego angielskiego w Polsce), zapasowo `en-US` |
| 4 | Model biznesowy | nie przesądzać teraz; zgodne z zasadami: jednorazowy zakup lub odblokowanie kolejnych kontynentów w strefie rodzica. Bez reklam i subskrypcji kierowanych do dziecka. |
| 5 | Maskotka | jest w MVP: bocian rysowany w kodzie (dokument 02). Do decyzji: imię bociana i ewentualne dopracowanie przez ilustratora |
| 6 | Nazwa i identyfikator aplikacji w sklepach | „EuLearn” sugeruje Europę — zdecydować przed etapem 2, czy nazwa zostaje przy zasięgu światowym |
| 7 | Trzeci język i kolejne | po etapie 2; struktura danych jest na to gotowa (dokument 03, sekcja 9) |
