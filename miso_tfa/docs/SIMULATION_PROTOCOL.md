# Final simulation protocol

## Aim and estimand

This is a controlled linear mechanism study. It asks when a two-input MISO
estimate recovers the known conditional MAP-to-CBFV and CO2-to-CBFV pathways
more accurately than two separate SISO estimates. It does not learn a
physiological transfer-function distribution and it is not tuned to make MISO
win on the NC recordings.

At each retained frequency, the primary score is

```text
advantage = log10(mean paired SISO squared error /
                  mean paired MISO squared error)
```

Positive values favor MISO, zero is equal mean error, and negative values favor
SISO. A family supplies both estimates, so every summary uses a shared paired
finite mask. MAP-pathway recovery is primary. CO2-pathway recovery is reported
as a supplement.

The generator is favorable to correctly specified MISO by construction: CBFV
is the sum of filtered MAP and CO2 pathways plus an unexplained output term.
The scientific result is therefore the frequency and recording conditions in
which MISO's finite-sample cost outweighs, equals, or improves on SISO. The
study cannot establish universal MISO superiority or population reference
ranges.

## Fixed analysis

- Sampling is 4 Hz, so the Nyquist frequency is 2 Hz.
- Results are reported only from 0.02 to 0.35 Hz. Simulation bins begin at
  2/100 = 0.02 Hz; retained NC bins begin at 2/90 = 0.0222 Hz.
- Welch spectra use 100-second Hann windows, 50% overlap, linear detrending
  within every segment, and three-bin smoothing.
- The input spectrum is the NC-derived monotonic shape
  `1/(1+(f/0.0290)^2.5514)`. Its fitted shape is used as a plausible operating
  spectrum, not as proof of a physiological range.
- MAP and CO2 pathway time constants are fixed at 3 and 5 seconds. The CO2
  pathway delay is fixed at 3 seconds.
- The pathway scaling band equals the 0.02-0.35 Hz reporting band. This only
  makes the assigned pathway-gain ratio reproducible; it is not a separate
  calibration experiment.
- Random streams, settings, family seeds, source tables, and manifests are
  saved. Increasing the repetition count preserves the existing family prefix.

## Factor design

The primary core has 12 mechanism conditions crossed with six paired
observations per family.

| Factor | Levels | Interpretation |
| --- | --- | --- |
| MAP-CO2 input coherence | 0, 0.15, 0.50, 0.95 | 0 is an independent control; 0.15 is NC-informed; 0.50 and 0.95 are stress levels |
| Assigned CO2-to-MAP pathway gain ratio | 0, 0.25, 1 | Mechanistic pathway levels; realized contribution is a share of separate pathway powers |
| Recording duration | 300, 600 s | Finite-record variance |
| CBFV output SNR | Inf, 10, 0 dB | Primary signal-shaped unexplained output variation |

The following experiments are separate so their effects remain readable.

| Experiment | Levels | Fixed reference condition |
| --- | --- | --- |
| E2 CO2 lag relative to MAP | -6, 0, 4 s at coherence 0.15, 0.50, 0.95 | pathway ratio 1; 300 s; 10 dB output SNR |
| E3 MAP input SNR | Inf, 10, 0 dB | coherence 0.50; pathway ratio 1; 300 s; 10 dB output SNR |
| E3 CO2 input SNR | Inf, 10, 0 dB | same reference, varied separately from MAP noise |
| E4 CO2 measurement alignment error | -3, 0, 3 s | same reference |
| Output-noise shape contrast | white noise at 10 and 0 dB | same reference |

MAP-CBFV and CO2-CBFV phase are generated outcomes of the input relation and
the two pathways. They are not independently assigned factors.

## Verification and uncertainty

The analytic companion contains three quantities on the same truth
normalization: analytic population SISO squared bias, empirical SISO mean
squared error, and empirical MISO mean squared error. It is a verification
view, not another advantage endpoint. The long-record convergence test checks
the population SISO target while allowing finite-record leakage, detrending,
tapering, smoothing, and sampling variation.

Production starts at 500 repetitions per condition and uses 2,000 paired
bootstrap draws. The precision target is a maximum primary-cell Monte Carlo
standard error of 0.05 log10 units. If the observed maximum exceeds 0.05, one
predeclared extension is allowed:

```text
ceil_to_50(500 * (observed maximum SE / 0.05)^2), capped at 1000
```

The final precision table reports the maximum SE, fraction of finite primary
cells meeting the target, paired sample counts, and failed estimates. If one
extension still misses the target, the attained precision is reported.

NC validation answers a different question. It averages the two disjoint
training-block spectra, predicts the third block, rotates the held-out block,
averages folds within subject, and then bootstraps subjects. Its intervals are
pointwise 95% subject-bootstrap intervals. The illustrative NC-protocol
simulation uses stated 10 dB output-noise assumptions and is not calibrated
from NC residuals.

## Reproduction

```matlab
restoredefaultpath
cd("/path/to/miso_tfa")
setup;

output = defaultSimulationOutputSettings("off");
output.createFigures = false;
study = runFinalSimulationStudy(500, output);
exportFinalSimulationStudy(study, fullfile(pwd, "output", "final"));

nc = ncBootstrap("/path/to/ieem_data");
illustrative = simulateIllustrativeNcProtocolScenario(23, 2000);
createFinalMisoTfaReport(study, nc, illustrative, ...
    fullfile(pwd, "output", "final"));
```

Run `runFinalSimulationStudy(1, output)` only as a wiring smoke check. Use the
production repetition count for scientific figures.
