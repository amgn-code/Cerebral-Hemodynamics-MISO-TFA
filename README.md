# Cerebral Hemodynamics Transfer Function Analysis

This MATLAB project analyzes the frequency-domain relationships between mean
arterial pressure (MAP), end-tidal CO2, and cerebral blood flow
velocity/CBV. It supports both:

- MISO analysis: MAP and CO2 are solved together as inputs to CBV.
- SISO analysis: MAP-to-CBV and CO2-to-CBV are solved independently.

The project can analyze one subject, a batch of subjects, or a generated
synthetic signal.

## Analysis Models

At each frequency, the MISO model is:

```matlab
S_xx = [S_mapmap, S_mapco2;
        S_co2map, S_co2co2];

S_xy = [S_mapcbv;
        S_co2cbv];

H = S_xx \ S_xy;
```

The two transfer functions are:

```matlab
H_mapcbv = H(1);
H_co2cbv = H(2);
```

The current MISO solve intentionally uses the direct spectral-matrix
solution without regularization or SISO fallback logic. The condition
number is stored as a diagnostic so alternative solving methods can be
evaluated later.

The SISO transfer functions are:

```matlab
H_mapcbv = S_mapcbv ./ S_mapmap;
H_co2cbv = S_co2cbv ./ S_co2co2;
```

## Project Flow

```text
main.m
└── runTFA
    ├── single: load one subject
    ├── synthetic: generate one subject
    └── batch: load each discovered subject
        └── analyzeSubjectTFA for every subject
```

`runTFA` selects the data source and determines whether the subject analysis
runs once or once per discovered subject. `analyzeSubjectTFA` performs the
same common workflow for every loaded or generated subject:

1. Preprocess the time-series arrays.
2. Check the available Welch windows.
3. Estimate and smooth the shared Welch spectra once.
4. Run the enabled MISO and/or SISO models from those spectra.
5. Limit the returned results to the selected analysis range.
6. Create the selected subject figures.

Batch processing subsequently organizes successful subject results into
group arrays, means, and standard deviations for plotting. After all
attempted subjects finish, `runTFA` writes the selected Excel metric sheets
using the same format for single, synthetic, and batch runs.

## Data Loading and Preprocessing

`loadSubjectData` reads the required time, MAP, CO2, and CBV columns from an Excel
worksheet and stores each signal as a horizontal array:

```matlab
signalData.t
signalData.map
signalData.co2
signalData.cbv
```

`preprocessTfaSignals` then:

1. Removes samples containing nonfinite values.
2. Removes leading CO2 zeros and the initial transition region.
3. Resamples all signals to `analysisSettings.fsTarget`.
4. Optionally normalizes CBV to percent baseline.
5. Optionally detrends the signals.
6. Optionally removes each signal mean.

The processed arrays remain horizontal throughout the analysis.

## Spectral Analysis

MISO and SISO use spectra from the same Welch calculation. The configuration
continues to come from `main.m`:

- Window length: `analysisSettings.pwelch.windowLengthSeconds`
- Window overlap: `analysisSettings.pwelch.windowOverlap`
- Minimum accepted windows: `analysisSettings.pwelch.minimumWindows`
- FFT length: the Welch window length in samples
- Spectral smoothing toggle: `analysisSettings.pwelch.smoothingEnabled`
- Spectral smoothing kernel: `analysisSettings.pwelch.smoothingKernel`

The default 128-second window contains 512 samples at the default 4 Hz
sampling frequency. Three windows with 50% overlap therefore require 1,024
samples, corresponding to approximately 256 seconds of recording.

The smoothing kernel is user-configurable in `main.m`. It must contain an
odd number of nonnegative weights that sum to one. When smoothing is
disabled, the original Welch auto- and cross-spectra are passed directly
to the enabled models.

The models can be run independently or together:

```matlab
analysisSettings.runMISO = true;
analysisSettings.runSISO = true;
```

`estimateWelchSpectra` returns the shared smoothed auto- and cross-spectra.
The model result structures retain the smoothed power spectra:

```matlab
results.map.power
results.co2.power
results.cbv.power
```

The reported frequency range is controlled by:

```matlab
analysisSettings.frequencyRangeHz
```

Frequency-band averages use:

```matlab
analysisSettings.frequencyBandEdgesHz
analysisSettings.frequencyBandNames
```

## Phase

Each transfer-function pathway stores:

```matlab
results.map.phase.wrapped
results.map.phase.unwrapped

results.co2.phase.wrapped
results.co2.phase.unwrapped
```

The input–input relationship stores the equivalent wrapped and unwrapped
MAP–CO2 phase arrays.

The phase method is selected in `main.m`:

```matlab
analysisSettings.phase.unwrapMethod = "standard";
```

Supported methods are:

- `"standard"`: MATLAB `unwrap`
- `"custom"`: the project-specific coherence-weighted unwrapping method

Circular phase means and standard deviations are calculated directly from
the complex mean resultant vector. The results do not depend on an external
circular-statistics toolbox.

For every phase aggregation, the wrapped values are summarized using a
circular mean and circular standard deviation. The circular-mean sequence
is then unwrapped using the selected phase method. The unwrapped
representation retains the same circular standard deviation because adding
phase cycles does not change angular dispersion. The circular standard
deviation is defined as `sqrt(-2*log(R))`, where `R` is the mean resultant
length.

The selected method is stored once per model:

```matlab
misoResults.phaseUnwrapMethod
sisoResults.phaseUnwrapMethod
```

## Result Structures

### MISO

```text
misoResults
├── f
├── map
│   ├── power
│   ├── transferFunction
│   ├── gain
│   ├── phase.wrapped
│   ├── phase.unwrapped
│   └── coherence.partial
├── co2
│   ├── power
│   ├── transferFunction
│   ├── gain
│   ├── phase.wrapped
│   ├── phase.unwrapped
│   └── coherence.partial
├── cbv.power
├── system
│   ├── multipleCoherence
│   ├── unexplainedFraction
│   └── residualPower
├── inputRelationship
│   ├── coherence
│   ├── phase.wrapped
│   └── phase.unwrapped
├── diagnostics.conditionNumber
├── phaseUnwrapMethod
└── welchInfo
```

### SISO

```text
sisoResults
├── f
├── map
│   ├── power
│   ├── transferFunction
│   ├── gain
│   ├── phase.wrapped
│   ├── phase.unwrapped
│   ├── coherence.pairwise
│   ├── unexplainedFraction
│   └── residualPower
├── co2
│   └── equivalent CO2-to-CBV fields
├── cbv.power
├── inputRelationship
├── phaseUnwrapMethod
└── welchInfo
```

Partial and multiple coherence belong to the MISO model. Pairwise
input-output coherence belongs to the SISO model.

## Running the Project

Configure the project in `main.m`, then select:

```matlab
runType = "single";
runType = "batch";
runType = "synthetic";
```

### Single

Set `subjectInfo` to one Excel file. The file is loaded and passed into the
common subject workflow.

### Batch

Set:

```matlab
batchSettings.dataFolder
batchSettings.groupsToRun
batchSettings.targetSuccessfulSubjectsPerGroup
```

Each entry in `batchSettings.groupsToRun` is matched to a folder with that
name. For example, `["MCI"; "NC"; "LC"]` uses the `MCI`, `NC`, and `LC`
folders in that order throughout discovery, processing, group figures, and
Excel export. Subjects are sorted numerically within each group.

The target subject count refers to successful analyses. Failed subjects
remain in the status and Excel outputs, and processing continues until the
requested number of successful subjects is reached or no files remain.

Only one baseline file is accepted for each group and subject ID. Subject
files use names such as:

```text
101_baseline.xlsx
```

Setting `batchSettings.previewOnly = true` loads and preprocesses each
subject and reports whether it contains enough Welch windows without
running the TFA models.

### Synthetic

Synthetic mode calls `createSyntheticSignal`, which returns a deterministic
horizontal Sho-style signal. MAP contains components at 0.03, 0.10, and
0.30 Hz; CO2 contains components at 0.05, 0.11, and 0.40 Hz; and both inputs
contain a shared 0.08 Hz component. CBV is constructed with known
pathway-specific gains and phase shifts. Its raw CBV variation is scaled
around a 50 cm/s baseline so the stored Sho gains are recovered directly
when the default percent-baseline normalization is enabled. The synthetic
signal then runs through the same subject analysis used for a real subject.

## Plotting

Nine complete figure types can be selected in `main.m`:

1. Subject/group overview
2. MISO MAP pathway
3. MISO CO2 pathway
4. SISO MAP pathway
5. SISO CO2 pathway
6. Partitioned MISO MAP pathway
7. Partitioned MISO CO2 pathway
8. Partitioned SISO MAP pathway
9. Partitioned SISO CO2 pathway

Transfer-function gain and phase use stem plots by default. Spectra,
coherence, condition number, and group mean/SD results use line plots.

Subject SISO coherence plots can show the CARNet ordinary-coherence
reference selected from the actual number of Welch windows. This line is a
visual benchmark and does not filter gain or phase. It is not drawn on MISO
partial- or multiple-coherence plots.

Partitioned figures use the frequency bands defined in `main.m`; the number
of rows changes automatically with the number of configured bands.

## Excel Output

Single, synthetic, and batch runs use one metric-based workbook format.
Each enabled metric receives one sheet per represented group. The group
sheet order follows the left-to-right order in
`batchSettings.groupsToRun`. For example, `["MCI", "LC", "NC"]` writes
MCI, then LC, then NC for each enabled metric.

The top section of every sheet contains:

- One row per frequency bin in `analysisSettings.frequencyRangeHz`
- The configured frequency-band label for each bin
- One column per attempted subject
- A group Mean column
- A group SD column

After one blank row, the same sheet contains the subject-level band
averages and their group Mean and SD. Arithmetic metrics use arithmetic
statistics. Phase metrics use circular group statistics; an unwrapped
group mean is produced by unwrapping the circular mean.

Subjects that cannot be analyzed remain visible as columns. The first cell
below their header contains a short error message, their remaining cells
are blank, and they are excluded from Mean and SD calculations.

The exported metrics are controlled by the
`outputSettings.excelMetrics` Boolean structure in `main.m`.

The fields named `power` contain power spectral density estimates produced
by `cpsd`. Power and residual-power exports are converted to decibels
before group and band statistics are calculated.

## Repository Structure

```text
.
├── main.m
├── src
│   ├── analysis
│   ├── data
│   ├── group
│   ├── output
│   ├── phase
│   ├── plotting
│   ├── preprocessing
│   └── workflow
└── tests
    └── helpers
```

Each MATLAB function has its own file.

## Requirements

The current dependency audit reports:

- MATLAB
- Signal Processing Toolbox

The project is currently tested with MATLAB R2025b.

## Tests

Run:

```matlab
results = runtests("tests");
```

The tests cover preprocessing, configurable Welch smoothing,
frequency-range limiting, MISO results, SISO results, circular phase
statistics, phase unwrapping, subject-level band summaries, subject
discovery order, batch readiness, figure toggles, and Excel export.

## Method References

- Panerai RB et al. Transfer function analysis of dynamic cerebral
  autoregulation: A CARNet white paper 2022 update. *Journal of Cerebral
  Blood Flow & Metabolism*. DOI: 10.1177/0271678X221119760.
- Berens P. CircStat: A MATLAB Toolbox for Circular Statistics.
  *Journal of Statistical Software*. 2009;31(10).
  DOI: 10.18637/jss.v031.i10.

This project is under active development and is intended for research and
validation use.
