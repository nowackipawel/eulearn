"""Synthesises the app's sound effects. Run from the repo root:
    python3 tool/build_sfx.py
Pure tones with a wooden, marimba-like decay: soft, no buzzers. Own work, no
licence to track."""
import math, random, struct, wave

RATE = 44100

def tone(freq, dur, decay=9.0, harm=((1, 1.0), (4, 0.25), (10, 0.06)), attack=0.004):
    n = int(RATE * dur)
    out = []
    for i in range(n):
        t = i / RATE
        env = min(1.0, t / attack) * math.exp(-decay * t)
        out.append(env * sum(a * math.sin(2 * math.pi * freq * h * t) * math.exp(-h * t * 2) for h, a in harm))
    return out

def noise(dur, decay=60.0, seed=1):
    r = random.Random(seed)
    return [(r.random() * 2 - 1) * math.exp(-decay * i / RATE) for i in range(int(RATE * dur))]

def mix(*layers):
    """layers: (samples, start_seconds, gain)"""
    n = max(int(s * RATE) + len(x) for x, s, _ in layers)
    out = [0.0] * n
    for x, s, g in layers:
        o = int(s * RATE)
        for i, v in enumerate(x):
            out[o + i] += v * g
    return out

def save(name, samples, peak=0.8):
    m = max(abs(v) for v in samples) or 1
    fade = int(RATE * 0.01)
    with wave.open(f'assets/audio/sfx/{name}.wav', 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(RATE)
        n = len(samples)
        w.writeframes(b''.join(
            struct.pack('<h', int(v / m * peak * 32767 * min(1.0, (n - i) / fade)))
            for i, v in enumerate(samples)))

C5, E5, G5, C6, E6, G6 = 523.25, 659.25, 783.99, 1046.5, 1318.5, 1568.0

# Button press: one short wooden tick.
save('tap', mix((tone(1046.5, 0.07, decay=45), 0, 1), (noise(0.02, 200), 0, 0.15)), peak=0.45)
# Right answer: two bright rising notes.
save('good', mix((tone(E6, 0.35), 0, 1), (tone(G6, 0.45), 0.11, 1)))
# Wrong answer: two soft low notes going down. Gentle, not a buzzer.
save('miss', mix((tone(329.63, 0.3, decay=11, harm=((1, 1.0), (2, 0.2))), 0, 1),
                 (tone(261.63, 0.4, decay=10, harm=((1, 1.0), (2, 0.2))), 0.13, 1)), peak=0.6)
# Puzzle piece or neighbour lands: a wooden knock.
save('snap', mix((tone(392.0, 0.12, decay=30, harm=((1, 1.0), (2.7, 0.4))), 0, 1), (noise(0.03, 150, 2), 0, 0.35)), peak=0.7)
# Border ribbon grows: a quick run up the chord.
save('ribbon', mix(*[(tone(f, 0.4), i * 0.075, 1) for i, f in enumerate((C5, E5, G5, C6))]))
# Country fully learned: passport stamp thump, then a bright chord.
save('stamp', mix((tone(110.0, 0.18, decay=28, harm=((1, 1.0), (2, 0.5))), 0, 1.4), (noise(0.06, 70, 3), 0, 0.6),
                  (tone(C6, 0.6), 0.16, 0.7), (tone(E6, 0.6), 0.16, 0.6), (tone(G6, 0.6), 0.16, 0.5)))
# Round finished: fanfare.
save('fanfare', mix(*[(tone(f, 0.5), s, 1) for f, s in ((C5, 0), (E5, 0.13), (G5, 0.26))],
                    *[(tone(f, 1.2, decay=4), 0.42, 0.8) for f in (C6, E6, G6)]))
print('ok')
