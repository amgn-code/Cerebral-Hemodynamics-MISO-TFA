# Cerebral Hemodynamics Transfer Function Analysis

This MATLAB project analyzes the frequency-domain relationships between mean
arterial pressure (MAP), end-tidal CO2, and cerebral blood flow
velocity/CBV. It supports both:

- MISO analysis: MAP and CO2 are solved together as inputs to CBV.
- SISO analysis: MAP-to-CBV and CO2-to-CBV are solved independently.

The project can analyze one subject, a batch of subjects, or one generated
demonstration signal. A separate family-based simulation supports the
Paper 1 known-truth study.

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

The default MISO solve uses the direct spectral-matrix solution without
regularization or SISO fallback logic. Standardized ridge regularization is
available only when it is explicitly enabled. The code never changes the
solver because a frequency bin looks difficult.

The solver reports the raw condition number as well as scale-normalized
diagnostics. The normalized condition number, determinant, minimum
eigenvalue, and reciprocal condition estimate are easier to interpret when
MAP and CO2 have different units or power.

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
    ├── demo: generate one illustrative subject
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
group arrays, means, and standard deviations. When statistical analysis is
enabled, the subject-level band values are then passed to the statistical
tests and matching figures. After all attempted subjects finish, `runTFA`
writes the selected metric and statistical sheets to the same workbook.

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

The CO2 startup check no longer assumes that startup ends at a fixed data
point. The stable start and removed duration are stored for each subject. If
startup removal changes an otherwise usable recording into one with too few
Welch windows, the subject is reported as `LateCO2Startup`.

Before detrending, normalization, or mean removal, preprocessing also stores
the subject's mean and within-recording SD for MAP, PETCO2, and raw CBFV. CVRi
is calculated as mean MAP divided by mean raw CBFV.

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

`calculateSubjectBandValues` is shared by the Excel exporter and statistical
analysis so every output uses the same band boundaries and averaging rules.

## Phase

Each transfer-function pathway stores:

```matlab
results.map.phase.wrapped
results.map.phase.unwrapped

results.co2.phase.wrapped
results.co2.phase.unwrapped
```

The input-to-input relationship stores the equivalent wrapped and
unwrapped MAP-to-CO2 phase arrays.

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
├── diagnostics
│   ├── conditionNumber
│   ├── normalizedConditionNumber
│   ├── normalizedDeterminant
│   ├── minimumNormalizedEigenvalue
│   ├── reciprocalConditionEstimate
│   └── isPoorlyConditioned
├── regularization
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
runType = "demo";
runType = "simulation";
```

The demonstration mode creates one signal for checking the ordinary TFA
pipeline. Simulation mode runs the family-based Paper 1 known-truth
workflow. Its profile, family count, factor values, observation sweeps, and
output folder are configured directly in the `Paper 1 Simulation` section
of `main.m`.

## Running the NC-Only Approach Paper

The Paper 1 workflow uses a separate settings structure so manuscript
decisions do not become hidden defaults in the ordinary subject pipeline.
The normal entry point is:

```matlab
runType = "simulation";
```

The editable simulation fields are shown directly in `main.m`. The workflow
can also be called from another script when needed:

```matlab
settings = approachPaperSettings( ...
    "/path/to/ieem_data", ...
    "/path/to/approach_paper_results", ...
    "quick");

paperResults = runApproachPaper(settings);
```

Start with the `"quick"` profile. It uses smaller simulation and surrogate
counts for checking the workflow and figure layout. Change the profile to
`"paper"` for the final analysis. The paper profile is intentionally large
and can take substantial time.

To run only the simulation while developing it:

```matlab
settings.steps.runEmpiricalAnalysis = false;
settings.steps.runRobustnessAnalysis = false;
paperResults = runApproachPaper(settings);
```

### Family-Based Known-Truth Simulation

The simulation separates three ideas:

1. A family is one fixed scenario with paired long, clean training and
   validation realizations.
2. A scenario fixes the input relationship and true physiological pathways.
3. An observation changes duration, measurement noise, or alignment while
   preserving the same family and true pathways.

Every family receives all main duration and output-SNR observations. Short
recordings are prefixes of the same long signal. Noisy recordings use the
same clean output and a fixed noise realization scaled to each requested
SNR. This makes duration and noise comparisons paired within a family.

The main final profile uses:

```matlab
settings.simulation.families.numFamilies = 1000;
settings.simulation.observations.referenceDurationSeconds = 300;
settings.simulation.observations.durationSeconds = ...
    [256 300 320 384 512 640 896];
settings.simulation.observations.outputSnrDb = ...
    [Inf 30 20 15 10 5 0];
```

`Inf` means no added noise. Zero dB means equal signal and noise power.
The reference duration is editable directly in `main.m`. Every
non-duration factor analysis uses that duration and states it in its
figure title. The 300-second default resembles the available NC recordings
and provides three 128-second Welch windows with 50% overlap. The
320-second condition is retained because it is the first listed duration
that provides four windows.

Target input coherence, spectral similarity, PETCO2-to-MAP fluctuation SD
ratio, PETCO2-to-MAP pathway band-gain ratio, and true PETCO2 delay use
fixed user-visible values. These values are assigned as evenly across
families as the family count allows. MAP and PETCO2 pathway time constants
remain continuous nuisance variables. Duration, CBFV output noise, MAP
measurement noise, PETCO2 measurement noise, and PETCO2 timing
misalignment are observation conditions applied repeatedly to each family.

The true MAP pathway is a high-pass-like autoregulatory response. Its gain
is smaller for slow MAP changes and approaches a higher plateau as
frequency increases. The true PETCO2 pathway is a separate delayed
low-pass response. Its scale is chosen so that the RMS transfer-function
gain over the selected analysis range has the requested ratio to the MAP
pathway. The simulation does not create zero PETCO2 pathways.

The longest noise-free observation is used only to characterize each
family. It supplies the realized coherence, PSD-shape overlap, fluctuation
SD ratio, and PETCO2 contribution-power share used to characterize that
family. The selected standard duration is then used to compare model
performance across those intrinsic groups. This prevents a 300-second
estimation error from redefining the family itself.

Input coherence is the magnitude-squared MAP-PETCO2 cross-spectral
relationship at each frequency. A whole-record family coherence is the
mean over the selected analysis range. PSD-shape overlap is a separate
descriptive measure. It is the Bhattacharyya coefficient between the
normalized MAP and PETCO2 power spectra. The fluctuation SD ratio is:

```text
SD(PETCO2) / SD(MAP)
```

It is an amplitude ratio, not a power or variance ratio. The realized
PETCO2 contribution-power share uses the known clean pathway components:

```text
PETCO2 contribution share =
    PETCO2 component power /
    (MAP component power + PETCO2 component power)
```

This quantity is distinct from both input amplitude and transfer-function
gain. It describes how much of the separately generated pathway power came
from PETCO2 in that realization.

The independent validation realization has the same input and pathway
settings as the training realization but a different random seed. It is
used only to test how well coefficients estimated from training data
predict a new recording.

The simulation result contains:

```text
simulationResults
├── familyDesign
├── observationPlan
├── observations
├── frequency
├── ridge
├── ridgeFrequency
├── estimatorSettings
├── estimatorFrequency
└── exampleFamily
```

`observations` contains whole-range errors and model advantages.
`frequency` retains frequency-specific truth, estimates, errors, input
coherence, conditioning, and model advantages.
`estimatorSettings` contains one-factor-at-a-time checks of Welch window
length and Welch overlap at the reference observation. Spectral smoothing
remains fixed at the primary `[0.25 0.50 0.25]` kernel and is not a Paper 1
sensitivity factor. A separate duration-by-window grid distinguishes the
effect of recording length from the effect of the Welch window.

Repeated-condition summaries use the same families at every controlled
level. Intrinsic-factor summaries use different family subsets in fixed
factor ranges. Those ranges can have unequal family counts, so the
exports report the total family count for every group.

### Simulation Statistical Comparisons

Every simulation model comparison uses the family as the independent
unit. MISO and SISO are fitted to the same observation, so the
family-level model advantage is the paired comparison:

```text
model advantage = log10(SISO error / MISO error)
```

A two-sided one-sample t test asks whether the across-family mean model
advantage differs from zero. The output reports the mean, SD, standard
error, 95% confidence interval, raw P value, BH-adjusted P value, valid
family count, and geometric SISO-to-MISO error ratio.

The reference-condition MAP complex comparison is the prespecified
simulation primary test and reports its unadjusted P value. The other five
reference outcomes are one secondary BH family. For a one-factor curve,
BH adjustment is applied across that metric's factor levels. For a
factor-by-frequency or two-factor map, BH adjustment is applied across all
valid cells within that panel. Separate MAP or PETCO2 complex, gain, and
phase panels remain separate correction families.

An outlined point on a one-dimensional model-advantage curve indicates
BH-adjusted `P < 0.05`. A black dot in a model-advantage heatmap identifies
a significant cell. Absolute MISO and SISO error plots do not receive
significance markers because significance belongs to their paired
comparison. Exact P values and confidence intervals remain in the source
data even when the plot shows only the threshold marker.

The default minimum for an inferential test is three valid families.
Sparse quick-profile groups can therefore remain unmarked. The paper
profile is required for stable inferential results. With 1000 families,
small effects can be statistically significant, so interpretation should
prioritize effect magnitude and confidence intervals in addition to P
values.

### Organized Plot Export

Paper 1 plots are exported by analysis group:

```text
Figures/
├── 01_Simulated_System/
│   ├── Plots/
│   └── Source_Data/
├── 02_Generator_Validation/
├── 03_Recording_Duration/
├── 04_CBFV_Output_Noise/
├── 05_MAP_Measurement_Noise/
├── 06_PETCO2_Measurement_Noise/
├── 07_Input_Coherence/
├── 08_PSD_Shape_Overlap/
├── 09_PETCO2_to_MAP_Fluctuation_SD_Ratio/
├── 10_PETCO2_to_MAP_Pathway_Band_Gain_Ratio/
├── 11_Realized_PETCO2_Contribution_Power_Share/
├── 12_True_PETCO2_Response_Delay/
├── 13_PETCO2_Timing_Misalignment/
├── 14_Ridge_Regularization/
├── 15_Welch_Window_Length/
├── 16_Welch_Window_Overlap/
├── 17_Coherence_by_PSD_Overlap/
├── 18_Fluctuation_by_Pathway_Gain/
├── 19_Duration_by_Welch_Window/
├── 20_Delay_by_Misalignment/
├── 21_NC_Simulation_Coverage/
├── 22_NC_Operating_Map_Placement/
├── 23_NC_Model_Comparison/
├── 24_NC_Robustness/
└── figure_manifest.csv
```

Every controlled simulation factor exports the same five-figure set:

1. Overall complex error and model advantage.
2. Mean frequency-resolved MISO error.
3. Mean frequency-resolved SISO error.
4. Mean frequency-resolved model advantage.
5. Whole-range gain and phase model advantage with consistency fractions.

Simulation curves use the arithmetic mean with one-SD shading. Absolute
frequency maps show the mean across families. MISO and SISO
counterpart panels use identical error limits. Model-advantage frequency
maps use a common blue-white-orange scale:

- Blue favors MISO.
- White indicates similar error.
- Orange favors SISO.

Model advantage is defined as:

```text
log10(SISO error / MISO error)
```

Positive values indicate lower MISO error, and negative values indicate
lower SISO error. The displayed range of -2 to 2 corresponds to a
100-fold difference in either direction. More extreme values use the
endpoint color.

The generator-validation folder also contains a reference-condition
forest plot for MAP and PETCO2 complex, gain, and phase errors. Horizontal
lines show 95% confidence intervals. The MAP complex result is labeled as
the primary comparison, and the other five outcomes use BH adjustment.

Whole-range complex error is the mean squared complex coefficient error
divided by the mean squared true coefficient magnitude over the selected
frequency range. Frequency-resolved complex error uses the same pathway's
full-range RMS truth gain as a fixed denominator. It does not divide by the
truth at each individual bin. This avoids artificial error inflation where
the true pathway gain is naturally small.

Gray heatmap cells are missing or have fewer than the configured minimum
number of valid families. This prevents missing phase values from being
displayed as strong SISO or MISO effects. Phase error is omitted at bins
where true pathway gain is below 5% of that pathway's full-range RMS gain.
The exported valid `n` therefore can be smaller for phase than for gain.

Each frequency heatmap saves:

- A numeric long-form CSV and Excel sheet with mean, SD, valid `n`, and
  group `N`.
- For model-advantage maps, standard error, 95% confidence interval, raw
  P, BH-adjusted P, significance status, and geometric error ratio.
- A readable Excel grid whose cells contain `mean ± SD`.
- A rightmost `N` column for the total families in each factor group.
- An added `n=` label only when a cell has fewer valid families than its
  group total.

The PDF or PNG heatmap uses color for the mean only. The workbook preserves
the dispersion and sample-size information without overloading the figure.

CBFV prediction error remains in the saved simulation tables but is not
part of the primary five-figure set.

The Welch-window sensitivity uses `[64 75 100 128 150]` seconds by default
with overlap fixed at 50%. The Welch-overlap sensitivity uses
`[0.25 0.50 0.75]` with window length fixed at 128 seconds. Results with
fewer than the primary three-window criterion are retained only as labeled
boundary conditions. Overlapping Welch windows are repeated spectral
segments, not cross-validation folds. The separate validation realization
is retained for internal prediction diagnostics.

The Paper 1 statistical plan uses NC only:

- NC MAP MISO versus SISO gain is the primary family.
- NC CO2 MISO versus SISO gain is a separate secondary family.
- Frequency-wise gain and phase results are exploratory.
- Between-group NC versus MCI tests are disabled.

At every frequency bin, the phase analysis uses each subject's wrapped
MISO-minus-SISO phase difference and a paired circular permutation test.
Benjamini-Hochberg adjustment is applied across the bins in each pathway's
phase curve. The output also reports the principal equivalent delay
difference:

```text
delay difference = -wrapped phase difference / (2*pi*frequency)
```

This delay is defined modulo one period, `1/f`. It should therefore be
interpreted as a local representation of the wrapped phase difference, not
as an unrestricted absolute physiological delay.

Every saved model-comparison row contains its `MultiplicityFamily`, raw P
value, and adjusted P value. Frequency-wise comparison rows also name the
exploratory curve used as their adjustment family. The approach workflow
saves the settings, random seeds, software manifest, participant inclusion
information, solver diagnostics, figure source data, and a single MAT
result file.

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

### Demonstration Signal

Demo mode calls `createSyntheticSignal`, which returns a deterministic
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

Batch statistical figures are controlled by
`analysisSettings.plot.show.statistics`. They show the subject values used
in the tests:

1. Paired SISO-MISO gain estimates
2. NC-MCI MISO gain and coherence comparisons
3. NC-MCI comparison of MAP-minus-CO2 pathway balance
4. Input coherence versus the absolute SISO-MISO gain change
5. Exploratory full-frequency group and model comparisons

Each full-frequency comparison contains the two mean/SD curves, their
difference, and the BH-adjusted P value at every frequency. A horizontal
line marks the configured significance level. These frequency-wise tests
are exploratory. The predefined band tests remain the primary analysis.

## Statistical Analysis

Batch statistics are enabled with:

```matlab
analysisSettings.statistics.enabled
```

The configured group order comes from `batchSettings.groupsToRun`. Primary
bands, alpha, the circular-permutation count, and the random seed remain
visible in `main.m`.

The implemented tests are:

- Paired t-tests for arithmetic SISO-MISO comparisons
- Welch unequal-variance t-tests for continuous group comparisons
- Circular permutation tests for phase
- Spearman correlation for input-coherence associations
- Fisher exact or chi-square tests for categorical participant variables
- Benjamini-Hochberg adjustment within prespecified analysis families

Optional exploratory frequency-wise tests are controlled by
`analysisSettings.statistics.frequencyWise`. NC-MCI gain and partial
coherence use Welch t-tests. Paired SISO-MISO gain uses paired t-tests.
Wrapped phase uses circular permutation tests. BH adjustment is applied
across the frequency bins in each enabled comparison curve.

Raw and BH-adjusted P values are retained. Model comparisons are explicitly
labeled so partial versus ordinary coherence is not interpreted as a test of
predictive performance. In-sample residual reduction is not used to claim
that MISO predicts better than SISO.

An optional standardized participant file may be provided through
`analysisSettings.statistics.participantDataFile`. It must contain one row
per participant and variables named `SubjectID` and `Group`. This avoids
embedding a parser for a study-specific demographic workbook.

## Excel Output

Single, demo, and batch runs use one metric-based workbook format.
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

When `outputSettings.excelStatistics` is true, batch output appends these
sheets to the same workbook:

- `Participant_Characteristics`
- `Model_Comparisons`
- `Group_Comparisons`
- `Input_Associations`
- `Frequency_Group_Tests`
- `Frequency_Model_Tests`

The participant sheet contains both group summaries and individual inclusion
status. Statistical sheets report sample sizes, estimates, confidence
intervals where applicable, effect sizes, raw P values, and BH-adjusted P
values.

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
│   ├── statistics
│   └── workflow
└── tests
    └── helpers
```

Each MATLAB function has its own file.

## Requirements

The current dependency audit reports:

- MATLAB
- Signal Processing Toolbox
- Statistics and Machine Learning Toolbox

The project is currently tested with MATLAB R2025b.

## Tests

Run:

```matlab
results = runtests("tests");
```

The tests cover preprocessing, configurable Welch smoothing,
frequency-range limiting, MISO results, SISO results, circular phase
statistics, phase unwrapping, subject-level band summaries, statistical
comparisons, BH adjustment, subject discovery order, batch readiness,
figure toggles, and Excel export.

## Method References

- Panerai RB et al. Transfer function analysis of dynamic cerebral
  autoregulation: A CARNet white paper 2022 update. *Journal of Cerebral
  Blood Flow & Metabolism*. DOI: 10.1177/0271678X221119760.
- Berens P. CircStat: A MATLAB Toolbox for Circular Statistics.
  *Journal of Statistical Software*. 2009;31(10).
  DOI: 10.18637/jss.v031.i10.
- Benjamini Y, Hochberg Y. Controlling the false discovery rate: a practical
  and powerful approach to multiple testing. *Journal of the Royal
  Statistical Society: Series B*. 1995;57(1):289-300.
  DOI: 10.1111/j.2517-6161.1995.tb02031.x.

This project is under active development and is intended for research and
validation use.
