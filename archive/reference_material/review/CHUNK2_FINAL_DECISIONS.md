# Chunk 2: final scientific decisions and Sol implementation contract

Status: bounded review completed 14 September 2026. This document supersedes
earlier proposed next-step lists where they conflict. Implement all REQUIRED
items in one final block. Preserve readable MATLAB functions and the six public
interfaces. No learned generator or extra primary factors are needed.

Review basis: protocol-freeze document, Step 4 implementation report and saved
precision table, current protocol, and targeted inspection of generation,
error scoring, NC validation, figure selection, and bootstrap code. The 92-test
result belongs to Chunk 1; no new numerical run or independent PDF inspection
was performed in this review. Existing tests establish implementation checks,
not scientific validity of every assumption.

## Decisions

### 1. Study purpose: controlled mechanism study — REQUIRED

Keep the known linear two-pathway generator. Ask when adding CO2 improves
conditional pathway recovery with finite recordings. SISO's omitted-input bias
is part of this estimand, not a programming defect. Also retain independent
held-out prediction error, which asks a different question.

NC results assess held-out prediction under this particular recording and
analysis protocol. Their negative point estimates are legitimate results.
Do not tune noise, pathway strength, or filters until simulated advantage agrees
with NC. The current simulation is informed by NC input characteristics; it is
not a validated generative model of NC physiology. Do not infer from negative
NC prediction advantage that the conditional MISO pathways are less accurate:
the true pathways are unavailable in those recordings.

### 2. Noise and NC comparison — REQUIRED

Keep Inf/10/0 dB output SNR as engineering conditions and signal-shaped output
disturbance as the declared primary assumption. Keep white noise as one
supplementary contrast. Describe output disturbance as unexplained additive
CBFV variation; signal-shaped disturbance is not an identified instrument-noise
model. Report nominal broadband SNR and realized in-band SNR separately.

Retain the existing 10 dB simulated-NC example only as an illustrative
NC-protocol scenario. Its pathway ratio, noise, and fixed dynamics have not
been estimated from NC. Rename captions saying 'predicted NC advantage' to
'illustrative simulated advantage under stated assumptions'. No data-driven
residual-noise calibration is required: residuals combine measurement noise,
omitted physiology, and model error, so these recordings do not identify pure
instrument SNR by themselves.

Remove the minimum-detectable-advantage panel and claims of demonstrated 80%
power from the default report. The current 2.8016 × bootstrap-SE calculation
uses one simulated cohort and a normal approximation, without validating a
test or its rejection rate. Retain frequency-wise bootstrap uncertainty instead.
Remove the obsolete MDA routine after replacing any useful scenario-generation
and overlay functions; do not build a new power-study subsystem.

### 3. Four primary factors, named secondary experiments — REQUIRED

Keep the existing core: coherence [0 .15 .50 .95], pathway ratio [0 .25 1],
duration [300 600] s, output SNR [Inf 10 0] dB. Keep primary reference slices
at coherence .50, ratio 1, duration 300 s, SNR 10 dB so existing precision
planning remains applicable. Explicitly label .50 as the stress-reference
slice, not typical NC. Mark .15 as an approximate NC-informed scenario.

Create an actual E2 run, not just a settings field: cross lags [-6 0 4] s
with coherence [.15 .50 .95], at ratio 1, 300 s, 10 dB. Reuse the current
generator and runner; do not change the primary factorial. Positive lag means
CO2 occurs later than MAP. Export frequency × lag × advantage with separate
panels for coherence. Verify the sign on a known delayed signal.

E3: separate MAP and CO2 input-noise panels at [.50, ratio 1, 300 s, 10 dB
output SNR], with input SNR [Inf 10 0]. E4: alignment [-3 0 3] s at that
same reference. White-output-noise contrast uses the same reference and [10 0]
dB. Secondary plots must select their named observation rows explicitly. They
must not silently pool core scenarios or additional observation variants.

The empirical lag fit is only an equivalent delay over selected coherent bins.
The current bias correction uses an approximate effective-average count which
does not fully account for Hann-bin/overlap correlations. Label corrected
coherence and fitted lags approximate, and show raw values alongside them in
the audit. Neither .15 nor [-6 0 4] constitutes a validated physiological range.
No elaborate calibration expansion is needed for this mechanism study.

### 4. Analytic reference — REQUIRED

Keep the analytic population SISO target and its normalized squared bias as a
verification quantity. Retire the hybrid 'analytic advantage' and
'empirical-minus-analytic advantage' from default figures. They are not an
independent theoretical prediction of MISO performance. Algebraically, their
difference cancels the MISO denominator and becomes log10(empirical SISO
error / analytic SISO bias), when all means use identical records.

Replace that page with a simple supplementary comparison of analytic squared
SISO bias, empirical SISO mean squared error, and empirical MISO mean squared
error on the same normalization. Preserve the long-record convergence test.
Do not require equality at finite record length: tapering, detrending,
smoothing, leakage, and estimation variability affect it. The primary heatmaps
remain advantage-only. For companion comparisons, use one paired finite mask
for all quantities, and export sample counts. Show exact zero honestly.

### 5. Production precision — REQUIRED

Retain the previously agreed target MCSE 0.05 log10 units. Start production at
500 repetitions per core condition, rounding the saved R=463 projection up.
This entails 6,000 core families and 102,000 analyses if all 17 existing plans
are retained. Run E2 separately at 500 repetitions per phase/coherence cell.
Compute time does not require prolonged model reasoning or repeated narration.

Expose target MCSE and repetitions in one production configuration rather than
duplicating the 0.05 literal. Use 2,000 paired bootstrap draws for final
uncertainty. Audit achieved MCSE over finite primary cells and report the
fraction meeting the target, maximum SE, valid N, and failed-estimate counts.
R=500 is a pilot-based choice, not a guarantee. If the maximum exceeds .05,
allow one predeclared append to ceil(500*(observedMaxSE/.05)^2), rounded up
to the next 50, capped at 1,000. Preserve existing family draws. If still above
target, report the attained precision instead of endless reruns. Apply the
precision target to primary figures; report secondary precision without
claiming it also passed. Store seeds, settings, source tables, and manifests.

MCSE .05 means about a factor 1.12 for one standard error of the error ratio;
it does not mean a 95% interval of ±12%. NC subject-bootstrap SE describes
sampling uncertainty across subjects, not simulation Monte Carlo precision.

## Specific implementation checks — REQUIRED

1. `settings.secondary.inputPhaseLagSecondsValues` currently has no consuming
   run path (text search found its declaration only). Complete E2 explicitly.
2. Both NC block-averaging implementations update numWindows but retain the
   first block's effectiveAverages. Recompute that metadata after averaging;
   do not describe approximate null-coherence references as empirical null
   distributions. Use one small shared block-spectrum averaging helper if the
   illustrative NC scenario is retained. Confirm prediction scores remain
   unchanged by this metadata correction.
3. Change the quick-start variable `simulationSettings = simulationSettings(...)`
   to `simSettings` so rerunning the script does not shadow the function.
4. Production primary slices must fail clearly if their reference condition is
   absent. Restrict `selectRowsWithFallback` to smoke profiles; never silently
   pool different conditions in a production map.
5. Label CO2 contribution share as 'share of separate pathway powers'. The
   denominator excludes covariance and is not total observed CBFV variance.
6. Label NC intervals pointwise 95% bootstrap intervals, not a simultaneous
   confidence band. Average folds within subject before resampling subjects;
   the folds are not independent participants. Keep paired finite masks.
7. Describe the 0.02 Hz cutoff accurately: retained NC bins start at 2/90 =
   0.0222 Hz; the simulation starts at 2/100 = .02 Hz. These grids need not
   match. Do not silently align them by row number in overlays.

## Final deliverable and acceptance — REQUIRED

Run the existing independent tests plus focused acceptance checks for E2,
secondary slice membership, corrected block metadata, and production slices.
Do one full final simulation and NC rerun, saving results before rendering.
Verify deterministic replay on a manageable saved subset. Confirm each exported
heatmap agrees with its source table and carries settings and valid N.

Produce one final visual PDF: workflow diagram, factor/provenance table, four
primary MAP heatmaps, supplementary CO2 recovery and E2/E3/E4 plots, noise
contrast, analytic-error check, NC advantage with uncertainty, and precision
summary. Reuse plotting/export functions. State that the linear generator is
favorable to correctly specified MISO by construction and delineates when its
finite-sample cost outweighs its benefit. Do not claim universal superiority.

After verified replacement, delete superseded executable parent workflows and
their legacy tests (`src`, `platform`, `studies`, `main.m`). Inspect project
startup/path metadata before deleting it. Retain unique manuscripts, source
papers, and presentation assets. Retire model_generator research material only
after checking for unique material still cited. Make the root README point to
the standalone project. Keep one current protocol, this decision record, and
one final report entry point; consolidate obsolete runtime profiles only after
replay compatibility is considered. No automatic commit or tag is required.

## Evidence and scope

- [CARNet 2022 update](https://pmc.ncbi.nlm.nih.gov/articles/PMC9875346/)
  supports standardized acquisition, spectral estimation, and reporting. It
  does not validate our chosen pathway constants or output-noise levels.
- [Morris, White and Crowther, 2019](https://pmc.ncbi.nlm.nih.gov/articles/PMC6492164/)
  supports explicit aims, generator, estimands, methods, performance measures,
  and reporting Monte Carlo uncertainty. The numeric precision target is our
  study-design choice.

No further scientific-review handoff is necessary for these decisions. If a
required acceptance check fails, repair it and rerun the affected checks; if a
scientific result is negative or imprecise, preserve and report it.
