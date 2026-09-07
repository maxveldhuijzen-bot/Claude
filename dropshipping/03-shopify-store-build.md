# Step 3 — Shopify Store Build + All Copy (Paste-Ready)

Everything below is written to be pasted directly into Shopify. Copy blocks are marked
**PASTE →**. Replace `[X]` placeholders only where explicitly noted.

---

## 1. Store name

> **Availability disclaimer:** I cannot verify live domain or trademark availability from here,
> so I have **not** claimed any of these are free. Before committing, check all three:
> (1) domain — Namecheap/Cloudflare, (2) **USPTO TESS** for trademark conflicts in Class 21/7,
> (3) Instagram + TikTok handle. Do the trademark check — this is a category with active brands.

| # | Name | Rationale |
|---|---|---|
| **1** | **HushCoat** ⭐ | **Recommended.** "Hush" = the quiet differentiator; "Coat" = the fur. Says the entire positioning in two syllables. Brandable, memorable, spells cleanly aloud |
| 2 | Quietpaw | Extremely clear, softer feel, slightly more generic |
| 3 | Stillfur | Calm + fur. Distinctive, slightly more premium/editorial |
| 4 | Hushound | Hush + hound. Great for dog-only positioning; weaker for cats |
| 5 | Calmcoat | Alliterative, warm, very legible |
| 6 | Mutefur | Direct and punchy; "mute" is slightly clinical |
| 7 | Softshed | Pleasant, describes benefit; less distinctive |
| 8 | Pawmuffle | Playful and highly memorable; more casual brand register |

**Going with `HushCoat` for all copy below.** Domain preference:
`hushcoat.com` → `hushcoat.co` → `gethushcoat.com`.

---

## 2. Brand positioning

**One-line positioning**
> HushCoat makes the grooming kit quiet enough that your dog doesn't run from it.

**USP (the thing no competitor says)**
> **12,000Pa of suction at 55 decibels. Every other grooming kit makes you choose.**

**Brand promise**
> Professional-grade grooming at home, without the fear, the fur, or the $100 appointment.

**Voice:** Calm, plainspoken, quietly confident. Never shouty, never emoji-stuffed. We talk about
decibels and pascals like people who actually care about the numbers — because the numbers *are*
the product. Warmth comes from understanding the dog, not from exclamation marks.

**Three brand pillars**
1. **Quiet is the feature.** Everyone else sells power. We sell power the dog can tolerate.
2. **Show the spec.** We publish dB and Pa on the page. Confidence, not adjectives.
3. **The dog's experience comes first.** Every decision is judged from the animal's side.

---

## 3. Design system

### Colors

> **Updated to the system that shipped on the live storefront.** The original warm
> off-white and terracotta scheme was replaced: it collides with the beige-cream +
> brass palette family that has become the default AI reach for DTC brands, and
> "forest green + amber" is going the same way. This palette is derived from the
> product's own material world instead: brushed steel on a dark ground.

Monochrome plus one saturated pop. Dark theme throughout (one theme per page).

| Role | Hex | Use |
|---|---|---|
| **Ground** | `#101412` | Page background, deep graphite green |
| **Surface** | `#19201D` | Cards, spec panels |
| **Raised** | `#222B27` | Hover and raised states |
| **Ink** | `#E9EDEA` | Primary text, cool bone |
| **Muted** | `#8C9A94` | Body copy, secondary |
| **Steel** | `#B8C2C0` | Rules, quiet CTAs, table labels |
| **Accent** | `#E2483D` | Signal red. **Primary CTAs and spec numerals only** |
| Hairline | `rgba(184,194,192,0.16)` | Section dividers |

**Rule:** the signal red appears only on primary CTAs and on the two numbers the
brand lives on (55dB, 12,000Pa). Nothing else on the page is colored. That single
restriction is what makes the page read as designed rather than assembled.

### Typography
- **Display:** `Outfit` (Google Fonts), 500 weight, `letter-spacing: -0.035em`.
- **Specs, eyebrows, numerals:** `IBM Plex Mono`, 400/500, `letter-spacing: 0.14em` uppercase.
- **Body:** `Outfit` 300.
- **Why a mono:** the decibel and pascal figures *are* the product, so they are set
  in the face that treats numbers as data. The mono is load-bearing, not decorative.
- **Sizes:** H1 `text-4xl` mobile / `text-6xl` desktop, body `text-base leading-relaxed max-w-[65ch]`.

### Theme
**Dawn** (free). PageSpeed ~92, Online Store 2.0, highest-reviewed free theme, and it handles a
one-product store cleanly. Alternatives: **Sense** (good for spec-heavy products), **Refresh**
(built-in urgency banner + slide cart). **Do not buy a premium theme to start** — spend that
money on creative testing instead.

### Aesthetic direction
Editorial-calm, close to Aesop or Away. Lots of warm white space. Real dogs in real homes —
never studio-white stock photos. Photography should feel like a Sunday morning, not a laboratory.

---

## 4. Homepage layout

Sections in order. Mobile-first — **80%+ of your Meta traffic is mobile.**

### Section 1 — Announcement bar
**PASTE →** `Free US shipping · 60-night risk-free trial · Ships from our US warehouse in 1 business day`
*(From 1 Dec, swap to: `🎁 Order by Dec 15 for guaranteed Christmas delivery`)*

### Section 2 — Hero
- **Full-bleed image:** golden retriever mid-groom in a sunlit living room, owner's hands
  visible, dog visibly relaxed. **Never** a white-background studio shot here.

**PASTE — H1 →**
```
Quiet enough that he won't run from it.
```
**PASTE — Subhead →**
```
12,000Pa of suction at 55 decibels. Every other grooming kit makes you choose between
power and a calm dog. The HushCoat Kit doesn't.
```
**PASTE — Primary CTA →** `Groom him at home — $129.95`
**PASTE — Under-CTA microcopy →** `Free shipping · 60-night trial · Ships in 1 business day`

### Section 3 — Trust bar
Four icons + labels:
`🇺🇸 Ships from the USA` · `🔇 55dB — quieter than a dishwasher` · `💨 12,000Pa suction` · `↩️ 60-night risk-free trial`

### Section 4 — The problem
**PASTE →**
```
## The problem isn't grooming. It's the noise.

Most grooming vacuums run between 65 and 75 decibels. To a dog — whose hearing is
roughly four times more sensitive than ours — that isn't an appliance. It's a threat.

So the manufacturers made quieter units. And to keep them quiet, they cut the motor.
Now the suction is too weak to pull an undercoat, and the fur ends up on your couch anyway.

Quiet or powerful. For years, that was the only choice.
```

### Section 5 — The solution *(the money section)*
**PASTE →**
```
## We refused to pick one.

The HushCoat Kit runs at 55 decibels — quieter than a dishwasher, quieter than
conversation in a restaurant. And it pulls 12,000 pascals, enough to lift the loose
undercoat off a double-coated breed in a single pass.

Not one or the other. Both. That is the entire reason this company exists.
```
**Comparison table — PASTE →**

| | Typical grooming kit | **HushCoat Kit** |
|---|---|---|
| Noise level | 65–75dB | **55dB** |
| Suction | 8,000–10,000Pa | **12,000Pa** |
| Brush teeth | Plastic | **Stainless steel** |
| Dustbin | 1–1.5L | **3L** |
| Works on double coats | Struggles | **Yes** |
| Ships from | China (2–5 weeks) | **US warehouse (2–5 days)** |

### Section 6 — How it works (3 steps)
**PASTE →**
```
1. Attach — Click on the tool you need. Five professional heads, one twist each.
2. Groom — Work in slow passes. The fur lifts off the coat and goes straight into the bin.
3. Empty — Pop the 3L bin, tip it out, rinse. Under ten seconds.
```

### Section 7 — What's in the kit
5-in-1 tool grid with a photo of each: Deshedding brush · Electric clipper · Slicker brush ·
Grooming nozzle · Crevice/cleanup tool.

### Section 8 — The math
**PASTE →**
```
## The average American dog groom costs $100 a visit.

At one groom a month, that's $1,200 a year — before tips, before transport, before the
three-week wait for an appointment.

The HushCoat Kit is $129.95, once. It pays for itself before February.
```

### Section 9 — Reviews
Star rating + 6 review cards + photo reviews. See §7 for setup.

### Section 10 — Video / UGC
Embed the Higgsfield ad (muted autoplay, captions burned in).

### Section 11 — FAQ
Accordion — see §9.

### Section 12 — Guarantee
**PASTE →**
```
## Sixty nights. Then decide.

Use it on every dog in the house. If your dog won't tolerate it, or it doesn't pull the
coat the way we said it would, send it back for a full refund. No photographs, no
explanation required.
```

### Section 13 — Final CTA
Repeat hero CTA + trust bar.

### Section 14 — Footer
Nav, policies, contact, email capture, payment icons.

---

## 5. Product page copy — full paste-ready block

**Product title**
```
HushCoat 5-in-1 Pet Grooming Kit — 12,000Pa Suction at 55dB
```

**Price:** `$129.95` — Compare-at: `$199.95`

**Subtitle / hook**
```
The grooming kit quiet enough that he won't run from it.
```

**PASTE — Benefit bullets (above the fold) →**
```
✓  55dB — quieter than a dishwasher, so nervous dogs stay calm
✓  12,000Pa suction — lifts loose undercoat from double-coated breeds in one pass
✓  Catches the fur at the source — it never reaches your couch, car or clothes
✓  5 professional tools — deshedder, clipper, slicker, nozzle, crevice tool
✓  3L dustbin — groom a large dog without stopping to empty
✓  Stainless-steel brush teeth — not the plastic ones that snap in month two
✓  Ships free from our US warehouse in 1 business day
✓  60-night risk-free trial — send it back for any reason
```

**PASTE — Full description →**
```
## Your dog isn't being dramatic.

A dog's hearing is roughly four times more sensitive than yours. Most pet grooming
vacuums run between 65 and 75 decibels. Held six inches from his head, that is not a
household appliance — it is a sustained, inescapable noise he cannot understand.

That's why he hides when the clippers come out.

## So why not just make it quieter?

Manufacturers tried. To drop the volume, they dropped the motor — and suction fell to
8,000 pascals or less. Below about 10,000Pa, a grooming vacuum simply cannot pull the
loose undercoat out of a Golden Retriever, a Husky or a German Shepherd. The fur stays
in the coat, sheds onto the sofa an hour later, and you're back where you started.

Quiet, or powerful. Until now, you picked one.

## The HushCoat Kit does both.

A redesigned brushless motor and a sound-dampened housing bring the unit down to
55 decibels — about the level of a dishwasher one room away — while still delivering
12,000 pascals at the head.

Quiet enough that most dogs settle within two or three sessions. Strong enough to strip
a double coat in a single pass.

## Five tools. One twist to change.

**Deshedding brush** — stainless-steel teeth reach through the topcoat to the loose
undercoat. This is the tool that does 80% of the work.
**Electric clipper** — low-vibration blade for paws, sanitary areas and light trims.
**Slicker brush** — daily maintenance and finishing, with suction running.
**Grooming nozzle** — pulls loose hair from short-coated breeds and cats.
**Crevice tool** — for the couch, the car seat and the stairs afterward.

## The 3L bin means you finish in one go.

Most kits ship a 1–1.5L bin, which fills halfway through a large dog. Ours holds three
litres. Groom a Bernese Mountain Dog start to finish without stopping. Empty it in about
ten seconds — unclip, tip, rinse.

## What it costs, versus what you're spending now.

The average dog groom in the United States runs about $100 a visit; small-dog full-service
packages run $75–$125, and extra-large dogs can exceed $200. At one visit a month you are
spending roughly $1,200 a year.

The HushCoat Kit is $129.95, once. It pays for itself in under two appointments.

## Getting him used to it

Almost every dog needs a short acclimation period. Run the unit on the low setting in the
same room for a few minutes, without touching him, and reward calm. Most owners report
their dog settling by the third session. The 60-night trial exists precisely so you have
time to do this properly, without pressure.

## In the box

1 × HushCoat main unit (3L bin) · 1 × reinforced 1.6m hose · 5 × professional grooming
heads · 1 × cleaning brush · 1 × user guide with acclimation instructions.

Certified CE, FCC and RoHS. Corded — no battery to degrade, and no lithium shipping delays.
```

**PASTE — Urgency block (use only if true; never fake a timer) →**
```
🇺🇸 In stock in our US warehouse — ships within 1 business day.
```
*(From 1 Dec add: `🎁 Order by December 15 for guaranteed Christmas delivery.`)*

**PASTE — Cart upsell offer →**
```
Add the Replacement Head & Filter Pack — $29 (normally $49)
Two filters and a spare deshedding head. Most owners replace theirs around month eight.
```

**PASTE — Social proof placeholders (replace with real reviews once you have them) →**
```
★★★★★ "Third session and he actually fell asleep during it." — [Name], [State]
★★★★★ "I have two huskies. I was skeptical about the suction. I am no longer skeptical."
       — [Name], [State]
★★★★★ "Cancelled the standing groomer appointment I've had for four years." — [Name], [State]
```
> ⚠️ **Replace these before launch.** Placeholder reviews presented as real are both a Meta
> misleading-claims violation and an FTC problem. Use them as *format templates only.*

---

## 6. Collections

A one-product store doesn't need many. Build three:

| Collection | Purpose | URL |
|---|---|---|
| **The Grooming Kit** | Hero product | `/collections/grooming-kit` |
| **Accessories & Refills** | Heads, filters, hoses — upsell + repeat revenue | `/collections/accessories` |
| **Gifts for Dog People** | **Build this by 1 Nov.** Q4 gift-buyer traffic | `/collections/gifts` |

---

## 7. App stack

Start lean. Every app costs speed, and speed costs conversions.

### Essential (launch with these)

| App | Job | Cost |
|---|---|---|
| **DSers** or **CJdropshipping** | Order fulfilment + US warehouse routing | Free tier |
| **Judge.me** or **Loox** | Reviews with photos. **Loox** if you want photo-first (better for this product) | ~$15–35/mo |
| **Vitals** | Consolidates upsells, bundles, trust badges, sticky cart in one app — better for speed than 6 separate apps | ~$30/mo |
| **Klaviyo** or **Omnisend** | Email/SMS — abandoned cart is your highest-ROI flow | Free to 500 contacts |
| **Meta Pixel & Conversions API** (native Shopify channel) | **Non-negotiable.** Server-side tracking | Free |

### Add after ~50 orders

| App | Job |
|---|---|
| **Frequently Bought Together** or **Bundler** | Bundle the accessory pack |
| **SMART Checkout Rules & Upsells** | Post-purchase upsell (pure margin — no ad cost) |
| **LimeSpot** | AI recommendations once you have catalogue depth |
| **Hotjar / Lucky Orange** | Session recordings to find where the PDP loses people |

**Do not install:** fake countdown timers, fake "17 people viewing" popups, spin-to-win wheels.
They violate Meta's misleading-claims policy, and in 2026 your landing page is reviewed as part
of the ad. Not worth the account risk.

### Email flows (build these three first)
1. **Abandoned cart** — 3 emails: 1h / 24h / 72h. The 72h email carries a $10 code.
2. **Welcome** — 2 emails, lead with the noise story, not a discount.
3. **Post-purchase acclimation** — day 1, 3, 7. *"How to get him comfortable with it."*
   This flow is your return-rate killer — most returns are acclimation failures, not defects.

---

## 8. Trust badges & policies

### Badges (place directly under the Add-to-Cart button)
`🔒 Secure checkout` · `🇺🇸 Ships from USA` · `↩️ 60-night returns` · `✅ CE / FCC / RoHS certified`
Payment icons: Visa, Mastercard, Amex, PayPal, Shop Pay, Apple Pay, Google Pay.

### Shipping Policy — **PASTE →**
```
## Shipping

We ship free to all 50 US states from our warehouse in the United States.

Orders placed before 2pm ET on a business day ship the same day; orders after that ship
the next business day.

Delivery: 2–5 business days standard. During peak season (November–December), allow
3–7 business days.

Holiday cut-off: order by December 15 for delivery before December 25.

You'll get a tracking number by email as soon as your order leaves the warehouse. If
tracking hasn't updated within 3 business days, email us and we'll chase it.

We currently ship to the United States, Canada, the United Kingdom and Australia.
International delivery is 5–12 business days; import duties, where applicable, are the
customer's responsibility.
```

### Returns & 60-Night Trial — **PASTE →**
```
## 60-Night Risk-Free Trial

Grooming is a habit, and habits take a few weeks to form. So we give you sixty nights.

Use the kit on every dog in the house. If your dog won't tolerate it, if the suction
isn't what we told you it would be, or if you simply don't want it — send it back within
60 days of delivery for a full refund.

We don't require photographs. We don't require an explanation.

How to return:
1. Email returns@hushcoat.com with your order number.
2. We'll send a prepaid return label within one business day.
3. Your refund is issued to the original payment method within 5 business days of the
   return arriving.

Return shipping is free for defective items. For change-of-mind returns, a $9.95 return
shipping fee is deducted from the refund.

Damaged or defective on arrival? Email us a photo and we'll ship a replacement
immediately — no return needed.
```

### Privacy Policy / Terms of Service
Generate from **Shopify Settings → Policies → "Create from template"**, then edit in your
business details. Do not paste a competitor's — it will name their entity and jurisdiction.
**Add a CCPA/CPRA section** if you sell to California, which you will.

### Contact — **PASTE →**
```
## Contact us

Email: help@hushcoat.com
We answer every email within one business day, Monday to Friday.

HushCoat
[Your registered business address]
[City, State, ZIP]
```
> A real, complete business address is required for Meta ad account verification. Do not skip it.

---

## 9. FAQ — paste-ready

**PASTE →**
```
### Will this actually be quiet enough for my dog?

The unit runs at 55 decibels — roughly a dishwasher in the next room. That's 10–20dB
below most grooming vacuums, and because decibels are logarithmic, that difference is
substantial rather than marginal.

That said, no vacuum is silent, and some dogs need time. Run it on low in the same room
for a few minutes a day without touching him first. Most owners tell us their dog settles
by the third session. You have 60 nights to find out.

### Will it work on a double-coated breed?

Yes — that's what the 12,000Pa is for. Below roughly 10,000Pa, a grooming vacuum can't
pull loose undercoat from a Golden Retriever, Husky, German Shepherd or Samoyed. The
deshedding head with stainless-steel teeth reaches through the topcoat to the undercoat
where the shedding actually happens.

### Can I use it on cats?

Yes. Use the grooming nozzle or slicker brush rather than the deshedding head, and start
on the lowest setting. Long-haired cats — Maine Coons, Persians, Ragdolls — benefit most.
Cats generally need a longer acclimation period than dogs.

### How often should I use it?

For heavy shedders, once or twice a week during shedding season (spring and autumn), and
every other week otherwise. Short-coated breeds need it less. Over-grooming can irritate
skin, so let the coat guide you rather than a fixed schedule.

### Is it cordless?

No, and that's deliberate. A corded unit delivers consistent suction for the whole
session rather than fading as a battery drains, there's no battery to degrade after two
years, and it avoids the lithium shipping restrictions that delay delivery. The hose is
1.6m, which reaches comfortably around a large dog.

### How loud is 55dB, really?

A quiet library is about 40dB. Normal conversation is about 60dB. A dishwasher one room
away is about 55dB. A typical grooming vacuum at 70dB is closer to a running blender.

### How long does the dustbin last?

The 3L bin will take a full groom of a large double-coated dog without emptying. Most
owners with medium dogs empty it every two or three sessions.

### What if it arrives damaged?

Email help@hushcoat.com with a photo. We ship a replacement immediately — you don't need
to send the damaged one back.

### How fast is shipping?

We ship from a US warehouse. Orders before 2pm ET ship same day, and delivery is
typically 2–5 business days (3–7 during the holiday peak).

### Do you ship outside the US?

Yes — Canada, the UK and Australia, in 5–12 business days. Import duties, where they
apply, are the customer's responsibility.

### Can I replace the brush heads?

Yes. Replacement heads and filters are in our Accessories collection. Most owners replace
the deshedding head around month eight, depending on use.

### Is there a warranty?

Twelve months against manufacturing defects, on top of the 60-night trial.
```

---

## 10. Product imagery — shot list & alt text

**Rule: no white-background studio shots in the first three slots.** Meta traffic converts on
in-context imagery. Save the clean studio shot for slot 4.

| # | Shot | Alt text (paste into Shopify) |
|---|---|---|
| 1 | **Hero** — Golden Retriever mid-groom, sunlit living room, owner's hands, dog relaxed | `Golden Retriever being groomed at home with the HushCoat 5-in-1 pet grooming vacuum kit` |
| 2 | **The demo** — macro, close on deshedding head, visible fur lifting off the coat | `Close-up of loose undercoat being lifted from a dog's coat by the HushCoat deshedding head` |
| 3 | **The proof** — split frame, couch covered in fur / same couch clean | `Sofa before and after removing pet hair with the HushCoat grooming kit` |
| 4 | **Kit flat-lay** — all 5 tools + unit, warm off-white background, top-down | `HushCoat 5-in-1 pet grooming kit contents including deshedding brush, clipper and slicker brush` |
| 5 | **Spec card** — graphic: "55dB" and "12,000Pa" large, on brand colors | `HushCoat grooming vacuum specifications: 55 decibels noise level and 12,000 pascals suction` |
| 6 | **Scale/size** — unit beside a coffee mug for size reference | `HushCoat grooming vacuum size compared to a coffee mug` |
| 7 | **Calm dog** — dog lying down, visibly relaxed, unit running beside it | `Relaxed dog lying still during grooming with the low-noise HushCoat vacuum` |
| 8 | **The bin** — 3L dustbin held open, full of collected fur | `3 litre dustbin of the HushCoat grooming kit filled with collected dog hair` |
| 9 | **Comparison graphic** — HushCoat vs typical kit table | `Comparison of HushCoat grooming kit versus typical pet grooming vacuums on noise and suction` |
| 10 | **Cat variant** — long-haired cat being groomed with the nozzle | `Long-haired cat being groomed with the HushCoat grooming nozzle attachment` |
| 11 | **Lifestyle/gift** — kit wrapped with a ribbon beside a dog *(add 1 Nov)* | `HushCoat pet grooming kit as a Christmas gift for dog owners` |

**Alt-text rules:** describe the image factually, include "HushCoat" and one keyword, keep under
125 characters, and **never** put a health claim in alt text — image metadata is now reviewed as
part of Meta's ad compliance unit.

**Where to get images:** order a sample unit and shoot it yourself on a phone in daylight. This
costs one weekend and beats every supplier photo you will ever be given. Supplier images are
shared with every competitor selling the same unit — shooting your own is the cheapest real moat
available to you.

---

## 11. Pricing strategy summary

| Element | Decision |
|---|---|
| Hero price | **$129.95** (compare-at $199.95) |
| Never discount below | **$99.95** |
| Free shipping | Always free, framed as "over $75" so the threshold feels earned |
| Cart upsell | Head & Filter Pack $29 (was $49) — ~90% margin |
| Q4 bundle | Two-kit gift bundle $229.90 |
| Target blended AOV | **~$142** |
| BFCM offer | **Bundle value, not price cuts** — "free $49 accessory pack" beats "25% off" at equal cost and protects the price anchor |
