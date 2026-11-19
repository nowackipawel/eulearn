# Product

<!-- impeccable:product-schema 1 -->

## Platform

adaptive

## Stack

Flutter (Android + iOS), wybrany przez właściciela produktu. Jeden własny język wizualny na obu systemach — aplikacja nie naśladuje natywnych kontrolek iOS ani Androida, ale respektuje zachowania systemowe (bezpieczne obszary, gest „wstecz”, ustawienia dostępności). Szczegóły techniczne: `docs/03-zalecenia-flutter.md`.

## Users

- **Dziecko 6–10 lat** (użytkownik główny). Młodsze dzieci są bystre, ale mogą jeszcze nie czytać płynnie. Gra w krótkich sesjach, najczęściej samo w domu, czasem z rodzicem obok, czasem w szkole lub na zajęciach.
- **Rodzic** — ustawia profil, sprawdza postępy, włącza grę online. Korzysta ze strefy rodzica za bramką.
- **Nauczyciel** — używa aplikacji z kilkorgiem dzieci na zajęciach; nie ma osobnej roli w aplikacji (potwierdzona sytuacja użycia, nie funkcja).

Urządzenia: tablet i telefon w równym stopniu.

## Product Purpose

Nauczyć dziecko mapy świata: gdzie leży każdy kraj, jak wygląda i z kim graniczy, jaką ma flagę i stolicę. Sukces: po kilku tygodniach zabawy po 5–10 minut dziennie dziecko wskazuje na pustej mapie swój kraj i wszystkich jego sąsiadów oraz rozpoznaje kraje swojego kontynentu; potem rozszerza to na cały świat. Przy okazji osłuchuje się z angielską wymową nazw krajów i stolic.

## Positioning

Nauka zaczyna się od „mojego kraju”, który dziecko samo zaznacza, i rozchodzi się na zewnątrz po granicach: mój kraj → sąsiedzi → kontynent → świat. Ten sam kraj wraca na kilka sposobów (wskazywanie, układanie kształtów, kolorowanie flagi, słuchanie), a mapa — nie lista ani quiz — jest głównym miejscem zabawy.

## Operating Context

- Sesje 2–4 minuty (runda 6–10 pytań); codzienna „Wyprawa dnia” złożona z powtórek.
- Dom: dziecko samo, aplikacja prowadzi głosem. Z rodzicem: wspólna zabawa. Szkoła: kilkoro dzieci, często jedno urządzenie na grupę lub tablety szkolne.
- Solo działa w pełni offline. Sieć potrzebna tylko w grze online.
- Lektor czyta każde polecenie i nazwę; nazwy także po angielsku.

## Capabilities and Constraints

- Tryby nauki, powtórki w odstępach, paszport z pieczątkami, profile dzieci, strefa rodzica: `docs/01-koncepcja-i-tryby-nauki.md`.
- Języki od pierwszej wersji: polski i angielski (interfejs do wyboru; drugi język jako lektor nazw).
- Orientacja pozioma, zablokowana.
- Zakres treści: 197 krajów; pierwsza wersja obejmuje Europę.
- Multiplayer: od razu online (pokój na kod, losowy przeciwnik). W pokoju nie ma żadnego kanału rozmowy — brak czatu, pseudonimy losowane, reakcje z gotowego zestawu.
- Aplikacja dla dzieci: bez reklam, bez analityki behawioralnej, bez linków zewnętrznych poza strefą rodzica.
- Nierozstrzygnięte: model biznesowy; ostateczna nazwa; lektor z syntezy czy nagrań; sposób pokazania terytoriów spornych (`docs/04-plan-wdrozenia-i-multiplayer.md`).

## Brand Commitments

Nic nie jest przesądzone. „EuLearn” to nazwa robocza. Aplikacja ma maskotkę-przewodnika (wymóg właściciela produktu); jej projekt powstaje w ramach prac. Nie ma logo ani gotowych grafik.

## Evidence on Hand

- Dokumenty projektowe w `docs/`.
- Dane, które będą prawdziwe w aplikacji: kształty krajów (Natural Earth), flagi (zestaw SVG), nazwy krajów i stolic w dwóch językach.
- Brak: ilustracji, maskotki, nagrań lektora, zrzutów ekranu, opinii użytkowników, wyników testów z dziećmi. Nie wolno ich zmyślać.

## Product Principles

1. Od mojego domu na zewnątrz — każdy nowy kraj jest zaczepiony o już znany.
2. Mapa jest bohaterem — interfejs jej nie zasłania i nie zastępuje.
3. Błąd to podpowiedź, nie kara — bez żyć, bez utraty postępów.
4. Aplikacja mówi — dziecko, które nie czyta, robi wszystko samo.
5. Bezpieczeństwo przez brak kanałów — nic, co dziecko wpisze, nie trafia do innego gracza.

## Accessibility & Inclusion

- Część użytkowników nie czyta: każde polecenie i każda odpowiedź ma głos; żadna informacja tylko w tekście.
- Niedokładna motoryka: cele dotyku min. 64 dp, tolerancja stuknięcia na mapie, alternatywa dla przeciągania.
- Kolor nigdy nie jest jedynym nośnikiem informacji (flagi i mapa to z natury treść kolorowa — pytania o flagi nie mogą opierać się wyłącznie na odróżnieniu podobnych barw bez drugiej wskazówki).
- Respektowanie systemowego ograniczenia ruchu i powiększenia tekstu.
