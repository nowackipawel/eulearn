---
version: 1
slug: "lib-ui-features-round-round-screen-dart"
primary_target: "lib/ui/features/round/round_screen.dart"
related_targets: ["lib/ui/core/map/geo_map.dart"]
---

# Surface: round screen (map question) — and the app shell it sets

Scope: the in-round map screen ("Pokaż Czechy"), landscape, phone and tablet. Mode: Operate. It sets the shell every other screen inherits (Explorer, Passport, Home).
Audience and job: a child aged 6–10, often not yet reading, answers one spoken question by touching the map. Constraints: touch targets 64 dp+, every prompt spoken, colour never the only cue, landscape only.
Memorable moment: the border ribbon of a country closing its loop when the child has learned it.
Unresolved: mascot design; final typeface check for Polish diacritics on device.

## Direction contract

THESIS: The border is the hero. Every country carries a thick ribbon along its border and learning a country draws that ribbon closed. Refuses the pastel, bubbly, mascot-first kids' app with soft shadows.

OWN-WORLD: The school political wall map. Sea-blue ground; flat political tints (yellow, green, orange, violet) each with a deeper same-hue border ribbon; pink with a signal-red ribbon reserved for "my country"; navy ink; white panels with 3 px navy outlines and small radii; no shadows, no gradients. Mastery is a fill pattern: outline, dots, hatching, solid. Country names in spaced capitals, water names in italic.

STORY: The child sees their own country marked in red, hears a question, touches a neighbour, and watches its ribbon grow. They understand that countries are defined by their borders and that the map fills in as they learn.

FIRST VIEWPORT: Map full-bleed on sea blue. Top centre: navy prompt bar with the spoken question and a 56 dp yellow speaker button. Top left: 64 dp back button. Bottom left: the map legend, a white ruled box that is the only home for progress and state keys. Bottom right: 64 dp zoom buttons. Poland centred, pink with red ribbon and a house mark.

FORM: School political wall map — position 7 of 7 on the grounded list. seed:d17bb65501ddbd07. Raises kept: fill pattern encodes mastery (Labanotation); one fixed control home, states as printed marks (centre-rail setting); a whole continent on one passport sheet (high-density web); label detail changes continuously with zoom (type specimen).

FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance
