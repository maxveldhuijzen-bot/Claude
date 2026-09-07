# Step 5 — Facebook Ads Testing & Scaling Strategy

---

## 1. The numbers you're playing against

**Your economics** (from `02-product-validation.md`, Phase 1):

| Metric | Value |
|---|---|
| AOV (blended, with upsell) | **$142** |
| Contribution margin | **$76.68/order (59%)** |
| **Break-even CPA** | **$76.68** |
| **Break-even ROAS** | **1.69x** |
| **Target CPA** | **$48** |
| **Target ROAS** | **2.7x** |

**2026 platform benchmarks:**

| Metric | Value |
|---|---|
| Median ecommerce CPM | **$13.48** |
| CPM outside Q4 | $14–17 |
| **CPM in Q4 (pet)** | **+35–41%** → ~$19–24 |
| Ecommerce CPC | $0.45–$0.88 |
| Median CTR (all industries) | **2.19%** |
| **Pet vertical ROAS** | **4.3x — highest of any vertical** |
| CPC seasonal swing | $0.85 (Jan) → $1.32 (Nov) |

**What this means:** you have $76.68 of room per sale. That is a *lot* — most dropshippers work
with $20–30. It buys you the ability to survive the learning phase and to keep a creative alive
long enough to actually judge it. Do not squander it by killing ads on day two.

---

## 2. Before you spend a dollar

- [ ] **Meta Pixel + Conversions API** installed via Shopify's native Facebook channel.
      Server-side is not optional in 2026 — browser-only tracking loses 20–30% of events.
- [ ] Verify domain in Business Manager
- [ ] Configure **Aggregated Event Measurement** — priority order: Purchase → InitiateCheckout →
      AddToCart → ViewContent → PageView
- [ ] Test events firing correctly (Events Manager → Test Events). **Place a real test order.**
- [ ] Business verification complete
- [ ] Product catalogue uploaded (needed for Advantage+ and retargeting)
- [ ] Warm the ad account: **$20–30/day for 3–4 days** on a simple engagement or traffic
      campaign before launching conversion campaigns. New accounts that open at $200/day get
      flagged disproportionately often.
- [ ] Site speed under 3s on mobile (PageSpeed Insights)
- [ ] All policy items in `02` §2 cleared on the live site — **the landing page is reviewed with the ad**

---

## 3. Phase 1 — Creative testing (Days 1–10)

**Budget: $100/day. Structure: ABO.**

Use ABO for testing — it gives each creative an equal, controlled budget instead of letting the
algorithm starve variants before they have data.

**Campaign:** `TEST | Creative | Sales`
**Objective:** Sales → Purchase *(not Traffic, not Add-to-Cart — optimise for what you want)*
**Placement:** Advantage+ Placements ON
**Attribution:** 7-day click, 1-day view

| Ad set | Audience | Budget/day | Creatives |
|---|---|---|---|
| AS1 | **Broad** — US, 35–65, all genders, no interests | $25 | All 6 |
| AS2 | Interest — Chewy, PetSmart, Petco, BarkBox | $25 | All 6 |
| AS3 | Interest — breed stack (Golden Retriever, GSD, Husky, Labrador, Aussie) | $25 | All 6 |
| AS4 | Interest — Dog grooming, AKC, Rover.com, Dog lover | $25 | All 6 |

**Include AS1 (broad) and mean it.** On a clean pixel in 2026, Advantage+ broad frequently beats
hand-picked interests. Many operators skip it out of habit and pay more for worse results.

**Creatives (all 6 from `04`):** Hero 20s · Calm Dog 15s · Couch 15s · Breed ×2 · Gift *(from 1 Nov)*

**Primary text — 3 variants to rotate:**

**PASTE — Ad copy A (Noise angle) →**
```
Most pet grooming vacuums run at 70 decibels.

A dog's hearing is about four times more sensitive than ours. At that volume, six inches
from his head, it isn't an appliance — it's a threat. That's why he hides when the
clippers come out.

The manufacturers who made theirs quieter did it by cutting the motor, and suction fell
below 10,000Pa — too weak to pull an undercoat off a double-coated breed.

The HushCoat Kit runs at 55dB and still delivers 12,000Pa. Quiet enough that most dogs
settle by the third session. Strong enough to strip a double coat in one pass.

Five professional tools. 3L bin. Ships free from our US warehouse.
60 nights to try it.

→ hushcoat.com
```

**PASTE — Ad copy B ($100 math) →**
```
The average dog groom in the United States costs about $100 a visit.

Once a month, that's $1,200 a year — before tips, before the drive, before the three-week
wait for an appointment.

The HushCoat 5-in-1 Kit is $129.95. Once.

12,000Pa of suction at 55 decibels — quiet enough that nervous dogs tolerate it, strong
enough to pull loose undercoat from Goldens, Huskies and Shepherds in a single pass.

It pays for itself before February.

Free US shipping. 60-night risk-free trial.
→ hushcoat.com
```

**PASTE — Ad copy C (Short / demo-led) →**
```
12,000 pascals. 55 decibels.

Every other grooming kit makes you pick one.

Free US shipping · 60-night trial · $129.95
→ hushcoat.com
```

**Headlines:** `Quiet Enough That He Won't Run` · `55dB. 12,000Pa. Both.` ·
`Your Groomer Charges $100. This Is $129.95.` · `The Kit Nervous Dogs Tolerate`
**Description:** `Free US shipping · 60-night risk-free trial`
**CTA button:** `Shop Now`

---

## 4. Kill and keep rules

**Do not touch anything for the first 48 hours.** Meta's learning phase needs ~50 conversions
per ad set to stabilise. Editing resets it. The single most common way beginners lose money is
optimising too early.

### At $100 spend per creative

| Signal | Action |
|---|---|
| 0 purchases, 0 add-to-carts | **Kill.** Creative isn't landing |
| 0 purchases, ≥3 ATCs | **Keep to $150.** Ad works, site may be leaking |
| CPA ≤ $48 | **Winner.** Move to Phase 2 |
| CPA $48–$76 | **Keep.** Profitable, needs optimisation |
| CPA > $76.68 (break-even) at $150 spend | **Kill** |
| CTR < 1.0% | **Kill the creative** — hook failed |
| CTR > 2.5% but no sales | Creative works, **landing page is the problem** |

**Rule of thumb:** kill at **1.5× break-even CPA** after $100–150 of spend. For you that's
**~$115**. Anything above that after $150 is not going to turn around.

### Diagnosing by metric

| Symptom | Diagnosis | Fix |
|---|---|---|
| Low CTR (<1%) | Hook failed | New first 3 seconds |
| High CTR, low ATC | Landing page mismatch | Align PDP headline to ad promise |
| High ATC, low checkout | Price/shipping shock | Surface free shipping earlier |
| High checkout, low purchase | Payment friction | Enable Shop Pay, PayPal, Apple Pay |
| Good CPA then decay | Creative fatigue (freq >2.5) | Rotate in new creative |

---

## 5. Phase 2 — Scaling (Days 11–30)

Move winners into CBO. Let the algorithm allocate.

**Campaign:** `SCALE | CBO | Sales` — start at **$150/day**

| Ad set | Audience |
|---|---|
| Broad | US, 35–65, no interests |
| Winning interest | Whichever won in Phase 1 |
| Lookalike 1% | Purchasers *(needs 100+ purchases)* |
| Lookalike 1–3% | Add-to-cart, 180d |

### Scaling rules

- **Increase budget 20–30% per day. Never double.** Doubling resets the learning phase and
  reliably tanks a working ad set.
- **Prefer horizontal scaling** — new audiences, new creatives, new geos. ~70% of accounts that
  scaled past $10k/month used horizontal expansion as the primary lever, because it preserves
  performance better than pushing budget into the same ad set.
- Wait **48–72 hours** after each increase before the next.
- If CPA rises >20% after an increase, **roll back to the previous budget** and hold 3 days.

### Retargeting — launch at day 14

**Campaign:** `RETARGET | ABO` — $30/day

| Ad set | Audience | Creative | Budget |
|---|---|---|---|
| Warm-1 | ATC 7d, excl. purchasers | Testimonial + `Still thinking?` | $15 |
| Warm-2 | VC 14d, excl. ATC | Comparison table creative | $10 |
| Warm-3 | IG/FB engagers 30d | Hero ad | $5 |

Retargeting CPA should run **$15–25** — roughly a third of cold. Do not offer a discount in
retargeting before day 3; most converters come back on their own and a premature discount just
donates margin.

---

## 6. Q4 calendar

| Dates | Move |
|---|---|
| **Sep 7–30** | Test at $100/day. CPMs are at their cheapest all quarter — **build pixel data now.** This window is the whole advantage |
| **Oct 1–15** | Lock winning creative. Scale to $200–300/day. Add Gift creative. Build `/collections/gifts` |
| **Oct 15–31** | Scale to $400–600/day. Launch retargeting properly. Build the email list hard |
| **Nov 1–20** | **Switch primary angle to Gift.** Scale to $800–1,200/day. Accept CPMs +35–41% |
| **Nov 21–26** | Pre-BFCM warm-up. Email list teaser. Raise budgets 30%/day |
| **Nov 27–Dec 1** | **BFCM. Maximum spend.** Offer = *free $49 accessory pack*, **not** a price cut |
| **Dec 2–15** | Gift push. Site-wide countdown to the Dec 15 cut-off |
| **Dec 15** | **Hard shipping cut-off.** Switch creative to digital gift cards |
| **Dec 26–31** | "New year, new routine." CPMs collapse — cheap traffic |
| **Jan** | **Cheapest CPMs of the year ($0.85 CPC).** Retention, email, spring-shed prep |

**On BFCM discounting:** at $129.95 with a 59% margin, a 25% sitewide discount costs you $32.49
per order — more than half your target profit. Bundling a $49 accessory pack that costs you $6
delivers a *larger perceived* discount for **one-fifth the margin**. Bundle, don't discount.

---

## 7. Budget ladder

| Stage | Daily | Duration | Total | Expected outcome |
|---|---|---|---|---|
| Warm-up | $25 | 4 days | $100 | Account seasoned |
| Testing | $100 | 10 days | $1,000 | 1–2 winning creatives, ~15–25 sales |
| Early scale | $200–300 | 10 days | $2,500 | ~50–70 sales, LLA seed built |
| Scale | $500–800 | 15 days | $9,750 | ~180–250 sales |
| **Q4 peak** | $1,000–1,500 | 30 days | $37,500 | ~700–950 sales |

**Minimum viable test budget: $1,500.** Below that you cannot gather statistically meaningful
data across 4 ad sets × 6 creatives, and you'll kill winners on noise.

> These projections assume you hit the $48 target CPA. Treat them as a **model, not a forecast** —
> they're arithmetic from benchmark inputs, not a promise. Your first two weeks will almost
> certainly underperform them while the pixel learns.

---

## 8. KPI dashboard

Check daily. Act weekly.

| Metric | Target | Red flag |
|---|---|---|
| CTR (link) | >1.5% | <1.0% |
| CPC | $0.45–$0.88 | >$1.50 |
| CPM | $14–17 (Q4: $19–24) | >$30 |
| ATC rate | >8% of clicks | <4% |
| Checkout→Purchase | >45% | <25% |
| **CPA** | **≤$48** | **>$76.68** |
| **ROAS** | **≥2.7x** | **<1.69x** |
| Frequency | <2.0 | >2.5 = fatigue |
| **MER** (total rev ÷ total ad spend) | **≥2.5x** | <1.8x |

**Watch MER, not just in-platform ROAS.** iOS attribution overstates platform ROAS. MER is the
number that tells you whether the business is actually making money.

---

## 9. Creative refresh cadence

Creative fatigue is the #1 cause of scaling failure. Once frequency passes 2.5, performance
decays regardless of how good the ad is.

- **Every 2 weeks:** 2 new creative variants
- **Every 4 weeks:** 1 new *angle*, not just a new edit
- Keep a rolling bank of 10+ ready assets
- When a winner starts decaying, **re-cut it before replacing it** — new hook, new first 3
  seconds, same body. Often recovers 60–80% of original performance at a fraction of the
  production cost.

The prompts in `04-higgsfield-prompts.md` are built for exactly this: fixed SETTING / SUBJECT /
PRODUCT blocks with a swappable SHOT SEQUENCE, so you can produce a genuinely new creative in
minutes without the visual identity drifting.
