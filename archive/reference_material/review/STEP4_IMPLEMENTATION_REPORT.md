# Step 4 implementation report

This report records the implementation and numerical reruns completed from
the ordered task list in `STEP2_STEP3_REVIEW.md`. It is written for the next
scientific review. The code and results should be judged together; the
simulation-to-NC comparison exposed a substantive disagreement that should
not be hidden by further presentation changes.

## 1. Shared spectral estimator

`estimateWelchSpectra` now linearly detrends every Welch segment before
applying the Hann window and FFT. The same function is used by simulation,
NC validation, and user-data analysis.

The NC rerun removed the former single-bin artifact. At 0.0222 Hz, raw mean
coherence is now 0.331 rather than approximately 1, and the median MAP power
falls by about 0.9 dB from 0.0222 to 0.0333 Hz rather than by approximately
26 dB. The lowest retained bin no longer has the signature of a shared
linear trend.

## 2. NC calibration and frozen factor levels

All 23 usable NC recordings completed the revised characterization and
blocked validation.

- Bias-corrected subject coherence P10/P50/P90: 0.0650 / 0.1292 / 0.1768.
- Frozen primary coherence levels: `[0 0.15 0.50 0.95]`.
- Revised phase-lag P10/P50/P90: -5.83 / 0.27 / 3.77 s.
- Frozen secondary phase levels: `[-6 0 +4]` s.
- Phase percentiles require at least five retained frequency bins.

The 0.15 row is explicitly marked as the NC operating point in the primary
coherence heatmap. Values 0.50 and 0.95 remain engineering stress levels.

## 3. Input spectrum and observation noise

The primary MAP and PETCO2 generators now share the monotonic spectrum

```text
P(f) = 1 / (1 + (f / 0.0290)^2.5514)
```

The model was fitted to the combined median NC MAP and PETCO2 shapes over
0.033-0.35 Hz. Fit RMSE is 0.91 dB. The model name and both fitted parameters
are stored in the simulation settings and run manifest.

The output-noise option is explicit:

- `signalShaped` is the primary condition and follows the clean CBFV
  amplitude spectrum.
- `white` is retained as a separate robustness experiment.

Across repeated generated recordings, the mean realized signal-shaped SNR
stays within 2 dB of its requested value across the reporting band. The
no-noise row is excluded from SNR color scaling and appears gray.

## 4. Revised factor and observation design

The core design contains 12 conditions: four coherence levels crossed with
three CO2-to-MAP pathway ratios. Each repetition receives 17 paired
observation plans: the main duration/output-SNR grid, separate MAP and CO2
input-noise checks, alignment checks, and finite white-output-noise
robustness rows. Phase remains a separate E2 experiment rather than expanding
the primary grid.

## 5. Analytic reference

Only coherence and pathway-ratio panels are shown. The analytic reference is
on the same log10 scale and colormap as the empirical maps, followed by an
empirical-minus-reference panel. Zero analytic-bias conditions are gray.

There is one necessary interpretation change from Claude's request. A literal
infinite-data advantage is undefined or infinite because the correctly
specified MISO estimator has zero truth error in that limit. The implemented
finite comparator is

```text
log10(analytic SISO population-target bias / finite-record MISO truth error)
```

This isolates the analytic SISO bias mechanism while retaining a finite
denominator on the empirical plot scale. The long, noiseless-record test
checks that empirical SISO error approaches this analytic population bias.
The scientific reviewer should confirm this naming and interpretation before
manuscript use.

## 6. Revised pilot and precision planning

The production-sized Step 4 pilot used 20 repetitions per core condition:

- 240 independent families.
- 4,080 observation analyses.
- Worst paired-bootstrap SD: 0.2405 log10 units at 0.12 Hz in the 0 dB
  output-noise slice.
- Projected repetitions for a 0.05 log10 Monte Carlo SE: 463 per condition.

The projection remains a planning result. It is not an automatic production
sample-size choice.

## 7. Exact NC-design sensitivity and validation result

The new sensitivity run uses the NC protocol exactly at the analysis level:
23 independent simulated subjects, three 90 s blocks, two training spectra,
one held-out spectrum, coherence 0.15, pathway ratio 1, and 10 dB
signal-shaped output noise.

- Predicted advantage range: -0.065 to 0.609 log10 units.
- Minimum detectable positive advantage: 0.136 to 0.320 log10 units,
  depending on frequency, for two-sided alpha 0.05 and 80% power.
- Measured NC advantage range: -0.440 to -0.077 log10 units.

The measured NC curve is below zero across the reported point estimates,
while the revised simulation predicts a positive advantage over most of the
band. The NC data therefore do not validate the current generator's central
prediction. This is now the most important scientific result to resolve.
Potential explanations include the assumed 10 dB NC noise level, unmodeled
time variation or nonlinear physiology, input measurement error, and a
simulation residual structure that remains more favorable to MISO than the
real recordings. These are hypotheses for review, not post hoc factors to add
automatically.

## 8. Artifacts and verification

Primary visual artifact:

```text
miso_tfa/output/pdf/STEP4_REVISED_SIMULATION_REPORT.pdf
```

Supporting source tables and MAT files are under `miso_tfa/output/pdf` and
`miso_tfa/output/data`. The report has six visually inspected pages: primary
heatmaps, analytic reference/difference, SNR diagnostics, NC calibration,
simulation-versus-NC overlay, and minimum detectable advantage.

The complete independent MATLAB test suite passed. Added acceptance checks
cover segment detrending, signal-shaped SNR, the eight-average coherence-bias
correction, recovery of known monotonic-spectrum parameters, and long-record
agreement with analytic SISO bias. MATLAB Code Analyzer reports no issues in
the Step 4 files, and `git diff --check` passes.

## 9. Decisions requested from scientific review

1. Confirm the finite analytic-bias reference described in Section 5.
2. Decide whether the 10 dB signal-shaped output-noise assumption is an
   acceptable NC sensitivity condition or must be calibrated from recordings.
3. Interpret the direction mismatch between simulated and measured NC
   prediction advantage before approving a larger production simulation.
4. Decide whether 0.05 log10 Monte Carlo SE is necessary; it currently implies
   463 repetitions per core condition.
