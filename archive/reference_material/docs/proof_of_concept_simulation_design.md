# Known-Truth Simulation Design for the Presentation Proof of Concept

## Document status

This document is the design specification for the revised known-truth
MISO-versus-SISO simulation. The named profiles, five-level assignments,
pairwise-balanced generator, saved design identifiers, and proof-of-concept
bin edges were implemented and tested in Chunk 2. Chunk 3 separated
numerical analysis from summary, table, and figure generation, added a
protected output-regeneration entry point, and verified the staged workflow
with automated tests. Chunk 4 implemented concise graphical titles,
per-figure caption files, caption fields in the figure manifest, and a global
Markdown caption catalog generated from the saved numerical context. Chunk 5
added a formal simulation-audit stage, completed the full `proof250` run,
audited its design and numerical support, visually reviewed the principal
figures, corrected the remaining generator and estimator-map layout issues,
and regenerated the complete output library from the saved numerical
checkpoint.

The 250-family profile is intended to generate a coherent proof of concept
for the detailed Beamer presentation. It is not the planned final sample size
for the research paper. The final paper will likely use 1,000 families and
may use finer grouping after the 250-family run has established occupancy,
stability, computational cost, and figure readability.

## Communication and scientific purpose

The simulation asks when a joint two-input transfer function estimate
recovers the known MAP-to-CBFV and PETCO2-to-CBFV pathways more accurately
than two separate single-input estimates. The proof-of-concept presentation
must establish the generating model, estimator, experimental design, error
metrics, and aggregation rules before interpreting results.

The 250-family run is large enough to demonstrate these relationships with a
balanced five-level design. It is not intended to establish the final
publication-resolution boundaries of the MISO operating region.

## Analysis profiles

| Profile | Families | Intended use | Grouping resolution |
|---|---:|---|---|
| `quick` | Small, reduced design | Function and unit testing | Minimal, chosen only for test speed |
| `designSmoke` | 25 | One complete balanced design block and full-workflow testing | Five levels or bins, with display minimum reduced for diagnostics only |
| `proof250` | 250 | Presentation proof of concept | Five exact levels and five fixed bins for intrinsic factors |
| `paper1000` | 1,000 | Likely final-paper analysis after the proof-of-concept review | To be prespecified after the 250-family occupancy and stability audit; potentially finer than five bins |

The names must state their purpose and size. A large profile must not be
selected and then silently overridden to a smaller family count in `main.m`.

## Reusable numerical results and output regeneration

The normal `runApproachPaper` entry point now executes three explicit stages:

1. `runApproachPaperAnalyses` performs the numerical empirical, simulation,
   and robustness work requested in the settings.
2. `summarizeApproachPaperResults` creates the reproducibility manifest and
   requested tables from those completed results.
3. `renderApproachPaperOutputs` creates the requested figures from the same
   completed results.

The wrapper saves `approach_paper_analysis_results.mat` immediately after the
first stage and before any table or figure is attempted. It then saves
`approach_paper_results.mat` after the requested output stages. The first file
is therefore the reusable numerical source for presentation and manuscript
revisions.

`regenerateApproachPaperOutputs` can load that numerical file and rebuild
tables and figures in the same or a new output folder. Its override interface
is limited to output location, whether tables and figures are created, and
existing export-format fields. It rejects changes to the analysis,
simulation, family design, and physiological parameters. The stored
`paperResults.settings` remains the provenance record for the numerical run,
while `paperResults.outputSettings` records the choices used for a particular
render.

## Units of the simulation

### Family

A family represents one fixed simulated physiological and input-structure
scenario. Assigned input relationships, true pathways, and pathway time
constants remain fixed for every observation of that family.

### Assigned family factor

An assigned factor is chosen before signals are generated. Its exact value is
used when grouping families. Assigned values are not post hoc bins.

### Realized family characteristic

A realized characteristic is measured from the longest clean generated
record. Examples include mean realized MAP-PETCO2 coherence, realized
PSD-shape overlap, and the realized PETCO2 contribution-power share. These
continuous values are grouped into fixed intervals for display.

### Realization

Each family has independent training and validation random realizations that
share the same assigned spectra and true transfer functions. The primary
study evaluates transfer-function recovery against truth. Validation signals
remain available for prediction checks and quality control.

### Observation

An observation changes how the same family is recorded. Duration, output
noise, input measurement noise, and timing alignment can change without
changing the family or its physiological truth.

### Estimator setting

An estimator setting changes how the same observation is analyzed. Welch
window length, Welch overlap, and ridge regularization are sensitivity
settings rather than new independent families.

## Proof-of-concept family factors

The proof-of-concept design uses five assigned levels for each of the five
main intrinsic factors.

| Assigned family factor | Proof-of-concept values | Interpretation |
|---|---|---|
| Target MAP-PETCO2 coherence | 0.05, 0.25, 0.50, 0.75, 0.95 | From nearly independent inputs to inputs that are difficult to distinguish |
| Spectral-similarity control | 0, 0.25, 0.50, 0.75, 1 | Moves the PETCO2 spectral center from maximally separated toward the MAP spectral center |
| PETCO2-to-MAP fluctuation SD ratio | 0.05, 0.25, 0.50, 1, 2 | From very weak PETCO2 fluctuations to fluctuations twice the MAP SD |
| PETCO2-to-MAP pathway band-gain ratio | 0.10, 0.50, 1, 2, 4 | From a very weak PETCO2 pathway to a pathway four times the MAP band gain |
| True PETCO2 pathway delay | 0, 2.5, 5, 7.5, 10 s | Even coverage of the existing zero-to-ten-second delay range |

The pathway time constants remain continuous nuisance variables:

| Continuous family property | Range |
|---|---:|
| MAP pathway time constant | 1 to 4 s |
| PETCO2 pathway time constant | 2 to 8 s |

The time constants will use stratified continuous sampling across all
families. They will not be converted to five categorical levels merely for
visual uniformity.

## Pairwise-balanced 250-family design

The five assigned factors will use a pairwise-balanced 25-family base block.
Within one block:

- each factor level occurs five times;
- every pair of factors contains every possible 5-by-5 level combination
  exactly once;
- the design does not attempt to contain every possible five-factor
  combination.

A complete five-factor factorial would require

\[
5^5=3,125
\]

families. That is unnecessary for the present purpose. The pairwise-balanced
design instead protects all planned one-factor and two-factor summaries from
accidental imbalance.

The proof-of-concept run repeats the 25-family block ten times:

\[
25\text{ families per block}\times10\text{ blocks}=250\text{ families}.
\]

Across 250 families, each assigned level therefore occurs 50 times and each
pairwise 5-by-5 combination occurs 10 times. Independent random sequences and
continuously sampled time constants keep the ten repetitions from being
identical signals.

The likely 1,000-family paper profile can use forty balanced blocks:

\[
25\times40=1,000.
\]

This preserves the same experimental logic while providing 40 families per
assigned pairwise cell and supporting finer continuous binning.

## Input and pathway generator settings retained from the current study

| Setting | Value |
|---|---:|
| Sampling frequency | 4 Hz |
| Analysis frequency range | 0.005 to 0.35 Hz |
| MAP spectrum center | 0.06 Hz |
| Spectrum bandwidth | 0.045 Hz |
| Maximum input-spectrum center separation | 0.22 Hz |
| Spectrum power floor | 0.01 of the configured scale |
| MAP high-frequency pathway gain | 1.5 |
| MAP low-frequency gain fraction | 0.25 |
| Filter burn-in | 120 s |
| Nonlinear interaction strength | 0 for the primary linear benchmark |

The proof-of-concept run retains the current known linear generating
structure. Unmeasured inputs and nonlinear model mismatch belong in a later,
separately labeled extension.

## Observation design

Every family is evaluated under the same paired observation conditions.

| Experiment | Levels | Family contribution |
|---|---|---|
| Duration by CBFV output SNR | Durations 256, 300, 320, 384, 512, 640, and 896 s crossed with SNR infinity, 30, 20, 15, 10, 5, and 0 dB | Every family receives all 49 combinations |
| MAP measurement noise | Input SNR infinity, 30, 20, 15, 10, 5, and 0 dB | Every family receives all seven levels at the reference observation |
| PETCO2 measurement noise | Input SNR infinity, 30, 20, 15, 10, 5, and 0 dB | Every family receives all seven levels at the reference observation |
| PETCO2 timing misalignment | -6, -3, 0, 3, and 6 s | Every family receives all five levels at the reference observation |

The reference observation is 300 seconds with 15-dB CBFV output SNR, no
added input measurement noise, and no timing misalignment. The longest clean
observation characterizes each family's realized intrinsic properties.

The current full sweep therefore contains 68 primary observation plans per
family:

\[
49+7+7+5=68.
\]

For 250 families, this gives 17,000 primary observation analyses.

## Estimator settings

The primary spectral estimator uses a 128-second Hann window, 50% overlap,
and the common three-point smoothing kernel `[0.25, 0.50, 0.25]`. At least
three complete Welch windows are required by the primary rule.

Sensitivity analyses retain:

| Estimator factor | Values |
|---|---|
| Ridge lambda | 0.001, 0.01, 0.1 |
| Welch window length | 64, 75, 100, 128, 150 s |
| Welch overlap | 0.25, 0.50, 0.75 |
| Duration-by-window grid | Seven durations crossed with five window lengths |

This produces 43 Welch-setting analyses per family and three ridge variants
at the reference observation. For 250 families, the expected counts are
10,750 Welch-setting analyses and 750 ridge analyses.

## Proof-of-concept grouping rules

Assigned factors are displayed at their five exact values. Their axes must
use exact numeric labels rather than interval labels.

The proof-of-concept fixed intervals for realized characteristics on a
zero-to-one scale are:

| Bin | Interval |
|---:|---|
| 1 | [0.0, 0.2) |
| 2 | [0.2, 0.4) |
| 3 | [0.4, 0.6) |
| 4 | [0.6, 0.8) |
| 5 | [0.8, 1.0] |

The final interval includes the upper endpoint. These fixed intervals apply
to realized input coherence, realized PSD-shape overlap, and realized PETCO2
contribution-power share unless a later scientific review provides a reason
to treat one of these variables differently.

Frequency-resolved plots retain the native Welch frequency bins. Frequency
is not rebinned merely to match the five family groups.

The resulting plot structures are:

| Plot type | Structure with 250 families | Expected support |
|---|---|---:|
| Repeated observation condition | Exact condition by native frequency or summary outcome | 250 families per condition before invalid results |
| One assigned family factor | Five exact levels | 50 families per level |
| Two assigned family factors | 5 by 5 exact grid | 10 families per cell |
| One realized family characteristic | Five fixed intervals | Approximately 50 families per interval if realized coverage is even |
| Two realized family characteristics | 5 by 5 fixed grid | Approximately 10 families per cell if realized coverage is even |

Realized-bin counts are not guaranteed. Their occupancy must be measured
after signal generation, and fixed boundaries must not be moved simply to
make the heatmap look complete.

## Accuracy outcomes

The primary comparison remains recovery of the known complex transfer
functions. Each pathway retains:

- absolute gain error;
- wrapped phase error, evaluated only where true pathway gain is adequate;
- normalized frequency-resolved complex error;
- normalized whole-range complex error;
- model advantage.

Model advantage is

\[
A_{\mathrm{model}}
=\log_{10}\left(
\frac{E_{\mathrm{SISO}}+\epsilon}
     {E_{\mathrm{MISO}}+\epsilon}
\right).
\]

Positive values indicate lower MISO error, zero indicates equal error, and
negative values indicate lower SISO error. Absolute SISO and MISO errors must
be examined alongside relative advantage.

The exact primary endpoint and multiplicity families remain subject to the
separate statistical review already identified in the project.

## Statistical unit and heatmap summaries

The family is the independent statistical unit. Frequency bins, Welch
segments, repeated observations, training and validation sequences, and
estimator settings are not treated as independent families.

Every plotted group or heatmap cell will retain:

- arithmetic mean;
- standard deviation;
- valid family count;
- total assigned family count;
- standard error;
- 95% confidence interval;
- raw probability value when inference is performed;
- Benjamini-Hochberg-adjusted probability value and adjustment family.

The proof-of-concept display threshold is at least five valid families. A
cell with fewer than five valid families remains visible as an insufficient-N
cell but does not display a mean color. A five-family minimum permits a
summary to be calculated; it does not make a small cell a strong basis for a
publication claim.

Two-dimensional continuous heatmaps are primarily descriptive operating maps
in the proof-of-concept presentation. Formal claims about continuous trends
or interactions should use family-level models that retain the underlying
continuous values rather than relying only on cellwise tests after binning.

## Figure-caption requirements

Every figure caption must state:

1. the outcome and pathways shown;
2. the reference observation and estimator settings;
3. whether an axis contains exact assigned values, fixed continuous
   intervals, or native frequencies;
4. that color represents the across-family mean;
5. where SD and valid family counts are reported;
6. the insufficient-N rule;
7. the meaning and adjustment family of significance markers;
8. the definition and direction of model advantage when it is displayed.

Captions must distinguish proof-of-concept evidence from final-paper
evidence. The 250-family plots must not be labeled as the final publication
simulation.

These requirements are now enforced by the centralized caption exporter.
For every plot, the complete caption is saved in three connected forms:

1. a plain-text file in the plot group's `Captions` folder;
2. a row in `figure_manifest.csv` beside the image and source-data paths;
3. an entry in the global `figure_captions.md` catalog.

Plot-specific exporters provide the exact-versus-binned axis definition and
the relevant multiple-testing family. The caption builder obtains the
profile, actual family count, insufficient-N threshold, alpha level,
multiple-testing method, and numerical error floor from the saved run. It
also inspects the retained source-data columns to report native frequency
bins, mean, SD, valid N, total group N, standard error, confidence intervals,
and adjusted P values when those quantities exist.

## Reproducibility requirements

The implemented proof-of-concept workflow will save:

- the complete assigned family-design table before signal generation;
- the random seed and per-family seeds;
- a profile and settings manifest;
- marginal level counts;
- pairwise assigned-cell counts;
- realized-bin occupancy;
- assigned-versus-realized validation summaries;
- factor-correlation diagnostics;
- software and toolbox versions;
- numerical checkpoints that can be rendered again without rerunning the
  simulation.

The ten 25-family blocks provide natural stability checks. Results can be
compared after five balanced blocks (125 families), eight blocks (200
families), and all ten blocks (250 families) without destroying the basic
pairwise balance at each checkpoint.

## Chunk 5 proof-of-concept execution audit

The `proof250` profile was completed on 23 August 2026. The numerical stage
took 1,279.3 seconds (21.3 minutes) and saved its reusable result before table
or figure generation. The completed run contains:

| Quantity | Completed count |
|---|---:|
| Independent families | 250 |
| Complete balanced design blocks | 10 |
| Primary observation analyses | 17,000 |
| Ridge analyses | 750 |
| Estimator-sensitivity analyses | 10,750 |
| Audited metric-by-observation support checks | 748 |

All 14 core execution checks passed. Every assigned factor level contains 50
families, and every assigned 5-by-5 factor pair contains 10 families. All 748
audited metric-condition groups meet the five-family display minimum, and no
audited whole-range metric value was nonfinite.

The 125- and 200-family balanced checkpoints were compared with the final
250-family reference-condition means. Across the six complex, gain, and phase
model-advantage outcomes, the largest absolute checkpoint-to-final difference
was 0.0339 at 125 families and 0.0169 at 200 families. These are descriptive
stability checks, not separate hypothesis tests.

Realized-bin occupancy was intentionally audited without changing the fixed
boundaries:

| Realized characteristic | Counts across the five fixed bins |
|---|---|
| Mean MAP-PETCO2 coherence | 51, 49, 50, 50, 50 |
| PSD-shape overlap | 0, 100, 45, 5, 100 |
| PETCO2 contribution-power share | 151, 26, 18, 20, 35 |

The coherence bins are essentially even. Contribution share is uneven but
all five bins meet the display minimum. PSD-shape overlap does not occupy the
0.0-to-0.2 interval, and the 0.6-to-0.8 interval contains exactly five
families. In the three audited joint realized-characteristic grids, 43 of 75
cells meet the display minimum and 13 are empty. The proof-of-concept figures
must therefore show unsupported cells as gray and treat the realized
two-dimensional maps as descriptive. The fixed edges were not moved after
seeing the result.

The final regenerated proof-of-concept library contains 80 figures, 160 image
files, 402 figure source-data files, and 80 individual caption files. The
generator-validation and estimator-frequency layouts were inspected at their
actual 7.2-inch export size and corrected where long labels or panel titles
had overlapped. All 80 manifest rows and all referenced files passed the final
integrity check.

The complete audit is stored with the run as
`Simulation_Audit/simulation_audit.md`. Detailed audit tables are also stored
as CSV files and workbook sheets. The occupancy finding is a design-review
input for `paper1000`: before the final run, the spectral-similarity control,
final continuous-bin definitions, and any family-level continuous models
should be prespecified rather than changed merely to fill the current gray
cells.

## Relationship to the final paper simulation

The proof-of-concept run will determine whether the workflow, parameter
coverage, captions, and figures communicate the method clearly. Before a
1,000-family final run, the following decisions will be made prospectively:

- final number and boundaries of continuous bins;
- final minimum valid family count per displayed cell;
- which interaction maps are primary, secondary, or supplemental;
- whether any family-factor range should be expanded;
- the primary statistical endpoint and multiplicity families;
- whether continuous regression or interaction models are required for
  formal claims.

If the same 25-family balanced block is repeated forty times, every pairwise
assigned 5-by-5 cell will contain 40 families. If a realized 10-by-10 grid is
later justified and approximately evenly occupied, 1,000 families would
average 10 families per cell. Actual occupancy, not this average alone, must
determine whether the finer grid is defensible.

## Chunk 1 review checklist

Before code implementation begins, confirm:

- [x] The 250-family run is labeled as presentation proof of concept.
- [x] The likely final-paper run remains a separate 1,000-family profile.
- [x] The five target-coherence values are acceptable.
- [x] The five spectral-similarity values are acceptable.
- [x] The five fluctuation-ratio values are acceptable.
- [x] The five pathway-gain values are acceptable.
- [x] The five true-delay values are acceptable.
- [x] Continuous time constants remain continuous.
- [x] Five fixed proof-of-concept bins are acceptable.
- [x] Observation and estimator sweeps remain unchanged for the proof run.
- [x] The family remains the independent statistical unit.
- [x] The 250-family run will be audited before any result narrative is
      written.
