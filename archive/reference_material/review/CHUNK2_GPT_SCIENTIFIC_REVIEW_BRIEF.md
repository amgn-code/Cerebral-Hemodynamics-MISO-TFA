# Chunk 2 GPT scientific review brief

## Purpose

Perform one bounded scientific review of the consolidated standalone project.
Return a single decision document that Sol can implement in the final chunk.
Do not broaden the simulation merely because additional factors are possible.

## Read first

1. `review/PROTOCOL_FREEZE.md`
2. `review/STEP4_IMPLEMENTATION_REPORT.md`
3. `miso_tfa/docs/SIMULATION_PROTOCOL.md`
4. `miso_tfa/config/simulationFactors.m`
5. `miso_tfa/docs/CONSOLIDATION_RECORD.md`
6. `miso_tfa/output/pdf/STEP4_REVISED_SIMULATION_REPORT.pdf`

## Current verified state

- `miso_tfa` runs when copied outside the repository.
- All six public pages have zero parent-project dependencies.
- All 92 independent MATLAB tests pass.
- MATLAB Code Analyzer reports zero issues.
- The active outputs are frequency-by-factor heatmaps of
  `log10(mean SISO error / mean MISO error)`.
- NC held-out point estimates are negative across the reported frequencies,
  while the current NC-design simulation predicts positive advantage over
  most of the band.

## Decisions required

Give an explicit decision and rationale for each item:

1. **Simulation-to-NC mismatch.** State whether the simulation is a mechanism
   study whose results need not reproduce NC direction, or whether the central
   generator must be recalibrated before production. Identify the smallest
   defensible change if recalibration is required.
2. **NC-design noise assumption.** Accept, replace, or remove the assumed 10 dB
   signal-shaped CBFV noise condition. Do not invent a data-derived noise value
   unless it can be identified from the available recordings.
3. **Analytic reference.** Accept or rename the implemented finite comparator:
   `log10(analytic SISO population-target bias / finite-record MISO truth
   error)`. A literal infinite-data MISO denominator is zero.
4. **Monte Carlo precision.** Select the production precision target and
   repetition count. The Step 4 pilot projects approximately 463 repetitions
   per condition for SE 0.05; a relaxed SE 0.10 target projects approximately
   116.
5. **Final factor scope.** Confirm which factors are primary and which remain
   secondary. Preserve the small, physiologically interpretable design unless
   evidence requires a change.
6. **Claims.** Specify exactly what the simulation and NC validation can each
   support in the manuscript.

## Deliverable

Write one prioritized implementation specification. Mark every requested code,
configuration, figure, and wording change as required or optional. The final
implementation block should be able to follow it without another scientific
review cycle.
