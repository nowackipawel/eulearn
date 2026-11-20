"""Records every phrase the narrator can say, using the OpenAI speech API.

    export OPENAI_API_KEY=...
    python3 tool/build_voice.py --dry-run     # count phrases and characters, no network
    python3 tool/build_voice.py --sample      # a handful of clips to judge the voice
    python3 tool/build_voice.py               # everything missing (safe to re-run)

Options via environment: VOICE_MODEL (default gpt-4o-mini-tts), VOICE_PL and
VOICE_EN (default coral). Delete assets/audio/voice/<lang>/ to re-record.

Phrases are built from the same sources as the app (ARB templates + geo
content), and each clip is named by a hash of its text. The app plays a clip
when one exists for the exact text and falls back to system speech otherwise,
so a changed sentence is never spoken with a stale recording.
Only country names and game sentences are sent to the API.
"""
import json, os, sys, time, urllib.request, urllib.error

ROOT = 'assets/audio/voice'
MODEL = os.environ.get('VOICE_MODEL', 'gpt-4o-mini-tts')
VOICE = {'pl': os.environ.get('VOICE_PL', 'coral'), 'en': os.environ.get('VOICE_EN', 'coral')}
STYLE = {
    'pl': 'Mów po polsku, naturalnie i wyraźnie, ciepłym głosem i spokojnym tempem, '
          'jak lektorka czytająca dzieciom w wieku 6–10 lat. Nazwy krajów i miast wymawiaj starannie.',
    'en': 'Speak clear British English in a warm, unhurried voice, for children aged 6 to 10 who are '
          'learning English. Pronounce country and city names carefully.',
}
# Sentences with one country name in them: (ARB key, which form of the name).
PER_COUNTRY = [('promptFind', 'acc'), ('promptCapitalOf', 'gen'), ('promptPickFlag', 'gen'),
               ('promptNeighbors', 'name'), ('promptWhereCapital', 'capital'),
               ('thisIs', 'name'), ('capitalIs', 'capital')]
FIXED = ['promptWhoseFlag', 'promptPuzzle', 'promptListen', 'wellDone', 'whereDoYouLive', 'meetFirst',
         'legendHome', 'legendKnown', 'legendLearning', 'legendNew']


def key(lang, text):
    """FNV-1a 64-bit of "lang|text"; must match voiceKey() in speech_service.dart."""
    h = 0xcbf29ce484222325
    for b in f'{lang}|{text}'.encode('utf-8'):
        h = ((h ^ b) * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF
    return f'{h:016x}'


def phrases(lang):
    arb = json.load(open(f'lib/l10n/app_{lang}.arb', encoding='utf-8'))
    geo = json.load(open(f'assets/i18n/geo_{lang}.json', encoding='utf-8'))
    out = [arb[k] for k in FIXED]
    for c in geo.values():
        sentence = c.get('nameInSentence', c['name'])
        forms = {'name': c['name'], 'capital': c['capital'],
                 'acc': c.get('nameAcc', sentence), 'gen': c.get('nameGen', sentence)}
        out += [c['name'], c['capital']]
        if 'hook' in c:
            out.append(c['hook'])
        for k, form in PER_COUNTRY:
            placeholder = 'capital' if form == 'capital' else 'name'
            out.append(arb[k].replace('{%s}' % placeholder, forms[form]))
    return list(dict.fromkeys(out))  # unique, order kept


def record(lang, text, path):
    body = json.dumps({'model': MODEL, 'voice': VOICE[lang], 'input': text,
                       'instructions': STYLE[lang], 'response_format': 'mp3'}).encode()
    req = urllib.request.Request('https://api.openai.com/v1/audio/speech', data=body, headers={
        'Authorization': 'Bearer ' + os.environ['OPENAI_API_KEY'], 'Content-Type': 'application/json'})
    for attempt in range(5):
        try:
            with urllib.request.urlopen(req, timeout=60) as r:
                data = r.read()
            with open(path + '.part', 'wb') as f:
                f.write(data)
            os.replace(path + '.part', path)
            return
        except urllib.error.HTTPError as e:
            if e.code not in (429, 500, 502, 503) or attempt == 4:
                sys.exit(f'API error {e.code}: {e.read().decode()[:300]}')
        except urllib.error.URLError as e:
            if attempt == 4:
                sys.exit(f'network error: {e}')
        time.sleep(2 ** attempt)


def main():
    dry, sample = '--dry-run' in sys.argv, '--sample' in sys.argv
    todo = []
    for lang in ('pl', 'en'):
        ps = phrases(lang)
        if sample:
            ps = ps[:4] + ps[10:22]
        os.makedirs(f'{ROOT}/{lang}', exist_ok=True)
        for t in ps:
            path = f'{ROOT}/{lang}/{key(lang, t)}.mp3'
            if not os.path.exists(path):
                todo.append((lang, t, path))
        print(f'{lang}: {len(ps)} phrases')
    print(f'to record: {len(todo)} clips, {sum(len(t) for _, t, _ in todo)} characters, model {MODEL}')
    if not dry:
        if todo and 'OPENAI_API_KEY' not in os.environ:
            sys.exit('set OPENAI_API_KEY first')
        for i, (lang, t, path) in enumerate(todo, 1):
            record(lang, t, path)
            print(f'{i}/{len(todo)} {lang} {t}')
    # The app reads this list at start to know which texts have a recording.
    index = sorted(f'{lang}/{f[:-4]}' for lang in ('pl', 'en')
                   for f in os.listdir(f'{ROOT}/{lang}') if f.endswith('.mp3'))
    json.dump(index, open(f'{ROOT}/index.json', 'w'))
    print(f'index: {len(index)} clips')


main()
