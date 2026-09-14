# Simulation protocol

This document describes the default `simple` profile in the independent
project. It is the implementation contract for a pilot run, not a claim that
the listed engineering levels are population reference intervals.

## Question and estimand

The simulation asks when a joint MAP/CO2 model recovers the generating
MAP-to-CBFV and CO2-to-CBFV pathways more accurately than separate SISO
models. The primary target is conditional pathway recovery: each estimated
transfer function is compared with the known filter that generated it. SISO
omits the other input by design, so its omitted-input bias is part of the
comparison.

The frequency-resolved score is

```text
advantage(f) = log10(mean SISO error(f) / mean MISO error(f))
```

Positive color means lower average MISO error. The primary complex error
combines gain and phase discrepancy. Gain and phase errors remain available as
supporting quantities where the true pathway has sufficient gain. Coherence,
condition number, and null-reference values explain the result; they are not
additional accuracy endpoints.

## Fixed signal and analysis choices

- Sampling rate: 4 Hz; Nyquist frequency: 2 Hz.
- Reporting band: 0.005–0.35 Hz.
- Pathway calibration band: stored separately from the reporting band and
  fixed before the random signal draw.
- MAP and CO2 input spectra, pathway shapes, Welch settings, and pathway delay
  are fixed in the simple profile.
- Each family is generated once at the longest requested duration. Shorter
  observations are prefixes of the same family.
- Training and validation realizations have separate deterministic seeds.

## Conditions

The default simple profile contains nine clean physiology families:

| Condition | Levels | Role |
|---|---:|---|
| MAP–CO2 input coherence | 0, 0.50, 0.95 | input separability |
| Relative CO2 pathway gain | 0, 0.25, 1 | effect of omitting CO2 |

Each family receives the following paired observations:

| Observation factor | Levels | Role |
|---|---:|---|
| Recording duration | 300, 600 s | finite-record variance |
| CBFV output SNR | Inf, 10, 0 dB | output measurement disturbance |
| MAP input SNR | Inf, 10, 0 dB | MAP measurement disturbance, separate check |
| CO2 input SNR | Inf, 10, 0 dB | CO2 measurement disturbance, separate check |
| CO2 alignment error | -3, 0, +3 s | secondary acquisition robustness |

The default profile therefore runs 9 families × 15 observation plans. MAP and
CO2 input-noise plans are separate so a combined input-noise condition cannot
be mistaken for an output-noise effect. Input phase is implemented as an
explicit MAP–CO2 factor, but remains fixed at zero in this profile until its
levels are supported by NC data or cited physiology. When enabled, the phase
rotation uses signed FFT frequencies so the generated signals remain real.

MAP–CBFV and CO2–CBFV phases are generated consequences of the input pair and
the two pathway filters. They are reported outputs, not independent settings.

## Figures and validation

The simulation interface returns frequency-by-condition advantage heatmaps.
Frequency is horizontal, the selected factor or diagnostic is vertical, and
color is the paired MISO-versus-SISO advantage. Band-averaged values are
synopses. Diagnostic maps use per-frequency coherence bins and retain valid
counts.

NC validation is a separate real-data workflow. It fits on two contiguous
training blocks, evaluates on the held-out block, masks frequencies above each
recording's usable Nyquist frequency, and bootstraps subjects. Its advantage is
held-out prediction advantage, not known-truth accuracy.

Before a paper run, replace or confirm provisional levels in
`config/simulationFactors.m` and save the resulting settings and manifest with
the exported simulation archive.
