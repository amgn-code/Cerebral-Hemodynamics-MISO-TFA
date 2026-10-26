# Step 1 — Scientific protocol freeze

**Reviewer:** Claude, acting as scientific reviewer per the agreed plan.
**Branch reviewed:** `codex/independent-miso-tfa` at `fb04665`.
**Scope:** the four step-1 decisions. This document is the implementation contract for Sol. Where it says **FROZEN**, the value does not change again without a new review. Where it says **PROVISIONAL**, the value is a placeholder with a named source that must supply it before the paper run.

This supersedes `miso_tfa/docs/SIMULATION_PROTOCOL.md` on every point where they differ. Sol should update that file to match this one.

---

## 0. What the independent branch already closed

I re-audited `miso_tfa/` against the Tier-1 and Tier-2 findings in `review/PROJECT_REVIEW.md`. Good progress — five are closed:

| Finding | Status on `fb04665` |
|---|---|
| S2 — truth depends on analysis band | **Closed structurally.** `settings.pathways.calibrationBandHz` exists and is the only thing `generateKnownTruthRealization.m:70` reads. Still needs the freeze in §4 and the regression test in §6. |
| S3 — no MAP–CO₂ input cross-phase | **Closed.** `generateKnownTruthRealization.m:42–43` applies `exp(1i*inputPhaseRadians)` to the shared spectrum; `inputPhaseLagSeconds` is a family factor. |
| S4 — uncorrected coherence bias | **Closed.** `nullMultipleCoherence` and `nullOrdinary` are computed and stored. |
| N2 — band above beat-to-beat Nyquist | **Closed.** `runNcSubjectBlockedValidation.m:37,96` masks per subject and records `UsableNyquistFrequencyHz`. |
| C1 — factor provenance | **Closed.** `config/simulationFactors.m` carries a provenance string per factor. |
| R3 — no replay | **Closed.** `modules/simulation/replaySimulation.m` + `tests/replaySimulationTest.m`. |

Four remain open and three of them block the freeze:

| Finding | Status | Blocks freeze? |
|---|---|---|
| S5 — ridge explained power | **Open.** `runMISOTFA.m:76–77` still uses `real(S_xy'*H)/S_yy`. | Yes — §5.1 |
| R1 — realisation length tied to the duration list | **Open.** `createKnownTruthFamily.m:6–8` still takes `max(durationSeconds, reference)`. | Yes — §5.2 |
| R2 — design assignment depends on `numFamilies` | **Open.** Still one global stream (`:15–17`); `familySeed = randomSeed + 1000*familyId` (`:39`). | Yes — §5.3 |
| S1 — estimand framing / analytic reference | **Open.** `projectSettings.m:14` declares a `secondaryEstimand` string; nothing implements it. | Yes — §3.4 |

---

## 1. Decision — factor set, levels, provenance

### The problem with the current list

`config/simulationFactors.m` marks **seven** factors `primary = true`, and `SIMULATION_PROTOCOL.md` runs 15 observation plans per family. That is drifting back toward the thing this whole exercise was meant to fix. Two of the seven — `mapMeasurementSnrDb` and `co2MeasurementSnrDb` — are the same concept (input measurement quality) counted twice.

### FROZEN: four core factors, three secondary experiments

**Core.** These define the primary figure set. Nothing else appears in a primary figure.

| # | Factor | Levels | Status | Provenance |
|---|---|---|---|---|
| 1 | MAP–CO₂ input coherence γ | 0, 0.50, 0.95 | **PROVISIONAL** | Replace with the 10th / 50th / 90th percentile of measured NC MAP–CO₂ ordinary coherence, averaged over 0.02–0.35 Hz. **Source: step 2.** Keep 0 as an added fourth level — it is the independent-input control and must not be dropped. |
| 2 | Relative CO₂ pathway strength | 0, 0.25, 1 | **FROZEN as engineering levels** | Deliberate stress design, not a physiological range. 0 is the omitted-pathway control. Label all three "methodological stress test" and additionally report the *realised* CO₂ contribution share to CBFV for each, which is the interpretable quantity. |
| 3 | Recording duration | 300, 600 s | **FROZEN** | 300 s is the CARNet 2022 minimum for a resting TFA recording and matches the NC protocol. 600 s is the doubling check, not a claim that 10-minute resting records are standard. |
| 4 | CBFV output SNR | Inf, 10, 0 dB | **FROZEN as engineering levels** | Stress levels. Must be labelled **broadband** SNR — see §4.3, this matters more than it looks. |

Factors 1 and 2 are family-level (they change the generated physiology, so they multiply scenarios). Factors 3 and 4 are observation-level (they are paired conditions on the same realisation, so they do not). Core grid: **3 × 3 = 9 scenarios, 2 × 3 = 6 paired observations each.**

**Secondary.** Each is a separately named experiment run at the reference condition (γ = 0.50, gain ratio = 1, 300 s, 10 dB). Each gets its own figure in a supplement, not in the primary set.

| Experiment | Factor | Levels | Status |
|---|---|---|---|
| E2 — input timing | MAP–CO₂ input phase lag | −4, 0, +4 s | **PROVISIONAL** — see §2 |
| E3 — input measurement quality | Input SNR, **with a channel label** (MAP or CO₂) rather than two separate factors | Inf, 10, 0 dB × {MAP, CO₂} | **FROZEN as engineering levels** |
| E4 — acquisition alignment | CO₂ measurement misalignment | −3, 0, +3 s | **FROZEN.** ±3 s is roughly one breath and is a plausible sampling-line/processing error. Keep strictly separate from the pathway delay and from E2. |

That is **seven varied parameters total**, inside your stated 5–7 target, with only four of them in the primary figures.

### FROZEN: everything else is held fixed

CO₂ pathway delay (3 s), MAP and CO₂ pathway time constants (3 s, 5 s), MAP high-frequency gain (1.5) and low-frequency fraction (0.25), input spectral shapes, input SD ratio (1), Welch settings (100 s, 50 % overlap, Hann, 3-tap smoothing), sampling rate (4 Hz).

The pathway shapes have qualitative literature support — Mitsis et al. 2004 report a high-pass pressure response, a low-pass CO₂ response, and an approximately 3–4 s CO₂ delay. That supports the **shapes**. It does not validate the specific gains or time constants, so label them "literature-supported shape, engineering parameterisation". Do not write "physiological range" anywhere near them.

### FROZEN: repetitions are computed, not chosen

Delete the hard-coded `numFamilies` from the user-editable surface for full-factorial designs; derive it as `prod(cellfun(@numel, valueSets)) * repetitionsPerCondition`.

Run a pilot at `repetitionsPerCondition = 20`, compute the Monte Carlo standard error of the advantage in the noisiest primary cell, and solve for the R that gives **SE ≤ 0.05 in log₁₀ units** (≈ ±12 % on the error ratio). Report that calculation in the methods. Plan for R ≈ 50 — that gives 450 families and about 2,700 primary analyses, roughly an order of magnitude below the proof-250 run.

---

## 2. Decision — input phase

**FROZEN: input phase is a named secondary experiment (E2), not a core factor. It does not enter the primary 3 × 3 factorial. It is not left permanently at zero.**

Three reasons:

1. **Not core.** Adding it to the factorial makes it 3 × 3 × 3 = 27 scenarios for a factor whose levels currently have no empirical support. That is a 3× cost increase to explore a direction we cannot yet justify, and it breaks the "a physiologist can read the primary figure" requirement.
2. **Not fixed at zero.** Zero cross-phase is the special case in which the SISO omitted-input bias is a *real* scaling of the CO₂ pathway. At non-zero lag the bias rotates with frequency and SISO's phase error develops structure the zero-lag design cannot produce. Freezing at zero would mean the study never examines the one regime where the answer might differ, and it is the factor you asked for directly at `Notes.md:309`.
3. **It is already built.** The generator implements it. The only decision left is what to sweep and when.

**E2 design:** 3 phase lags × 3 coherence levels at fixed gain ratio = 1, at the reference duration and SNR. Nine scenarios, its own figure.

**Sign convention — FROZEN, and write it in the code comment, not only in the docs:**

> A **positive** `inputPhaseLagSeconds` means PETCO₂ **lags** MAP: the CO₂ fluctuation occurs later in time. It is applied to the shared component before CBFV is generated, so it changes the physiology being simulated, not the observation of it.

**Levels are PROVISIONAL.** [−4, 0, +4] s is a placeholder. The right source is your own data: **step 2 must report the distribution of measured MAP–PETCO₂ cross-spectral phase across the 23 NC recordings, restricted to frequencies where input coherence exceeds the CARNet significance threshold.** Convert the central tendency and spread to equivalent lags in seconds and set the three levels from them. If the measured phase is not interpretable as a single lag across the band — which is likely, and fine — say so and keep [−4, 0, +4] as declared stress levels rather than pretending they are physiological.

This gives step 2 a concrete deliverable beyond "does the loader work".

---

## 3. Decision — primary metrics and heatmap layout

### 3.1 FROZEN: the estimand, stated in one sentence

> Accuracy is defined as distance from the **conditional generating pathway** — the filter that actually produced the CBFV contribution. A single-input estimator is not consistent for that target when the inputs are correlated; the comparison therefore quantifies **how much of that known gap a two-input estimator recovers from a finite record**, not whether single-input TFA is wrong.

That sentence, or a close paraphrase, goes in the methods. Without it the paper is open to the objection that you compared SISO against something it was never estimating.

### 3.2 FROZEN: one primary metric

**Normalised complex transfer-function error**, computed separately for the MAP pathway and the CO₂ pathway, MISO versus SISO, on the same paired observation, normalised by the truth-derived denominator so both estimators share it.

**Advantage** = `log10(mean SISO error / mean MISO error)`, **ratio of group means**, `ScoreVersion = "frequency-ratio-of-mean-errors-v1"`. Positive favours MISO. Bootstrap percentile interval.

**Retire the per-element log-ratio** (`calculateErrorAdvantage.m`) from everything except the NC page — see §3.5. Two definitions of "advantage" in one results struct is the fastest way to lose a reader's trust when they check a heatmap cell against the source table.

### 3.3 FROZEN: three supporting metrics, no more

| Metric | Role |
|---|---|
| Gain error | the magnitude component of the complex error |
| Circular phase error, in degrees | the timing component, reported **only** where true gain ≥ the declared threshold |
| Held-out prediction error on the independent validation realisation | shows whether the fit generalises, and is the only simulation metric directly comparable to the NC result |

Coherence, condition number, and the null references are **diagnostics that explain the result**. They are not accuracy endpoints and must not appear in the primary figure set.

### 3.4 FROZEN: every primary heatmap carries the analytic reference

This is the S1 fix and it is the single most important change in this document.

The population SISO bias is exactly `H_CO2(f) · S_map,co2(f) / S_map,map(f)`. That is a theorem, true for any generator. **The simulation's job is therefore not to discover it.** Its job is the finite-sample question: where does MISO's variance exceed SISO's bias, and how much of the theoretical separation does a 300 s record actually recover?

So every primary advantage figure gets a companion showing the advantage you would predict with infinite data. Implement it as:

```matlab
% Population SISO estimate for the MAP pathway, from the *designed*
% input spectra and the saved truth filters. No estimation involved.
sisoMapPopulation = trueMap + trueCo2 .* (designedCrossSpectrum ./ designedMapPower);
```

Then the primary figure reads "here is where finite records fall short of theory", which is a result, instead of re-deriving an identity with 2,700 Monte Carlo runs.

Also implement the declared-but-missing `secondaryEstimand`: score SISO against **its own population target** as well as against the conditional pathway. If SISO recovers its own target accurately while missing the conditional pathway, that is a much cleaner statement of what MISO buys, and it forecloses the "wrong comparison" critique entirely.

### 3.5 FROZEN: naming, so the two workflows cannot be confused

The NC page and the simulation currently share the axis label `log10(mean SISO error / mean MISO error)` while plotting different quantities. Rename:

- Simulation → **`truthRecoveryAdvantage`**, axis label `log10(mean SISO truth error / mean MISO truth error)`
- NC → **`predictionAdvantage`**, axis label `log10(mean SISO held-out prediction error / mean MISO held-out prediction error)`

And add one sentence to the results: better held-out prediction does not imply more accurate pathway separation.

The simulation already computes a directly comparable prediction advantage. **Plot it as the companion panel to the NC figure.** That gives you a genuinely strong pair — simulated prediction advantage against measured prediction advantage, same metric, same units — and lets the truth-error map stand alone as the thing only simulation can provide.

### 3.6 FROZEN: heatmap layout

Your format, made specific:

- **x = frequency**, native retained Welch bins, linear, 0.02–0.35 Hz.
- **y = the factor level** (categorical, ordered, labelled with the actual level value and unit).
- **colour = advantage**, diverging, **white/neutral exactly at 0**.
- **Colour limits symmetric and identical across the whole primary set**, chosen once from the pooled data and rounded outward to 1 decimal place. Comparability across panels matters more than per-panel contrast. Record the limit in the source table.
- **Cells below `minimumValidN` render grey and are not interpolated.** Grey means "not enough data", and the caption must say so explicitly, because a reader will otherwise read grey as "no effect".
- Every heatmap ships with its source table containing frequency, factor level, both mean errors, N, advantage, bootstrap SD, CI bounds, `ScoreVersion`, and the colour limit. Already implemented — keep it.

**Primary figure set — FROZEN at four heatmaps:** the four core factors, MAP pathway only. The CO₂ pathway set goes in the supplement. This is an autoregulation paper; MAP is the pathway of interest and four panels is what a reader will actually absorb.

**Required companions:** the analytic-reference panel from §3.4, and a realised in-band SNR row (see §4.3).

Band-averaged values are synopses only. Do not let a band average become the headline number.

---

## 4. Decision — reporting band and calibration band

### 4.1 FROZEN: reporting band 0.02–0.35 Hz. Not 0.005–0.35.

**The 0.005 Hz lower edge is not reachable.** Frequency resolution is `Δf = 1/T_window`:

| Configuration | Δf | First non-DC bin | Bins in [0.005, 0.025) |
|---|---|---|---|
| Simulation, 100 s Welch window | 0.0100 Hz | **0.0100 Hz** | 2 |
| NC blocked validation, 90 s block | 0.0111 Hz | **0.0111 Hz** | 2 |
| Legacy 128 s window | 0.0078 Hz | 0.0078 Hz | 3 |

A band edge at 0.005 Hz is below the first estimable bin in every configuration in use. The VVLF band it defines contains two bins, and the lower of those two sits adjacent to the DC bin — which mean removal drives to approximately zero and which the 3-tap smoothing kernel then mixes into it. It is the least trustworthy bin in the spectrum and currently anchors the lowest reported band.

**FROZEN band structure:**

| Band | Range | Bins at 100 s | Provenance |
|---|---|---|---|
| VLF | 0.02–0.07 Hz | 5 | CARNet 2022, unchanged |
| LF | 0.07–0.20 Hz | 13 | CARNet 2022, unchanged |
| HF (truncated) | 0.20–0.35 Hz | 15 | CARNet 2022 HF is 0.20–0.50; truncated at 0.35 Hz |

Drop VVLF entirely. The lower edge 0.02 Hz is exactly 2Δf at both 100 s and 90 s, which puts it clear of the DC-smoothing contamination, and it is CARNet's own VLF boundary — so the change is toward the convention, not away from it.

**Justification for truncating HF at 0.35 Hz**, which must appear in the methods: the NC recordings are beat-to-beat values interpolated onto a 4 Hz grid. The audited median beat interval is 0.728–1.100 s, so the native Nyquist frequency is 0.455–0.687 Hz. CARNet's 0.50 Hz upper limit assumes a properly sampled continuous signal; beat-to-beat data do not automatically qualify, and for the slowest-beating subjects 0.50 Hz is above their native Nyquist. 0.35 Hz sits below the slowest subject's limit. Keep the per-subject masking already implemented in `runNcSubjectBlockedValidation.m` as the belt-and-braces check.

### 4.2 FROZEN: calibration band 0.02–0.35 Hz, declared independently and never coupled

`settings.pathways.calibrationBandHz` defines the generated truth. `settings.analysis.reportingBandHz` defines what you plot. They currently hold the same value, which is fine — but the separation is only real if it is **tested**. See §6.

Changing the reporting band must not change a single generated sample. Today it would: the CO₂ kernel is scaled to an RMS gain ratio computed over the calibration band, and the MAP pathway is high-pass while the CO₂ pathway is low-pass, so moving the band moves their band-averaged gains in opposite directions. I measured a **46 % change in the true CO₂ pathway amplitude** between `[0.005 0.35]` and `[0.02 0.50]` for an identical assigned ratio of 1.

### 4.3 REQUIRED: report realised in-band SNR. The "SNR" labels are broadband.

This is the one thing the current protocol gets quietly wrong and it bears directly on your primary figure, because it varies along the frequency axis.

The input spectra are Gaussian, centred at 0.06 Hz with a 0.045 Hz bandwidth and a 1 % floor. Relative input power across the reporting band:

| f (Hz) | 0.02 | 0.05 | 0.10 | 0.20 | 0.30 | 0.35 |
|---|---|---|---|---|---|---|
| power relative to peak (dB) | −1.6 | 0.0 | −1.6 | −17.4 | −19.9 | −19.9 |

Output noise is broadband. So a condition labelled "output SNR = 10 dB" delivers roughly **10 dB of local SNR at 0.06 Hz and about −10 dB at 0.35 Hz**. The entire HF band — 15 of the 34 reported bins, nearly half the frequency axis — is a near-noise-floor regime wearing a 10 dB label.

**Do not change the generator to fix this now.** The right shape for the input spectra is an empirical question, and step 2 is about to measure the actual NC MAP and CO₂ spectra. Guessing a new shape before that measurement would be exactly the mistake this protocol is trying to avoid. Instead, for the frozen pilot:

1. Rename the settings and every axis label to **`broadbandOutputSnrDb`**, so the label stops implying something it does not deliver.
2. Compute and store **realised per-frequency in-band SNR** for every observation, and render it as a companion row beneath each primary heatmap.
3. State the HF limitation explicitly in the figure caption and the limitations section.
4. **Step 2 deliverable:** report the measured NC MAP and PETCO₂ power spectra over 0.02–0.35 Hz. If they carry materially more relative HF power than the current Gaussian, reshape the generator from that measurement and re-run. That is a post-freeze revision with a named trigger, not an open question.

---

## 5. Required code changes before the pilot run

Four changes block the freeze. All are small.

### 5.1 Ridge explained power — `modules/tfa/runMISOTFA.m:74–82`

Still uses the unregularised identity on penalised coefficients. Replace with the full quadratic form, which the codebase already uses correctly in `calculateFrequencyValidationPredictionError.m:35–37`:

```matlab
if cbvPowerAtFrequency > 0 && all(isfinite(H))
    residual = cbvPowerAtFrequency ...
             - 2*real(H'*S_xy) ...
             + real(H'*S_xx*H);
    multipleCoherence(frequencyIndex) = ...
        1 - max(real(residual), 0)/cbvPowerAtFrequency;
end
```

Reduces to the existing expression at λ = 0, so every unregularised result already produced stays valid.

### 5.2 Realisation length — `modules/validation/createKnownTruthFamily.m:6–8`

Still `max(durationSeconds, referenceDurationSeconds)`, so adding a duration condition redraws every signal in the study, including the shorter ones. Replace with a fixed declared constant:

```matlab
settings.generator.realizationLengthSeconds = 1200;   % FROZEN; never derived
```

Truncate to the requested duration afterwards exactly as now. The prefix property is preserved and durations become a genuine nested factor. Record it in the manifest.

### 5.3 Per-family design streams — `modules/validation/createKnownTruthFamilyDesign.m:15–17, 39`

Still one global stream sized by `numFamilies`, so going from 9 families to 18 re-assigns all eighteen rather than appending nine. Give each family its own stream:

```matlab
familyDesignSeed = settings.randomSeed + 7919*familyId;
rngFamily = RandStream("threefry", "Seed", familyDesignSeed);
```

Draw that family's nuisance parameters from `rngFamily`. Key the block index off `familyId` arithmetically rather than off a permutation of the whole set. The prime multiplier also removes the seed-collision hazard in `familySeed = randomSeed + 1000*familyId` (seed 2026 family 2 currently collides with seed 3026 family 1).

### 5.4 Analytic reference and secondary estimand — §3.4

Currently `projectSettings.m:14` declares `secondaryEstimand` as a string with no implementation.

---

## 6. Acceptance criteria

The freeze is implemented when all of these pass. Add only these tests — no others are justified by this protocol.

1. **Band independence.** Generate a family at `reportingBandHz = [0.02 0.35]`, then again at `[0.05 0.30]`, holding `calibrationBandHz` fixed. Assert `truth.mapImpulseResponse` and `truth.co2ImpulseResponse` are **bit-identical**. This is what makes §4.2 real.
2. **Ridge equivalence.** Assert the new multiple-coherence expression agrees with the old one to 1e-12 at λ = 0, and disagrees at λ = 0.1.
3. **Design stability.** Build a 9-family and an 18-family design with the same seed; assert the first 9 rows are identical.
4. **Duration independence.** Generate a family with `durationSeconds = [300 600]`, then with `[300 600 900]`; assert the 300 s observation is bit-identical in both.
5. **Replay.** Extend the existing `replaySimulationTest` to round-trip a saved manifest and reproduce the exported `frequencyMap` table bit-identically.
6. **Reachable band edges.** Assert every `frequencyBandEdgesHz` entry is ≥ `1/welch.windowLengthSeconds`. This is a one-line guard that would have caught the 0.005 Hz edge.
7. **Advantage consistency.** Assert a value read from an exported heatmap source table equals the value drawn in the corresponding cell.

---

## 7. Explicitly NOT changing

So Sol does not over-reach, and so the freeze means something:

- The MISO/SISO spectral engine. `solveMisoSpectralSystem.m` is correct — I verified the conditioning separation, the ridge scaling algebra, and the CPSD conjugation against closed forms. Leave it alone.
- The coherence identities in `calculateMisoCoherenceDiagnostics.m`. Verified against random PSD matrices. Leave alone.
- The NC blocked-validation design. Two disjoint training blocks, spectra averaged without concatenation, one held-out block. I tested it for an unfair two-input advantage and found none: with no true CO₂ pathway the advantage came out at −0.15, with a true pathway present +0.18. It is directionally sound and mildly conservative. Its weakness is statistical power, not fairness, and that is a step-2 interpretation question, not a step-1 freeze question.
- Input spectral shape — deferred to step 2 with a named trigger (§4.3).
- Pathway shapes, delays, and time constants — fixed, labelled, not swept.
- Welch settings — fixed at 100 s / 50 % / Hann / 3-tap. Window-length sensitivity is a robustness appendix, not a factor.
- The `quick`, `designSmoke`, `proof250`, `paper1000` profiles — leave them for regression comparison until the legacy tree is retired in step 5.

---

## 8. What step 2 must return

Three things, and the protocol cannot be finalised without them:

1. **NC MAP–CO₂ ordinary coherence distribution** over 0.02–0.35 Hz → sets core factor 1's levels (§1).
2. **NC MAP–PETCO₂ cross-spectral phase distribution**, restricted to frequencies above the CARNet significance threshold → sets E2's levels, or establishes that they must stay declared stress levels (§2).
3. **Measured NC MAP and PETCO₂ power spectra** over the reporting band → decides whether the generator's input spectra are reshaped (§4.3).

Everything else in step 2 is workflow validation and can proceed in parallel.

---

*Step 1 complete. Decisions in §1–§4 are frozen; §5 lists what must be implemented before the pilot run; §6 is the acceptance gate.*
