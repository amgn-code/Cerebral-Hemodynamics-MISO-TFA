# MATLAB model generator: development proposal

Date: 13 September 2026. Status: proposed design, pending implementation and measured validation. Numerical training gates below must be finalized from development-data uncertainty before final evaluation; they are not claims of achieved performance.

## 1. Objective and recommendation

Build a MATLAB module that can generate paired MAP/PETCO2 fluctuations, generate paired MAP-to-CBFV and PETCO2-to-CBFV pathway models, combine them into synthetic recordings, and evaluate MISO/SISO against the exact generating responses.

The user should be able to choose duration, a seed, an input template, and a small set of scientifically meaningful controls. A report must explain what was requested, what was generated, which parameters were learned, and which were imposed.

Proceed with two learned components:

1. **G: paired input generator.** Start with a trained, stable vector autoregression and an empirical spectral-template baseline. Develop a conditional spectral generator only if those baselines cannot reproduce important recording variation.
2. **T: paired transfer-function generator.** First create and validate a library of estimated pathway pairs. Establish representative-pair and compact statistical sampling baselines, then evaluate a small generative model of causal filter coefficients.

This is not a proposal to train another unrestricted MAP/CO2-to-CBFV waveform network. `tfest` can help prepare compact examples for T; it does not itself learn a population distribution or generate new population members. The earlier simulation stays available as an independent known-system reference.

## 2. The MISO/SISO difference is manageable, but the target must be explicit

Let centered inputs be M and C, and let the generated output be

`y = h_M * M + h_C * C + e`,

where `*` means causal convolution. With fixed linear filters, disturbance uncorrelated with both inputs, and a nonsingular input spectral matrix, the population joint transfer functions are H_M and H_C.

Define `S_MC = E[conj(M(f))*C(f)]`. The population pairwise relationships are

`H_SISO,MAP = H_M + H_C*S_MC/S_MM`

`H_SISO,CO2 = H_C + H_M*conj(S_MC)/S_CC`.

These equations follow directly from the stated generator. The extra terms explain why separate SISO curves differ from joint pathways. They change with the input distribution even if the generating filters remain unchanged. Related cerebral-hemodynamic evidence is given by [Peng et al.](https://pubmed.ncbi.nlm.nih.gov/18066666/).

Consequences for the library and training:

- Compute and retain MISO and both SISO curves for every eligible recording.
- Use distinctly labeled **paired joint-pathway candidates** as the first T training target. Do not combine MISO and SISO examples under the same label.
- Retain SISO curves as observed pairwise descriptors and comparator targets. Generating their distribution could be a separate task, not the definition of two component filters for one output.
- A generated joint pair is exact truth only after it is frozen and used in the simulator. The source estimates remain uncertain approximations to physiology.
- Evaluate both methods against the same generating pathways for the primary structural-recovery question. Also check SISO against its analytic marginal target when the input model makes that target available. This separates omitted-input effects from finite-record estimation error.
- Include independent-input, absent-CO2, near-collinear, low-excitation, and noisy cases. MISO must be allowed to lose. No subject, curve, or simulation is removed because it favors SISO.
- Joint spectral estimation and `tfest` are both models. They do not prove causal physiological pathways in the presence of shared unmeasured drivers, feedback, measurement error, or changing dynamics.

The research claim is initially **recovery of known simulator pathways under specified conditions**, not discovery of the true human pathways. Avoid validating only on functions produced by the same estimator under evaluation: retain analytic filters, multiple library-construction methods, and held-out input conditions.

## 3. Data foundation before training

The prior Python work used 23 NC participants. Their recordings are approximately 270–347 seconds after its cleanup. A 4 Hz interpolation grid does not provide four independent measurements per second. Its subsequent timing audit reports 13 cleaned workbooks with omitted internal beats and compressed elapsed time; this is saved audit evidence that must be rechecked against the chosen source files.

Create a dataset manifest with source path/hash, participant ID, recording ID, cohort, protocol, sheet, channel mapping, units, and timing provenance. Use an explicit supplied path. The Python NC path currently exists; the MATLAB script's configured Downloads NC path does not.

Data decisions:

- Preserve elapsed time when removing bad measurements; do not close gaps by changing the clock.
- Compare raw/cleaned timing and document any reconstruction assumptions. A reconstructed clock is not automatically acquisition truth.
- Define short-gap interpolation, long-gap segmentation, startup handling, and quality flags before model selection. Keep paired channels synchronized.
- Work with the recorded beat-mean MAP and end-tidal CO2 representation. A generator of these interpolated signals does not recreate raw arterial pulses or capnograms.
- Keep baselines and fluctuation units separate. MAP and CO2 remain in mmHg unless a reversible, recorded training transform is used; CBFV fluctuations can be percentage points of baseline. Record the baseline needed for cm/s conversion.
- Full-record means define a retrospective fluctuation-analysis task. Prospective absolute-CBFV prediction would need a separately available baseline/calibration interval; it must not silently use the future output mean.
- Split by participant before windows, learned normalization, PCA, clustering, or training. Repeated recordings and alternate sheets stay in the same fold. No lagged history crosses recording boundaries.
- All 23 historical subjects have influenced prior development; subsequent cross-validation is exploratory internal evaluation. It cannot manufacture an untouched external cohort.
- Preserve cohort/protocol labels if data expand beyond NC. Do not silently turn pooled ranges into NC ranges.

[CARNet guidance](https://pmc.ncbi.nlm.nih.gov/articles/PMC9875346/) supports standardized signal preparation and TFA reporting. It does not validate an individual worksheet clock or this learned generator.

## 4. Component G: learn paired MAP and CO2 generation

### 4.1 Properties that matter

Preserve each signal's amplitude distribution, power spectrum, autocorrelation and increments, plus joint cross-spectrum, coherence, phase where estimable, cross-correlation, and recording-to-recording diversity. Check slow drift/stationarity separately. Shared physiological influences may involve respiration and autonomic regulation, but a two-channel fit cannot identify those hidden mechanisms or a universal direction of causation.

Correlation at zero lag is insufficient: it does not determine frequency-dependent coherence or relative phase. Likewise, a correct average PSD is insufficient if every generated recording has nearly identical amplitude and spectral shape. The Python audit already identified this diversity limitation.

### 4.2 First trained baseline: G-VAR

Port the existing model concept, not its notebook layout: a regularized bivariate autoregression with correlated two-channel innovations. At each step it predicts both inputs from their recent histories, then draws a paired innovation.

- Compare a small memory/regularization menu within participant-disjoint development folds. The prior 15-second memory is a candidate, not a fixed optimum.
- Train on each recording separately when constructing histories; pool sufficient statistics with deliberate participant weighting.
- Require stable dynamics. Check the correctly ordered companion matrix and long free-running trajectories. Reject or explicitly refit unstable candidates rather than silently clipping eigenvalues.
- Preserve innovation covariance and evaluate paired-block innovations if residual dependence remains. Do not resample the two innovation channels independently.
- Use a small library of supported parameter/template variants to model diversity. Randomly averaging stable autoregressive coefficient sets does not guarantee stability; test every generated set.
- Choose warmup using settling diagnostics and the slowest supported dynamics. Save initial conditions and the discarded interval.
- Evaluate free-running generations, not only one-step forecasts using measured history.

MATLAB options are `varm`/`estimate`/`simulate` with Econometrics Toolbox, or an explicitly tested regularized regression implementation when that toolbox is unavailable. [MathWorks VAR documentation](https://www.mathworks.com/help/econ/varm.html).

### 4.3 Controllable spectral baseline: G-Spectral

Estimate smooth joint spectral templates from development recordings. Retain amplitudes and the complex input relationship together. Generate new Fourier realizations consistent with a valid positive-semidefinite input spectral matrix, enforce real-signal symmetry, and transform to time.

Prescribed multivariate spectra are an established simulation construction; they specify second-order statistics, not all higher-order/nonstationary behavior. [Li et al.](https://doi.org/10.1155/2011/842183).

Use positive power parameterizations and complex coherency constrained to magnitude at most one. Coherence is its squared magnitude. Near zero coherence, input phase is poorly defined: represent the complex coherency and mask unsupported phase interpretation rather than learning arbitrary angles. Check spectral-matrix validity after interpolation and every user intervention.

This baseline provides transparent control of power and phase; G-VAR provides a direct continuation of the previous trained generator. Compare them on identical held-out recording characteristics before selecting a default. Do not concatenate independent generated windows to manufacture a long recording; boundaries can create artificial spectral content. Fix a versioned master generation horizon or stream method so adding a duration does not change old realizations.

### 4.4 Learned extension: G-Conditional

If baseline generators miss meaningful diversity, test a small conditional variational autoencoder on a compact representation of joint spectra and recording-level scales. The network learns a distribution of valid spectral parameters; a deterministic mathematical synthesis step generates the waveforms.

Proposed representation: smooth-basis coefficients for log powers, bounded complex coherency, and baseline/scale context. Condition on a few declared controls; use latent randomness for remaining variation. Fit transforms and conditioning normalization only on training participants. A decoder must preserve nonnegative powers and valid coherency by construction. Do not use an image VAE example unchanged as a time-series solution.

Evaluate reconstruction, latent sampling, diversity, control fidelity, held-out distribution agreement, and memorization separately. A network that reconstructs recordings but samples poor new spectra fails generation. This is a proposed research architecture, not a validated cerebral-hemodynamic method. With 23 participants it may offer no reliable benefit. Use a learning curve and baseline comparison to determine whether more independent recordings are needed.

A raw-waveform conditional generator or TimeGAN is a later challenger only if preserving higher-order temporal behavior becomes necessary and data support it. [TimeGAN](https://proceedings.neurips.cc/paper/2019/hash/c9efe5f26cd17ba6216bbe2a7d26d490-Abstract.html) motivates joint temporal evaluation; its published benchmarks do not establish suitability here.

### 4.5 User controls and their meaning

| Control | Implementation/qualification |
|---|---|
| Duration, seed, template ID | Exact bookkeeping; duration derived from a saved underlying realization |
| MAP and CO2 mean | Add baselines after centered generation; this does not simulate baseline-dependent physiology |
| MAP and CO2 fluctuation SD | Positive scaling, with requested/achieved values reported; finite-record normalization must be declared |
| Relative low-frequency power | Constrained spectral-shape modification; total power and other changes reported |
| Input coherence | Valid cross-spectrum modification at fixed auto-spectra; a single VAR innovation-correlation control is not equivalent to arbitrary frequency-wise coherence |
| Input phase/relative delay | Modify the joint input process before generating CBFV; preserve valid spectral symmetry |
| Pathway gain/delay | Modify T, not G; report whether within training support or a stress scenario |
| Measurement timing error | Apply after generating the output; separate from true input/pathway timing |

Provide two modes: **empirical sampling**, preserving observed joint combinations, and **controlled intervention**, deliberately changing specified features. Changing coherence, spectral shape, and phase can affect other characteristics. Return actual achieved values and any feasibility failure; do not silently clamp impossible requests. Out-of-support requests are labeled extrapolation/stress tests, not physiological predictions.

## 5. Component T: learn and generate paired transfer functions

### 5.1 Library construction

For each recording, compute the existing joint spectral estimate and both individual SISO estimates from common preprocessing/spectra. Store complex responses, wrapped phase, units, frequency grid, signal power, relevant coherences, conditioning, usable duration, and quality masks.

Verify the existing unregularized implementation against `tfestimate(...,"mimo")` under matched window/overlap/FFT settings with extra spectral smoothing disabled. Confirm cross-spectrum orientation and phase using known delays. Without explicit joint mode a matrix/vector call can produce separate estimates. Verify the custom smoothing separately; matching unsmoothed results does not validate every extension. [MathWorks tfestimate](https://www.mathworks.com/help/signal/ref/tfestimate.html).

Create compact candidate representations through:

1. Causal finite-impulse-response basis fits to complex joint curves, weighted by available uncertainty/support.
2. `tfest` fitted to joint frequency-response data as a competing representation.
3. An optional direct joint `tfest` fit to the recorded inputs/output as a sensitivity check, not a replacement for the requested transfer-function learning task.

Use a small predefined pole/zero/delay menu. One-, two-, and three-pole candidates are a starting engineering menu, not claims about physiology. Set stability constraints explicitly, retain diagnostics, and select using development validation. At 4 Hz, record the sample time as 0.25 seconds using an appropriate data object or discrete-time options. Never accidentally accept the one-second assumption of a raw-matrix continuous-time call. [MathWorks tfest](https://www.mathworks.com/help/ident/ref/tfest.html).

Spectral smoothing and compact fitting can reduce variance while adding model bias. Reject neither unfavorable MISO curves nor unusual valid physiological recordings merely for appearance. Retain all original estimates; distinguish unavailable/unidentifiable pathways from poor fit to a chosen compact representation.

### 5.2 Representation for learning

The first learnable representation is a pair of real, causal FIR kernels in a fixed smooth basis. A finite causal kernel is bounded-input/bounded-output stable and determines consistent gain and phase curves. Its basis/support still limits the shapes it can represent. Include a library-quality check for reconstruction error and support sensitivity.

Do not independently interpolate poles or average rational-model coefficients: that can break stability and has pole-ordering ambiguities. Convert supported compact models to a common representation only after checking truncation error and tail energy. The learned band (proposed 0.02–0.50 Hz) does not identify the response outside that band. Save a full realizable filter and label its out-of-band extension as an assumption. Include DC/baseline handling and sensitivity to that extension; never apply an arbitrary band-only inverse FFT and assume causality.

Train both pathways jointly to preserve their paired variation. Preserve units and normalization. Include input-template/context IDs so a typical joint input pattern can stay associated with its pathway pair. Cross-pairing a pathway with unrelated input context is allowed only as a declared stress experiment.

### 5.3 Actual generative training

T0: sample accepted paired library members. This is a reproducible empirical baseline, not a new-curve generator.

T1: learn a low-dimensional distribution of paired basis coefficients using PCA/probabilistic PCA plus a regularized latent distribution. Generate new latent samples and decode to paired kernels. Preserve signs where necessary; do not impose universal positive impulse coefficients on an autoregulatory response. Quantify fidelity, diversity, rejected draws, and extrapolation.

T2: compare a small conditional VAE operating on the same paired coefficient representation, trained on examples of transfer functions rather than directly predicting CBFV. The decoder produces paired kernels; custom reconstruction loss can compare their complex frequency responses and gain/phase where supported. Use reconstruction plus latent regularization and narrowly justified shape penalties. Phase losses must be circular or based on complex values, not naive wrapped-angle MSE.

Select T2 only if generated—not merely reconstructed—pairs improve held-out distribution and control metrics over T0/T1. Bootstrap fits and windows from the same participant are not new independent physiological examples. Keep within-record estimation uncertainty distinct from between-participant variation; bootstrap scatter is not automatically a biological range.

No clustering is mandatory. If useful for user-facing template selection, test stability and a no-cluster alternative before assigning physiological names.

## 6. Output synthesis and exact truth

Freeze one input template, one paired pathway draw, and their seeds. Generate inputs with adequate history; apply the saved causal filters to the full signals; discard warmup afterward. The saved filter responses evaluated at analysis frequencies define truth. Do not re-estimate truth from a clean finite synthetic recording.

Store MAP contribution, CO2 contribution, clean combined output, background disturbance, and all measurement noises separately. With correlated components, component-power shares do not sum into an attribution of total output variance without a cross-term. Label them accordingly.

Disturbance modes: no disturbance; independent colored disturbance; white output measurement noise; separate input measurement noises; and an explicitly correlated-disturbance stress case. The earlier Python audit found strongly colored residuals and some residual/input dependence. Residual power is not automatically measurement noise. Estimate a residual-shape model only from appropriately held-out or cross-fitted residuals within the development pipeline and disclose its interpretation.

All MAP/CO2/CBFV phase relationships arise from the same valid system. Input phase, pathway phase, and measurement misalignment are different controls. Do not independently request all three pairwise phases as unconstrained values. At fixed input powers/coherence, pure input-phase rotation does not by itself change normalized two-input conditioning. Analytic SISO complex-bias magnitude can also remain unchanged under pure phase rotation, while its gain/phase decomposition changes. Test these invariances so apparent phase effects from finite windows or SNR scaling are not misreported as universal mechanisms.

Hold noise amplitude fixed when isolating phase effects, or explicitly label constant-SNR experiments: constructive/destructive component combinations change total output power, and constant-SNR scaling then changes noise amplitude too.

## 7. Evaluation and acceptance gates

Use the ADEMP structure for the simulation protocol: aim, generating process, target, estimators, and performance. Report paired Monte Carlo uncertainty and failures. [Morris et al.](https://doi.org/10.1002/sim.8086).

| Gate | Required evidence |
|---|---|
| Data validity | Verified participant identities/units; explicit clock/gap policy; exclusions independent of estimator preference |
| Estimator correctness | Known gain/delay recovery; built-in comparison under matched settings; singular/weak-input and unit-scaling behavior |
| G fidelity | Held-out input PSD, SD, autocorrelation, increments, coherency and phase support; diversity across recordings; long-run stability |
| G controllability | Requested-versus-achieved quantities, valid spectral matrices, effects on untargeted characteristics, out-of-support labeling |
| T fidelity | Supported reconstruction and generated-pair distributions; causal stable filters; low-gain phase treatment; no participant leakage |
| Empirical support | Source uncertainty retained; real/real development variability supplies a reference for discrepancies; independent cohort confirmation remains separate |
| Synthetic recovery | Same observations for all estimators; complex error primary, gain/circular-phase error supporting; both pathways; valid counts and absolute error in zero-pathway cases |
| Reproducibility | Reload/replay matches signals and scientific outputs; reordered/resumed runs preserve IDs and seeds; render-only actions do not refit |

G has no single meaningful waveform accuracy score against an unrelated random realization. Evaluate distributions and dynamics. One-step R2 is only a diagnostic. For T, smoother curves and better training loss do not prove physiological validity. Predefine primary comparisons; keep other diagnostics in an advanced report.

Choose numerical acceptance margins using development uncertainty and scientific tolerance before touching final evaluation. Do not repeatedly redefine thresholds until a candidate passes. Use participant-level resampling for population uncertainty. For time-series resampling, keep channels together and preserve dependence; record boundaries must not introduce artificial spectral events.

Approximately five-minute recordings with three 128-second Welch windows do not support ordinary random-window or half-record MISO cross-validation. Prefer repeated/longer records when available. Subject-held-out library/generator evaluation is feasible as exploratory analysis, but it answers a different question from within-person prediction. Do not claim a per-person fitted curve was validated on that same record.

### First simulation questions: keep controls separate from scores

The first pilot should vary input coherence and relative input phase while holding a saved pathway pair, input powers, duration, and output-noise amplitude fixed. Repeat with a few accepted pathway pairs and fresh input realizations. Then separately vary the relative pathway delay. This directly addresses the user's phase question without changing every aspect of a recording at once. Check actual achieved coherence and phase support in each record.

Priority candidate factors for subsequent studies, in order of the question they resolve:

| Factor to vary | Why it matters | Source of values |
|---|---|---|
| 1. MAP–CO2 coherence | Ability to distinguish the two inputs | Development-data support plus explicit near-collinear stress cases |
| 2. MAP–CO2 relative phase/delay | Relative timing of input contributions | Supported cross-spectrum estimates; controlled rotations labeled interventions |
| 3. Relative CO2/MAP contribution strength | Size of the omitted pathway in a single-input analysis | Input powers and paired pathway library, retaining their units |
| 4. Relative pathway delay/phase | How MAP and CO2 contributions combine in CBFV | Causal paired filters; delay changes documented as interventions |
| 5. Output disturbance amplitude | Finite-record error under unexplained output variability | Cross-fitted residual scale as a qualified reference; noiseless anchor |
| 6. Input spectral overlap/excitation | Whether both pathways are measurable in the same band | Joint spectral templates and declared low-excitation stress cases |
| 7. Recording duration | Variance and amount of independent spectral averaging | Explicit study durations using the same underlying realization |
| 8. Input measurement noise | Bias from uncertain MAP/CO2 measurements | Instrument evidence if available; otherwise labeled sensitivity values |
| 9. Pathway shape/time scale | Dependence of findings on one chosen generating response | Accepted paired library plus independent analytic filters |
| 10. Nonstationarity | Failure of the fixed linear model assumption | Later extension with documented changes over time |

These are candidate experimental factors, not ten mandatory simultaneous sweeps. Some are coupled: changing contribution strength can be achieved through input amplitude or pathway gain, and those mechanisms must be distinguished. Input/output pairwise phase is measured from the resulting system rather than independently assigned. Begin with one primary score—complex transfer-response error against the saved filters, reported for each pathway—and supporting gain/phase error and failure counts. Keep coherence and conditioning as explanatory diagnostics, not additional competing definitions of success.

## 8. Modular implementation and user workflow

Only the proposal documents exist today. Planned implementation:

```text
model_generator/
  README.md
  DEVELOPMENT_PROPOSAL.md
  RESEARCH_AND_PRIOR_WORK.md
  runModelGenerator.m                  short user entry point
  config/                             complete presets, schema, validation
  +mg/
    +data/                            manifest, timing, import, splits
    +inputs/                          VAR, spectral, conditional candidates
    +pathways/                        estimation, representation, T training
    +synthesis/                       compose signals, noise, exact truth
    +validation/                      scientific checks and comparisons
    +reporting/                       compact report and audit tables
    +provenance/                      hashes, random streams, replay
  examples/                           small documented MATLAB examples
  tests/                              focused scientific regression tests
```

Use MATLAB namespaces and avoid a second copy of the existing spectral solver. Initial adapters call `estimateWelchSpectra`, `runMISOTFA`, `runSISOTFA`, `solveMisoSpectralSystem`, and relevant error helpers. Refactor existing code only when a verified requirement demands it. Avoid calling the current global `main.m` as a library: it clears variables, closes figures, and configures unrelated workflows.

Proposed conceptual calls (not implemented APIs):

```matlab
cfg = mg.configure(dataPath, outputFolder);
library = mg.prepareLibrary(cfg);
models = mg.train(library, cfg);
record = mg.generate(models, request);
report = mg.evaluate(record, cfg);
replayed = mg.replay(savedManifest);
```

Contracts:

- **Recording:** time, fs, aligned channels, baseline/unit metadata, participant/recording IDs, QC/gap masks, provenance. Use one declared samples-by-channels orientation and adapters for legacy row arrays.
- **Input model:** type, fitted parameters, joint template, condition support, training IDs, transformations, innovations, validation status, version.
- **Pathway model:** paired causal filters or verified realization, fs, units, source method, supported band, context, uncertainty, validation status.
- **Generation request:** seed, duration, template/model IDs, empirical/intervention mode, named controls, noise settings.
- **Generated record:** all components, exact filters/responses, marginal target when available, requested/achieved diagnostics, warmup and provenance.

Default reports: data readiness; input fidelity; paired pathway library; generated recording with known truth; estimator comparison. Store complete numerical results separately and regenerate plots without training.

## 9. Reproducibility contract

Hash source files, the resolved configuration, split manifests, preprocessing choices, fitted model files, and source code including uncommitted changes. Record MATLAB/toolbox versions and execution device. Stable scenario IDs identify scientific settings; repetition IDs identify randomness. Separate random streams for design, inputs, T latent draws, disturbances, measurement noise, resampling, and training.

Freeze the generation horizon and out-of-band spectral grid independently of display settings. Do not let a new maximum duration, family count, plotting band, or loop order silently alter existing cases. The current simulation's band-gain normalization uses the analysis band; the new module separates calibration and reporting bands.

Save models and exact representative/test signals, not merely seeds. Checkpoint per completed case, resume by IDs, and save failure logs. Same-environment numerical replay uses declared tolerances; bitwise identity across MATLAB releases/devices is not promised. Python/MATLAB parity uses shared numeric inputs/innovations and coefficient ordering, not an assumption that equal seed integers yield equal random numbers.

## 10. Development sequence

| Stage | Deliverable | Exit criterion |
|---|---|---|
| 0. Data and environment | Explicit data manifest, timing comparison, MATLAB capability report | Paths and timing are reviewable; requirements known |
| 1. Estimator verification | Existing-vs-built-in checks and fixed known-system examples | Complex coefficients/phase conventions verified; discrepancies explained |
| 2. G baseline | MATLAB paired VAR plus spectral-template baseline, saved generation examples | Stability, fidelity, diversity and control report completed |
| 3. T library | Paired MISO/SISO curves, uncertainty, FIR/`tfest` candidates | Source labels, filter validity and low-information cases documented |
| 4. Generative training | T0/T1 baseline; gated G-Conditional and T2 experiments | Added complexity justified by held-out generation evidence or retained as experimental |
| 5. Integration | G + T + separate disturbance + existing TFA | Exact truth and component accounting verified end-to-end |
| 6. Focused pilot | Input-phase/coherence and pathway-phase experiments; duration/noise robustness | Monte Carlo precision, invariance checks and failures reported |
| 7. Release | Short entry point, replay, report regeneration, documentation | Another user can run and reproduce a saved example without internal edits |

Stages 2 and 3 use the same frozen data/splits; neither is allowed to tune against final simulation advantage. The first implementation should reach stages 0–3 before large neural training. This is a development dependency, not a conclusion that generative learning is unnecessary.

## 11. MATLAB requirements and unresolved decisions

Signal Processing Toolbox supports the spectral analysis. System Identification Toolbox is needed for `tfest`; Econometrics Toolbox is optional for `varm`; Statistics and Machine Learning Toolbox supports statistical baselines; Deep Learning Toolbox supports the proposed neural generators. Use `dlnetwork`/`trainnet` and explicit custom losses for compatible training. Use custom loops only where required by the selected architecture/optimization; review the exact release APIs during implementation.

The historical R2025b manifest does not list System Identification, Econometrics, or Deep Learning Toolbox. Live attachment failed during this review, so their present availability/licenses are unverified. No installation was attempted. Plan CPU-scale development on this Mac; standard Parallel Computing Toolbox GPU acceleration is not available on macOS. [MathWorks platform requirements](https://www.mathworks.com/support/requirements/matlab-mac.html).

Decisions to resolve from stage 0 evidence: the authoritative time axis/gap policy; available repeat recordings; independent dataset availability; library support length and frequency band; empirical fidelity tolerances; and whether participant count supports a neural generator beyond the compact baselines.
