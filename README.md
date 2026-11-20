# EuLearn

Aplikacja mobilna (Flutter, Android + iOS) dla dzieci 6–10 lat do nauki mapy: położenie krajów, granice i sąsiedzi, flagi, stolice. Polski i angielski; nazwy krajów i stolic czytane w obu językach.

Dokumentacja projektowa: [docs/](docs/README.md).

## Uruchomienie

```sh
flutter pub get
flutter run            # telefon lub tablet, orientacja pozioma
```

## Testy

```sh
flutter analyze
flutter test                                   # logika, dane, ekrany
flutter test --update-goldens test/app_test.dart   # odświeża zrzuty ekranów w test/goldens/
```

## Dane mapy

Geometria, sąsiedztwo i barwy krajów są generowane z Natural Earth:

```sh
dart run tool/build_geo.dart    # wymaga Node (npx mapshaper); pisze do assets/geo/
```

Ręcznie utrzymywane: `tool/overrides.json` (lista krajów, wyjątki, podobne flagi) oraz `assets/i18n/geo_pl.json` i `geo_en.json` (nazwy, odmiana, stolice, skojarzenia).

## Dźwięki

Efekty są syntezowane, bez zewnętrznych plików i licencji:

```sh
python3 tool/build_sfx.py       # pisze do assets/audio/sfx/
```

## Głos lektora

Bez nagrań aplikacja czyta systemowym syntezatorem telefonu. Nagrania wszystkich zdań (855 krótkich klipów, PL i EN) robi skrypt korzystający z API mowy OpenAI:

```sh
export OPENAI_API_KEY=...
python3 tool/build_voice.py --sample    # kilkanaście klipów na próbę
python3 tool/build_voice.py             # reszta; można przerywać i wznawiać
flutter test                            # sprawdza, że każde zdanie ma nagranie
```

Głos i model: zmienne `VOICE_PL`, `VOICE_EN`, `VOICE_MODEL`. Zdanie bez nagrania (np. po zmianie tekstu) jest czytane syntezatorem.

## Licencje danych

Natural Earth (domena publiczna), flag-icons (MIT), czcionki Andika i Sofia Sans Semi Condensed (OFL).
