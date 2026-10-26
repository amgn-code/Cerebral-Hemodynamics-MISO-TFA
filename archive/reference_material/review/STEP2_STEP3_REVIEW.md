# Steps 2 & 3 — scientific review, and the step 4 task list

**Reviewer:** Claude, scientific reviewer per the agreed plan.
**Inputs:** `STEP2_NC_INPUT_AUDIT.pdf`, `STEP3_SIMULATION_PILOT_REPORT.pdf`, branch `codex/independent-miso-tfa` at `b42b234`.
**Prior documents:** `review/PROJECT_REVIEW.md` (findings), `review/PROTOCOL_FREEZE.md` (step 1).

This closes the three PROVISIONAL items left open in `PROTOCOL_FREEZE.md` §8, reviews the pilot figures, and gives step 4 an ordered task list. Supporting figures are in `review/figures/`.

---

## Headline

**The NC recordings operate at a MAP–PETCO₂ coherence of roughly 0.13, and the simulation has no level anywhere near it.** The measured band-mean coherence is 0.24, but the estimator's null expectation at these settings is 0.125 — so more than half of what was measured is estimator bias. Bias-corrected, the 23 subjects span γ² ≈ 0.06–0.18. The simulation's levels are 0, 0.50 and 0.95.

That is not a failure of step 2. It is the most useful thing step 2 could have returned, and it changes what the paper is about. It also makes a clean, defensible story available: *at rest, MAP and PETCO₂ are barely coherent, so the omitted-input bias that motivates MISO is small — but MISO still helps, through a second mechanism that does not depend on coherence at all.* The pilot already shows that second mechanism; nobody has named it yet. See §B2.

Six things need to change before the paper run. They are listed in priority order in §D.

---

# Part A — Step 2 review

Execution was clean: 24 files found, 23 completed cleanup and characterisation, the frozen 0.02–0.35 Hz band was used, per-recording Nyquist masking was applied, and the effective-averages correction (`3 windows / Σk² = 8`) was implemented exactly as specified. Good work. The findings below are about interpretation, not execution.

## A1. Deliverable 1 — coherence. **Levels now FROZEN, and they change.**

The audit reports band-mean coherence percentiles of 0.1812 / 0.2395 / 0.2822 and then says the levels "remain `[0 0.50 0.95]` until the scientific reviewer decides". Here is the decision, and the reasoning matters more than the numbers.

**These are biased estimates and must be corrected before they are compared with an assigned simulation level.** The simulation's `targetCoherence` is a *population* parameter. The NC numbers are *sample* magnitude-squared coherences from 8 effective averages, and for that statistic `E[γ̂²] ≈ γ² + (1−γ²)/n`. Inverting:

| Percentile | Measured | Bias-corrected true γ² |
|---|---:|---:|
| 10th | 0.1812 | **0.064** |
| 50th | 0.2395 | **0.131** |
| 90th | 0.2822 | **0.180** |

For context: the estimator null is 0.125 and the CARNet 95 % threshold at n = 8 is 0.22. **The 10th-percentile subject's raw coherence (0.181) is below the CARNet threshold, and the median subject (0.240) barely clears it.** The coherence-by-frequency panel in the step-2 figure shows the same thing directly — the mean curve tracks along or just under the threshold line across the whole band.

So: in resting NC recordings, MAP and PETCO₂ are only marginally coherent, and for a substantial fraction of subjects and frequencies the coupling is not distinguishable from zero.

**FROZEN — input coherence levels: `[0, 0.15, 0.50, 0.95]`**

| Level | Role | Provenance |
|---:|---|---|
| 0 | independent-input control | design |
| **0.15** | **NC operating point** | **NC-derived: bias-corrected median 0.131, rounded** |
| 0.50 | moderate coupling stress level | engineering |
| 0.95 | near-collinear stress level | engineering |

Adding one level takes the core grid from 9 to 12 scenarios. That is cheap and it is the difference between a study that describes your data and one that does not. Without 0.15 you cannot answer the question a reviewer will ask first: *what does this predict for the recordings you actually have?*

Report the bias correction explicitly in the methods, and put the NC operating range as a shaded band or marked row on the primary coherence heatmap. See `review/figures/f1_operating_point.png`.

## A2. Deliverable 2 — phase. **Levels now FROZEN, upgraded from stress set to NC-derived.**

Measured fitted PETCO₂-lag-relative-to-MAP: 10th −6.17 s, median +0.27 s, 90th +3.68 s, median linear-fit R² 0.72.

The audit is appropriately cautious, but I checked whether the spread is real rather than estimation noise, and it is. At the bias-corrected coherence of 0.131 with n = 8, the per-bin phase standard deviation is about 37°, which gives a fitted-lag standard error of roughly **0.24–0.72 s** depending on how many bins survive the threshold and how they are spread across the band. The observed between-subject spread is about **3.5 s SD**, five to fifteen times larger. The lag variation across subjects is genuine physiological or protocol variation, not measurement scatter.

**FROZEN — E2 input phase lag levels: `[−6, 0, +4]` s**, provenance **"NC-derived (10th / 50th / 90th percentile of fitted lag, n = 23)"**.

The median of +0.27 s means that on average PETCO₂ and MAP fluctuate essentially in phase at rest — which is what you would expect if respiration drives both. Keep the audit's caveat that a single lag is not a complete description of every recording, and keep the sign convention comment in the generator.

One refinement worth doing: report `ValidPhaseBinCount` per subject in the paper's supplement, and exclude any subject with fewer than, say, 5 retained bins from the percentile calculation. With coherence this close to threshold, a subject contributing 2 bins should not carry the same weight as one contributing 20.

## A3. Deliverable 3 — spectra. **Reshape is required. The §4.3 trigger has fired.**

`PROTOCOL_FREEZE.md` §4.3 said: reshape the generator if the measured spectra carry materially different relative HF power. They do.

Excluding the contaminated lowest bin (§A4), the measured NC spectra fall about **30 dB** from 0.033 Hz to 0.35 Hz, monotonically. The generator's Gaussian falls about **20 dB** and, more importantly, **peaks at 0.06 Hz — where the real spectra are already 5–10 dB down from their maximum.** The real inputs have no peak; they decay from the lowest frequency onward. See `review/figures/f2_spectra.png`.

Two consequences:

1. **Replace the Gaussian-plus-floor with a monotonic decaying shape** fitted to the measured median spectra over 0.033–0.35 Hz. A two-parameter `1/(1 + (f/f₀)^α)` or a low-order AR shape will do; fit `f₀` and `α` to the median NC MAP spectrum, freeze them, and record the fit in the manifest. Do not hand-tune.
2. **One thing the data supports keeping:** the measured MAP and PETCO₂ spectra are roughly **parallel** — MAP sits 5–10 dB above PETCO₂ throughout, with no systematic divergence. So the frozen `spectralSimilarity = 1` (identical shapes for both inputs) is a defensible approximation, and the 8–10 dB offset is absorbed by the SD ratio. That fixed setting survives step 2 unchanged, and now it has empirical backing rather than convenience.

Be aware of the knock-on: a steeper roll-off means **less** input power at HF, so the realised in-band SNR at 0.20–0.35 Hz gets *worse* than the pilot shows. That reinforces §C.

## A4. Defect found — the 0.02 Hz bin is contaminated by residual trend

In the step-2 coherence panel, MAP–PETCO₂ coherence at the lowest retained bin is **≈ 1.0**, falling to 0.33 at the next bin. In the spectra panel, both MAP and PETCO₂ sit **~26 dB above their next neighbour** at that same bin.

Coherence of 1.0 between two physiological signals at the lowest resolvable frequency is the classic signature of a shared residual linear trend, not of physiology. Two records that both drift slowly are perfectly coherent at the bin adjacent to DC.

The cause is in `estimateWelchSpectra`: **there is no per-segment detrending.** The only detrend option is global, and it is off by default (`detrendEnabled = false`). Standard Welch practice detrends each segment before windowing.

**Fix (step 4):** detrend each Welch segment (linear) before applying the window, in `estimateWelchSpectra`, for both the simulation and the real-data path. Then re-run the step-2 characterisation. I expect the 0.02 Hz coherence to drop to the same 0.2–0.3 range as the rest of the band and the spectral spike to disappear. If it does not, exclude the bin and say why.

This matters beyond cosmetics: that bin currently anchors the lowest reported band and it is included in the band-mean coherence that sets the level in §A1. The corrected numbers may shift slightly. **Re-run §A1's percentiles after the detrend fix and confirm the 0.15 level before the paper run.**

## A5. Is the default NC protocol appropriate for these recordings?

**Mostly yes, with one caveat that is now more serious than it was.**

Working well: 23/24 recordings usable; three 90 s blocks fit every record; per-subject Nyquist masking implemented; the effective-averages correction is right; disjoint training blocks with spectra averaged rather than concatenated.

The caveat is the one from `PROJECT_REVIEW.md` N1 — two training Welch segments for a two-input solve — and step 2 has made it worse, not better. At a true coherence of 0.13, MAP and PETCO₂ carry almost independent information, which is *good* for conditioning, but the effect MISO is meant to correct is correspondingly tiny. You are now trying to detect a small effect with a low-power design.

**Recommendation:** take option 3 from `PROTOCOL_FREEZE.md` §N1 — keep the design and pre-register the limitation — but do it quantitatively. Run the simulation at the NC design's exact settings (2 training windows, 1 held-out window, 23 subjects, γ² = 0.15) and report the minimum detectable advantage. That converts "we found no clear difference" from a weak result into a stated power bound, and it is a natural use of the machinery you have already built. It is one simulation run, not new code.

---

# Part B — Step 3 review

## B1. The main result figure works

Page 1 is a good figure and it is close to publication quality. Colour limits are symmetric and identical (±2) across all four panels, which is what `PROTOCOL_FREEZE.md` §3.6 asked for and is the thing most people get wrong. Frequency is horizontal, factor level vertical, advantage as colour. It reads correctly.

What it shows, in physiological terms:

- **At γ² = 0.95**, MISO is clearly better below ~0.15 Hz and clearly **worse** above ~0.17 Hz. That is the bias–variance crossover I said was the real finding, and it is visible without being told to look for it.
- **At CO₂ pathway ratio = 0** (no CO₂ effect at all), the map is faintly orange — SISO slightly better. Correct, and a good internal sanity check: with nothing to correct, MISO's second parameter is pure variance cost.
- **Duration 600 s beats 300 s** at low frequency, as expected.

## B2. A finding in the pilot that nobody has named yet — and it is the one that matters for NC

Look at the coherence panel, row γ² = 0. MISO is **better** there, not neutral, at low frequency.

At zero input coherence there is no omitted-variable bias — SISO is unbiased for the MAP pathway. So why does MISO win? Because including CO₂ removes the CO₂-driven component from the unexplained CBFV variance, which lowers the variance of the MAP coefficient. **This is a second, independent mechanism, and it does not require the inputs to be coherent at all.**

That is exactly the regime your NC data occupies. So the study now has a two-part answer:

| Mechanism | Requires input coherence? | Where it shows up |
|---|---|---|
| Removing omitted-input **bias** | Yes — scales with √γ² | γ² = 0.5 and 0.95 rows, low frequency |
| Reducing residual **variance** | No | present even at γ² = 0 |

**This should be stated explicitly in the paper and it should drive the NC prediction.** At γ² ≈ 0.15 the bias mechanism is nearly absent, so the predicted NC advantage comes almost entirely from variance reduction — a small positive effect, concentrated at low frequency. That is a specific, falsifiable prediction that you can check against the NC bootstrap result you already have. If the measured NC advantage matches it, that is a genuinely strong validation of the whole framework.

Add a dedicated figure: predicted advantage at γ² = 0.15 from simulation, overlaid on the measured NC prediction advantage.

## B3. The analytic reference panel is not usable as built

Page 2 does not do the job `PROTOCOL_FREEZE.md` §3.4 asked for. Three problems:

1. **Wrong quantity.** §3.4 asked for *the advantage you would predict with infinite data* — in the same log₁₀-ratio units as page 1, so a reader can compare "theory says +1.5, we measured +0.8". What was produced is the raw normalised SISO bias, in different units, with a different colormap and a different scale. The two pages cannot be compared.
2. **The colour range is consumed by one bin.** Every panel is uniform dark blue with a single yellow column at 0.02 Hz. That is mathematically correct — the MAP pathway is high-pass so its gain is smallest at low frequency, while the CO₂ pathway is low-pass so its gain is largest there, and the ratio peaks at the band edge — but it renders the figure informationless.
3. **Two of the four panels carry no information.** The analytic bias is a population quantity; it cannot depend on recording duration or output noise. The duration and SNR panels are constant down every column by construction and should not exist.

**Fix:** produce **two** analytic panels only — coherence and pathway ratio — expressed as predicted *advantage* in log₁₀ units on the **same colour scale and colormap as page 1**, and computed at the infinite-data limit. Then either place them adjacent to the corresponding empirical panels, or plot the **difference** (measured advantage − predicted advantage), which is the most informative single view: it shows where finite records fall short of theory, which is the actual scientific content.

## B4. The realised-SNR companion — one broken panel, one important confound

Page 3 is the right idea and it did its job: it confirms that realised in-band SNR falls from ~25 dB at 0.02 Hz to roughly **0 dB at 0.30–0.35 Hz**. Exactly the concern from `PROTOCOL_FREEZE.md` §4.3, now measured rather than predicted.

Two problems:

1. **Panel 4 is unreadable.** Its colour scale runs 0–160 dB because the "No noise" row is infinite (or numerically enormous), which compresses the 10 dB and 0 dB rows into indistinguishable blue. Exclude the noiseless row from the colour scaling and render it as a separate labelled category, or cap the scale at the finite maximum.
2. **A confound the pilot has exposed.** In the pathway-ratio panel, realised SNR differs *between rows* — the ratio = 1 row has visibly lower HF SNR than the ratio = 0.25 row. That is mechanically correct (a stronger low-pass CO₂ pathway concentrates output power at low frequency, so at fixed *broadband* SNR the HF end gets relatively noisier), but it means **the pathway-ratio heatmap is partly confounded with SNR**. Any frequency structure you read off that panel is a mixture of the two.

## B5. Figure defects checklist for step 4

| # | Defect | Fix |
|---|---|---|
| 1 | Page 2 plots bias, not predicted advantage; wrong units and scale | §B3 — two panels, log₁₀ advantage, page-1 colour scale; add a difference map |
| 2 | Page 2 duration and SNR panels are constant by construction | Delete them |
| 3 | Page 3 panel 4 colour scale destroyed by the infinite row | Exclude Inf from scaling; label the noiseless row separately |
| 4 | No N annotation anywhere | Print `PairedValidN` range in each caption; grey any cell below `minimumValidN` |
| 5 | Grey-cell convention never exercised or explained | Say in every caption that grey means insufficient valid observations, not "no effect" |
| 6 | NC operating range not marked on the coherence panel | Shade or mark γ² ≈ 0.06–0.18 |
| 7 | y-axis tick labels sit near row boundaries rather than centres | Centre them; with 2–4 rows this is easy to misread |
| 8 | Captions do not state the estimand | One line: distance from the conditional generating pathway |

Items 4, 5, 6 and 8 are what a physiologist needs and none of them are currently present.

---

# Part C — The one thing that must change before the paper run

**The frequency axis currently confounds frequency with in-band SNR, and that undermines the pilot's most interesting result.**

Page 3 shows realised SNR falling ~25 dB across the reporting band. Page 1 shows MISO becoming worse than SISO at high frequency when γ² = 0.95. Two mechanisms produce that orange region, and the current design cannot separate them:

- **Collinearity.** At γ² = 0.95 the two-input solve is ill-conditioned, so MISO's variance is high everywhere.
- **Low in-band SNR.** At 0.30 Hz the local SNR is ~0 dB, and a two-parameter estimator degrades faster than a one-parameter estimator as SNR falls.

Both push the same direction. So "MISO fails at high frequency" is currently uninterpretable — it may be a statement about frequency, or a statement about SNR wearing a frequency costume. And after the §A3 spectral reshape the gradient gets steeper, making it worse.

**Fix:** add a documented noise-spectrum option and run the primary factorial with a flat in-band SNR.

```matlab
settings.observations.noiseSpectrum = "signalShaped";  % primary
% "white"        - broadband noise, current behaviour, realistic for some sensors
% "signalShaped" - noise follows the clean CBFV spectrum, so in-band SNR is
%                  constant across the reporting band and "10 dB" means 10 dB
%                  at every frequency
```

Run the primary set with `signalShaped` so any frequency dependence in the advantage map is attributable to pathway shape and coherence rather than to a hidden SNR gradient. Keep `white` as a named robustness contrast — real TCD and capnograph noise is not spectrally flat either way, and showing both is stronger than asserting one.

This is a small change with a large payoff: it is what makes the frequency axis — your preferred axis, and the whole point of the figure design — mean what a reader will assume it means.

---

# Part D — Step 4 task list, in order

**1. Per-segment detrending in `estimateWelchSpectra`** (§A4). Linear detrend of each Welch segment before windowing, simulation and real-data paths. Then re-run the step-2 characterisation and confirm the 0.02 Hz bin behaves.

**2. Re-confirm the coherence level after the detrend fix** (§A1). Recompute the bias-corrected percentiles; confirm or adjust the 0.15 level.

**3. Update the frozen levels** (§A1, §A2):
- `inputCoherence` → `[0, 0.15, 0.50, 0.95]`, provenance `"0.15 NC-derived (bias-corrected median, n=23); 0.50/0.95 engineering stress"`
- `inputPhaseLagSeconds` → `[-6, 0, +4]`, provenance `"NC-derived (10th/50th/90th fitted lag, n=23)"`

**4. Reshape the input spectra** (§A3). Monotonic decaying shape fitted to the measured NC median over 0.033–0.35 Hz; freeze the fitted parameters; record them in the manifest. Keep `spectralSimilarity = 1` — step 2 supports it.

**5. Add the `noiseSpectrum` option and make `signalShaped` the primary** (§C).

**6. Rebuild the analytic reference as predicted advantage** (§B3): two panels, log₁₀ units, page-1 colour scale, plus a measured-minus-predicted difference map.

**7. Fix the figure defects** in §B5 — items 3 through 8 are all small and all improve readability for a non-methodologist reader.

**8. Add the two new results figures:**
- Predicted advantage at γ² = 0.15 overlaid on the measured NC prediction advantage (§B2).
- Minimum detectable advantage for the NC design (§A5).

**9. Write the two-mechanism framing into the protocol document** (§B2). This is the paper's scientific spine and it currently exists nowhere.

Items 1–3 are prerequisites for everything else and should land together. Items 4–5 change generated data, so they force a re-run — do them before the production run, not after. Items 6–8 are presentation only and can proceed in parallel.

---

# Part E — Acceptance criteria to add

Extending `PROTOCOL_FREEZE.md` §6:

8. **Per-segment detrending.** A signal with a known linear trend added produces the same spectra, to a declared tolerance, as the same signal without it.
9. **Noise spectrum.** With `noiseSpectrum = "signalShaped"`, realised in-band SNR is constant across the reporting band to within 2 dB.
10. **Analytic reference agreement.** In the noiseless, long-duration limit, measured advantage approaches predicted advantage to within a declared tolerance. This is the test that proves the analytic panel and the simulation are computing the same quantity.
11. **Coherence bias correction.** The corrected estimator recovers a known γ² from synthetic data with n = 8 averages to within Monte Carlo error.

---

# What I could not verify

- **MATLAB did not run.** All numerical claims here come from independent re-implementation, not from executing your code.
- **I did not see the exported tables** — `subjectQuantiles`, `ValidPhaseBinCount`, `EffectiveWelchAverages`, `PairedValidN`, or the frequency tables behind the heatmaps. The figures and `STEP2_NC_INPUT_AUDIT.md` were my only sources, so the coherence and lag numbers are as reported there. The n = 8 effective averages is inferred from the CARNet threshold of 0.22 shown in the figure matching the table entry at 8 windows; worth confirming against the exported column.
- **The 0.02 Hz contamination diagnosis** is inferred from coherence ≈ 1.0 plus a 26 dB spectral spike at a single DC-adjacent bin, together with the absence of per-segment detrending in the code. It is a strong inference, not a direct measurement. Task 1 will confirm or refute it.
- **NC spectral values** were read off the step-2 figure, so the reshape fit in task 4 must use the exported table, not my figure-derived numbers.

---

*Steps 2 and 3 reviewed. §A1 and §A2 close the two PROVISIONAL level decisions; §A3 fires the reshape trigger; §D is the step 4 task list.*
