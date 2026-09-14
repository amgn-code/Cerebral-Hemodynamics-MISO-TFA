# Step 2 NC input audit

The independent NC workflow was run on:

```text
/Users/amoghn/Desktop/ieem_data
```

The loader found 24 NC files. Twenty-three completed acquisition cleanup,
resampling, and spectral characterization; the same 23 were usable for the
three-fold blocked prediction validation. The analysis used 4 Hz resampling,
90 s non-overlapping Welch windows, and the frozen 0.02–0.35 Hz reporting
band. Frequencies above a recording's native beat-to-beat Nyquist were masked.

## Deliverable 1: MAP–PETCO2 coherence

For each subject, ordinary coherence was averaged over 0.02–0.35 Hz. Across
the 23 subject averages, the 10th, 50th, and 90th percentiles were:

| Percentile | Band-mean coherence |
|---:|---:|
| 10th | 0.1812 |
| 50th | 0.2395 |
| 90th | 0.2822 |

The provisional primary input-coherence levels therefore remain `[0 0.50
0.95]` until the scientific reviewer decides whether the upper engineering
levels should be brought closer to the observed NC distribution. Zero remains
as the independent-input control.

## Deliverable 2: MAP–PETCO2 cross-spectral phase

Phase was retained only where ordinary coherence exceeded the CARNET reference
threshold for that subject's effective Welch averages. For each subject, the
unwrapped phase was regressed against frequency; with the project sign
convention, positive lag means PETCO2 lags MAP.

| Quantity | Value |
|---|---:|
| 10th percentile fitted lag | −6.17 s |
| Median fitted lag | 0.27 s |
| 90th percentile fitted lag | 3.68 s |
| Median linear-fit R² | 0.72 |

The fit quality is adequate for a descriptive lag summary, but the spread is
wide and a single lag is not a complete description of every recording. The
secondary phase experiment therefore remains declared as the stress set
`[-4 0 +4]` s pending review; the subject-level and frequency-level tables
are exported so that this decision is auditable.

## Deliverable 3: measured input spectra

`inputCharacterization.power.frequencyTable` reports subject mean, median, and
standard deviation of MAP and PETCO2 power in dB for each retained frequency.
These spectra are descriptive evidence for a later generator-shape decision;
the current Gaussian input shape is not silently changed by Step 2.

## Reproduction

```matlab
setup;
settings = defaultNcBootstrapSettings;
settings.plot.enabled = false;
results = ncBootstrap("/Users/amoghn/Desktop/ieem_data", settings);
exportNcBootstrapResults(results, "output/nc_step2");
```

The output folder contains the held-out bootstrap table, subject audit table,
and four Step 2 input-characterization tables. The bootstrap seed and all
preprocessing choices are stored in the MAT result archive.
