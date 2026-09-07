# Step 4 — Higgsfield AI Video Ad Prompts

> **These are written against Higgsfield's live model lineup, which I queried directly rather
> than recalled.** Durations, resolutions, aspect ratios and parameter names below are the real
> ones the API currently accepts.

---

## 1. Which model to use

| Model | ID | Duration | Use it for |
|---|---|---|---|
| **Seedance 2.5** ⭐ | `seedance_2_5` | **4–30s** | **The hero ad.** The only model that reaches 30s in one generation |
| Marketing Studio | `marketing_studio_video` | 12–15s | Fast UGC variants with built-in hooks/settings |
| Seedance 2.0 | `seedance_2_0` | 4–15s | 4K product beauty b-roll |
| Genjutsu | `hf_mult_motion_control` | — | Transferring motion from a reference clip |

**Use Seedance 2.5 for the hero.** Marketing Studio caps at 15s, which forces you to cut the
`$100 math` beat — the beat that does the rational justification. Seedance 2.5 at 20s keeps the
full hook → problem → solution → proof → CTA arc intact.

---

## 2. Style: UGC, not polished lifestyle

**Recommendation: UGC-style, with two polished product inserts.**

Reasoning specific to this product:

1. **Pet-owner anxiety about DIY grooming makes tutorial-style content convert.** The buyer's
   real objection isn't "is this a good vacuum," it's "will I mess this up / will my dog hate
   me." Polished advertising doesn't answer that. A person in their own living room does.
2. **The buyer is 35–65 on Facebook.** That demographic has high ad-literacy and low tolerance
   for obvious commercials. UGC reads as recommendation; polished reads as sales.
3. **The core proof is inherently unglamorous** — fur leaving a coat, a bin full of hair. Shot
   glossy, it looks staged. Shot handheld, it looks true.
4. **Polished creative is where you lose to the incumbents.** Neakasa can outspend you on
   production forever. They cannot out-authentic you.

**But** two polished inserts earn their place: the **spec card** (55dB / 12,000Pa) and the
**product hero** at the CTA. Those two shots do the "this is a real brand, not a scam" job that
pure UGC can't, and they're where trust for a $129 purchase gets built.

---

## 3. ⭐ HERO PROMPT — copy-paste

**Model:** Seedance 2.5 · **Duration:** 20s · **Aspect:** 9:16 · **Resolution:** 1080p

```
A 20-second vertical 9:16 user-generated-style social media advertisement filmed on a
modern smartphone, in the visual language of an authentic home video posted by a real dog
owner — not a commercial. Warm, natural, slightly imperfect. Handheld throughout with
subtle organic camera shake; never locked on a tripod. Soft natural daylight from a large
window, camera left, with gentle falloff into a warm domestic interior. Color palette of
warm off-white, deep forest green and soft terracotta. Shot on a phone-grade wide lens,
shallow but not cinematic depth of field, mild sensor grain, realistic skin and fur
texture. No text overlays, no logos, no watermarks, no captions rendered in-frame.

SETTING: A lived-in, sunlit living room mid-morning. Light oak floor, a pale linen sofa
with a soft throw, a low wooden coffee table, a green houseplant near the window. The
room feels genuinely inhabited, not styled for a catalogue.

SUBJECT: A calm, healthy adult Golden Retriever with a thick, well-groomed double coat,
lying relaxed on the floor. A woman in her early forties in a soft cream knit sweater and
jeans kneels beside the dog. Her face is warm, unhurried and un-made-up; she is not
performing for the camera. Her hands are the focus more often than her face.

PRODUCT: A compact matte off-white and deep-green pet grooming vacuum unit with a slim
reinforced hose and a brushed stainless-steel deshedding head. Understated, premium,
modern — closer to a high-end kitchen appliance than a power tool.

SHOT SEQUENCE:

0.0–3.0s — HOOK. Extreme close-up, macro, on the deshedding head moving in one slow pass
across the dog's flank. Thick loose undercoat visibly lifts away from the topcoat and
disappears into the head. The fur moves in soft realistic clumps. The dog does not flinch.
Camera drifts slowly right, following the pass. No dialogue. Only ambient room tone and a
soft low hum.

3.0–6.0s — REVEAL. Smooth handheld pull-back to a medium-wide two-shot revealing the whole
scene: the woman kneeling, the retriever lying completely still and relaxed, one paw
stretched out, eyes half-closed. She glances down at the dog and smiles slightly. Natural
window light rims the dog's coat.

6.0–10.0s — THE PROBLEM. Cut to a warm, close, slightly-off-center handheld shot of the
woman looking just past the camera lens, speaking casually as if to a friend, mid-thought.
Behind her the dog is still relaxed on the floor, softly out of focus. Her expression is
wry and knowing, not scripted.

10.0–13.0s — THE PROOF. Cut to a locked-off but subtly breathing shot of the dog fully
relaxed on its side, entirely undisturbed, with the grooming unit visibly running beside
it. Then a quick cut to a close shot of hands unclipping a large transparent dust bin
densely packed with collected fur, tipping it forward toward the lens.

13.0–16.0s — THE CONTRAST. Cut to a static shot of the pale linen sofa heavily covered in
dog hair in flat window light. Hard cut, identical framing, identical light: the same sofa
completely clean. The cut lands sharply.

16.0–20.0s — RESOLUTION AND CTA. Cut to a slow, smooth push-in on the grooming unit resting
on the wooden coffee table in soft window light, hose neatly coiled, the five brushed-steel
grooming heads arranged beside it. In the softly blurred background the retriever pads into
frame and lies down beside it. The push-in settles and holds on the product, clean and
centered in the lower third of the frame, leaving clear negative space in the upper third
for a text overlay to be added in post.

MOTION AND PACING: Deliberately unhurried. Long enough holds that each shot reads on a
small screen. Cuts land on natural beats. The camera behaves like a real hand holding a
real phone — micro-drift, small settle after each move, never robotic.

AUDIO: Natural room tone throughout. A soft, low, unobtrusive appliance hum during the
grooming shots — noticeably quiet, never a harsh vacuum roar. Faint fabric and fur contact
sounds. A single warm, sparse, acoustic music bed at low level under the whole piece. No
voiceover in the generated audio.

NEGATIVE / AVOID: no on-screen text, no captions, no logos, no watermarks, no brand names,
no distressed or frightened animal, no restraining or gripping the dog, no fast whip pans,
no lens flares, no slow-motion, no color grading toward teal and orange, no studio seamless
white background, no stock-footage gloss, no crowd, no children, no other animals, no
distorted paws or extra limbs, no text artifacts on the product body.
```

### Settings

| Parameter | Value | Why |
|---|---|---|
| `mode` | **`omni_reference`** | Feed a real photo of your unit so the product stays accurate. Use `t2v` only if you have no product photo yet |
| `medias` (role `image_references`) | 1–3 photos of your actual unit | **Do this.** Without it the model invents a plausible-but-wrong product |
| `duration` | `20` | Hook + problem + proof + CTA all fit. 15s cuts the $100 beat |
| `aspect_ratio` | **`9:16`** | Reels/Stories/Feed. Generate 1:1 separately, don't crop |
| `resolution` | **`1080p`** | 720p visibly softens fur detail — and fur detail *is* the proof |
| `generate_audio` | `true` | Room tone sells the "quiet" claim |
| `bitrate_mode` | **`high`** | Fine fur motion is exactly what low bitrate destroys |

### Two practical notes

**1. Generate in segments if 20s comes back inconsistent.** Long single generations can drift.
Reliable fallback: generate **three 7-second clips** (Hook+Reveal / Problem+Proof / Contrast+CTA)
using the same reference images and the same SETTING/SUBJECT/PRODUCT blocks, then cut them
together. You get the same 20s with far more control. Use `video_extension` mode to continue a
clip you like.

**2. AI video and fur.** Macro fur-in-motion is genuinely at the edge of what these models do
cleanly, and the 0–3s macro shot is the single most important frame of your ad. **Strongest
play: shoot the 3-second macro demo yourself on a phone** once your sample unit arrives, and use
Higgsfield for everything else. Hybrid beats pure-AI here — not because the AI is bad, but
because that one shot is the proof and it has to be unimpeachable. Test both; let CTR decide.

---

## 4. Voiceover script (add in post)

Higgsfield generates ambient audio, not your VO. Record this yourself or use ElevenLabs —
**a real human voice outperforms synthetic on this product**, because the whole creative is
selling authenticity. Warm, conversational, female, 35–50, no announcer energy.

| Time | Line |
|---|---|
| 0–3s | *(silence — let the demo play)* |
| 3–6s | "He used to hide when the clippers came out." |
| 6–10s | "Turns out it was never the grooming. Most of these run at seventy decibels. Dogs hear that four times louder than we do." |
| 10–13s | "This one's fifty-five. And it still pulls twelve thousand pascals." |
| 13–16s | "That's one week of shedding — off the couch, and into the bin." |
| 16–20s | "A hundred and thirty dollars. My groomer was a hundred a visit." |

### On-screen captions (burn in — 80%+ watch muted)
```
0–3s    (no text — let the demo breathe)
3–6s    He used to hide from the clippers.
6–10s   Most grooming vacuums run at 70dB.
10–13s  This one runs at 55dB. And pulls 12,000Pa.
13–16s  One week of shedding.
16–20s  $129.95 — about one groomer visit.
        [CTA button: Shop HushCoat]
```
Caption style: white, bold sans (Inter Bold), 90% opacity black rounded-rectangle behind,
lower third, **above** the Meta UI safe zone (keep out of the bottom 15% of a 9:16 frame).

---

## 5. Variant prompts for testing

You need 4–6 creatives at launch. Reuse the SETTING / SUBJECT / PRODUCT / NEGATIVE blocks
verbatim and swap only the SHOT SEQUENCE. Consistency across variants makes CTR differences
attributable to the *angle* rather than to random visual noise.

### Variant B — "The Calm Dog" (emotional, 15s)
```
Replace SHOT SEQUENCE with:

0.0–3.0s — Close on the dog's face, eyes slowly closing, completely at ease, as the
grooming head works along its neck just in frame. Utterly calm.
3.0–7.0s — Slow handheld drift back. The dog exhales and settles its head fully onto the
floor mid-groom. The woman's hand rests briefly on its shoulder.
7.0–11.0s — Close on the deshedding head lifting thick undercoat away in one slow pass.
11.0–15.0s — Slow push-in on the product on the coffee table, the sleeping retriever soft
in the background. Hold with clear negative space in the upper third.
```
Caption hook: `Third session. He fell asleep.`

### Variant C — "The Couch" (proof-led, 15s)
```
Replace SHOT SEQUENCE with:

0.0–3.0s — Static wide of a pale linen sofa heavily covered in dog hair, flat window light.
A hand enters frame and drags across the fabric, lifting a visible cloud of loose fur.
3.0–8.0s — Cut to the grooming session: macro on the deshedding head pulling undercoat off
the retriever's flank in slow passes, fur visibly disappearing into the head.
8.0–11.0s — Close on the transparent dust bin, densely packed with collected fur, unclipped
and tipped toward the lens.
11.0–15.0s — Hard cut back to the identical sofa framing in identical light, now completely
clean. Hold. Then a slow push-in to the product resting on the coffee table.
```
Caption hook: `Same couch. Ten minutes apart.`

### Variant D — "Breed-Specific" (highest CTR, cheapest CPC)
Duplicate the hero prompt and change only the dog. Generate one per breed:
`Siberian Husky with a dense grey and white double coat` · `German Shepherd with a black and
tan coat` · `black Labrador Retriever with a short dense coat` · `Australian Shepherd with a
merle coat` · `Samoyed with a thick white double coat`

Pair each with a breed-named caption hook — `Husky owners, you already know what September
means.` Breed-specific creative reliably beats generic pet creative on CTR, and it lets you
run cheap breed-interest ad sets against matching creative.

### Variant E — "The Gift" (switch on 1 Nov)
```
Replace SHOT SEQUENCE with:

0.0–4.0s — Warm evening interior, soft lamp light. Hands lift the grooming unit out of an
open gift box with tissue paper. A decorated tree is softly out of focus behind.
4.0–9.0s — Cut to daylight: the recipient using it on their retriever for the first time,
smiling in genuine surprise as the fur lifts away.
9.0–13.0s — Close on the full dust bin, tipped toward the lens.
13.0–16.0s — Slow push-in on the product beside the open gift box on the coffee table,
dog resting in the soft background. Hold with negative space in the upper third.
```
Caption hook: `The gift every dog owner actually wants.`

---

## 6. Marketing Studio route (fastest variants)

For high-volume variant testing, `marketing_studio_video` is quicker than hand-writing prompts —
it composes from building blocks.

| Parameter | Value |
|---|---|
| `mode` | A **UGC** preset slug (list them first via `show_marketing_studio`, `action='presets'`) |
| `product_ids` | `['<your uploaded product uuid>']` — **plural array**, `product_id` is rejected |
| `avatar_ids` | `['<uuid>']` — max 1. Pick a warm, natural 35–50 female avatar |
| `hook_id` | From `show_marketing_studio(action='list', type='hook')` — pick a product-reveal hook |
| `setting_id` | From `type='setting'` — pick a **sunlit living room / warm home** setting |
| `aspect_ratio` | `9:16` |
| `resolution` | `1080p` |
| `generate_audio` | `true` |

Notes: hooks/settings work only on the UGC, Tutorial, Unboxing, Product Review and UGC Virtual
Try-On presets. `hook_id`/`setting_id` are **mutually exclusive with `ad_reference_id`** — pick
one approach. **Tutorial** is a strong second preset here, given tutorial content's documented
performance on pet grooming products.

---

## 7. Product b-roll (Seedance 2.0, 4K)

For the PDP hero video and the polished CTA insert.

```
A 6-second 4K product film of a compact matte off-white and deep-green pet grooming vacuum
on a warm oak surface against a soft off-white backdrop. Slow, smooth orbital camera move
from left to right, gently pushing in. Soft directional daylight from camera left with a
large soft source, gentle falloff, warm bounce fill, soft realistic contact shadow.
The five brushed stainless-steel grooming heads are arranged in a clean arc beside the
unit; the reinforced hose is neatly coiled. Shallow depth of field with the front edge of
the unit tack sharp. Premium, calm, understated — the register of a high-end appliance
commercial. Photorealistic, no text, no logos, no watermarks, no people, no animals.
```
Settings: `duration: 6` · `resolution: 4k` · `mode: std` · `aspect_ratio: 9:16` ·
`generate_audio: false` · `genre: auto`
*(4K requires `mode: std`; `fast` caps at 720p. Seedance 2.0 also supports unlimited
free-trial generations where your plan allows.)*

---

## 8. Creative compliance check

Run every generated asset against this before it goes live:

- [ ] No on-screen text implying a viewer attribute ("Is *your* dog scared?") → **Personal Attributes**
- [ ] No human before/after imagery *(a sofa before/after is fine)*
- [ ] No health/medical claim about the dog — no "reduces anxiety," "treats skin conditions"
- [ ] No distressed animal — a frightened dog on camera is both off-brand and a policy risk
- [ ] dB and Pa figures on screen **match the product page exactly** (ad + LP reviewed as one unit)
- [ ] No fake countdown, no fake stock counter
- [ ] No competitor brand names or logos
- [ ] Captions inside the safe zone (avoid bottom 15% of 9:16)
- [ ] Price on screen matches live site price
- [ ] Music is licensed or from Meta's Sound Collection

---

## 9. Deliverables checklist

| Asset | Model | Duration | Ratio | Purpose |
|---|---|---|---|---|
| Hero ad | Seedance 2.5 | 20s | 9:16 | Primary cold traffic |
| Hero ad (square) | Seedance 2.5 | 20s | 1:1 | Feed placement — **regenerate, don't crop** |
| Variant B — Calm Dog | Seedance 2.5 | 15s | 9:16 | Emotional angle |
| Variant C — Couch | Seedance 2.5 | 15s | 9:16 | Proof angle |
| Variant D ×3 — Breeds | Seedance 2.5 | 20s | 9:16 | Breed ad sets |
| Variant E — Gift | Seedance 2.5 | 16s | 9:16 | Q4, from 1 Nov |
| Product b-roll | Seedance 2.0 | 6s | 9:16 | PDP + CTA insert |

> **On generating these:** I've written the prompts but haven't run any generations, since each
> one spends your Higgsfield credits. Say the word and I'll generate the hero ad plus variants.
