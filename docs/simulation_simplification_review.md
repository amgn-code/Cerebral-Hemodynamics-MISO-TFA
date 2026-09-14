# A simpler, defensible MISO–SISO simulation study

**Current protocol:** [frequency-first revision incorporating Shotaro feedback](known_truth_protocol/SIMULATION_PROTOCOL.md). That document supersedes the endpoint hierarchy and illustrative levels below; this file preserves the earlier review.

Review date: 13 September 2026. Recommendation, not an implemented change to the simulator. Based on source inspection, saved project audits, and primary literature; no new simulation was run.

## Recommendation

Retain the existing known-truth simulation as the basis of the paper. Defer learned input/pathway generation. Reduce the main experiment to input coherence, relative CO2 contribution strength, and output disturbance. Keep phase, recording duration, measurement errors, and alternative pathway shapes as focused secondary checks.

The question is: **Under which specified conditions does joint MAP/CO2 analysis recover the generating pathways more accurately than separate single-input analysis?** It is not necessary to recreate the entire distribution of human recordings to answer this question. Population-realistic generation would be a separate research objective.

## How relevant papers establish performance

| Primary study | Validation evidence | Application and limitation |
|---|---|---|
| [Panerai et al., 2000, *Multivariate dynamic analysis of cerebral blood flow regulation in humans*](https://pubmed.ncbi.nlm.nih.gov/10743786/) | In 16 resting normal subjects, adding end-tidal CO2 to pressure significantly reduced model mean-square error; causal FIR responses were physiologically interpreted | Supports examining added explanatory value. The accessible abstract does not establish independent test-record validation; do not describe this result as proof of true pathway recovery |
| [Peng et al., 2008, *Multivariate system identification for cerebral autoregulation*](https://pubmed.ncbi.nlm.nih.gov/18066666/) | In 13 healthy subjects, pressure plus respiratory gases increased multiple coherence below 0.05 Hz; a physiologically based simulation investigated low univariate coherence and altered pressure responses | Direct motivation for omitted-input effects and a simulation/real-data combination. Includes oxygen as well as CO2; increased coherence alone does not establish estimation accuracy |
| [Westwick et al., 2006, *Identification of Multiple-Input Systems with Highly Coupled Inputs*](https://pmc.ncbi.nlm.nih.gov/articles/PMC2590628/) | Generated correlated, band-limited random inputs, applied known filters, added noise, and assessed independent-data output prediction across Monte Carlo trials; also evaluated neural/EMG recordings | Strong methodological precedent for a transparent stochastic generator without neural signal generation. Its principal score is squared output correlation, not our transfer-function error; its input-selection task is not identical to comparing our two estimators |
| [Chertoff et al., 2020, *A Novel Nonlinear System Identification for Cerebral Autoregulation in Human*](https://pubmed.ncbi.nlm.nih.gov/31873829/) | A simulated high-pass pathway plus a nonlinear pathway allowed direct checks of recovered gain, cutoff and phase, followed by application to human recordings | A cerebral-autoregulation precedent for known-system validation. This is linear/nonlinear identification, not a direct MAP/CO2 MISO-versus-SISO experiment |
| [Kouchakpour, Allen and Simpson, 2010, *Nonlinear, multiple-input modeling of cerebral autoregulation using Volterra Kernel estimation*](https://pubmed.ncbi.nlm.nih.gov/21096582/) | Compared normalized model error across structures; benefits varied between subjects, and the abstract reports that a fixed linear pressure-only model had the smallest average error when one model was used across recordings | Counterevidence to a universal “more inputs/complexity is better” claim. Abstract-level review; do not infer an unreported validation split |

These sources support three distinct claims: recovery of known simulated responses, prediction on observations excluded from fitting, and additional explanation of real measurements. They are not interchangeable. A gain/phase difference or a larger coherence is not evidence that one estimate is closer to an unknown human truth.

For this study, make transfer-function recovery primary. The existing independent-realization spectral prediction error is a useful secondary endpoint. Do not call that score a prospective time-domain waveform validation. NC data can show practical differences and plausible operating conditions; they cannot supply exact pathway truth. Bootstrap uncertainty measures precision, not unknown bias. Any real-data cross-validation must preserve time dependence and separate fitting from evaluation; short records limit this option.

## Assessment of the existing study

**Logical: yes.** The generator produces two inputs, applies saved causal filters, adds separately specified observation errors, and gives the same observed recordings to both estimators. `analyzeKnownTruthObservation` evaluates estimates against `freqz` of the actual generating filters. It also uses an independent realization for spectral prediction checks.

**Reproducible for a frozen configuration: substantially supported.** The code saves factor assignments and seeds, restores random state, and has deterministic-design tests. The saved `proof250` audit documents 250 families, all assigned pairwise balance checks, 17,000 observation rows, 750 ridge rows, and 10,750 estimator-sensitivity rows. These are historical checks, not a fresh replay performed during this review.

**Simple enough to explain: no.** Five assigned factors, two randomly varied time constants, multiple noise and duration sweeps, estimator variants, and numerous error summaries obscure the main question. Pairwise balancing is economical and deliberate, not haphazard, but it does not isolate every two-factor interaction from higher-order effects. Marginal summaries average over other changing properties.

**Established physiological population: no.** The project source ledger already distinguishes physiological motivation from assigned engineering ranges. That distinction needs to become visible in the main protocol and plots.

Targeted reproducibility fixes are sufficient: save a complete configuration and code/data provenance; keep scenario/repetition IDs stable; prevent a changed maximum duration or family count from silently redefining previous realizations; separate the band used to calibrate generating gain from the reporting band; verify replay from saved results. None requires model training.

Local evidence: [design specification](proof_of_concept_simulation_design.md), [source ledger](presentation_source_ledger.md), [saved audit](../slides/long_form/source_material/proof250/simulation_audit.md), [generator](../src/validation/generateKnownTruthRealization.m), [analysis](../src/validation/analyzeKnownTruthObservation.m), [defaults](../src/validation/defaultKnownTruthSimulationSettings.m).

## Physiological motivation does not establish every numerical range

It is valid to write that prior work motivated a response shape, then vary its parameters systematically. Each numerical choice should be labeled **directly literature-supported**, **an approximation chosen for this model**, or **a deliberate stress test**. A range need not be physiological to be useful, provided its purpose is explicit.

| Current choice | Evidence status and recommended handling |
|---|---|
| MAP response attenuates slow fluctuations; CO2 has a slower dynamic response | Supported qualitatively by cerebral-hemodynamic work, including [Mitsis et al., 2004](https://www.eng.ucy.ac.cy/gmitsis/Publications/IEEE_TBME_LVNmult_2004.pdf). The exact single-exponential formulas remain modeling approximations |
| MAP time constant 1–4 s; CO2 time constant 2–8 s | Do not claim these are established normal ranges from the sources reviewed. Fix a documented illustrative pair initially and evaluate alternate response shapes/time scales separately |
| CO2 delay 0–10 s | A broad sensitivity interval, not a demonstrated resting-population interval. Transport/instrument delay, response latency and response time constant must not be conflated |
| CO2 spectrum center moves from 0.06 to 0.28 Hz | A deliberately broad separation experiment. It is not established here as typical resting PETCO2 variability; use a slow-input reference spectrum and put broad spectral separation in sensitivity analysis |
| Flat coherence from 0.05 to 0.95, zero population input cross-phase | Controlled identification conditions, not an inferred physiological joint spectrum. Add exact independence as a control; assess phase separately |
| Input SD ratio 0.05–2 and pathway band-gain ratio 0.1–4 | Two separate controls that both influence relative output contributions. Replace their simultaneous primary sweep with one explicitly defined contribution-strength control |
| Duration and SNR sweeps | Observation-quality scenarios. SNR of unexplained output is not automatically an instrument-noise specification |

For a concrete literature anchor, Panerai et al. report a CO2 step response approaching approximately 2.5%/mmHg over about 10 seconds. That is a study-specific response, not a direct justification for this project's dimensionless band-gain ratio or a 10-second exponential time constant.

The [CARNet TFA update](https://pmc.ncbi.nlm.nih.gov/articles/PMC9875346/) supplies standardized acquisition/analysis guidance, including at least 4 Hz interpolation and at least five minutes of suitable stationary recordings. Its conventional bands span 0.02–0.50 Hz. Align the reporting convention explicitly; the current simulation uses a different range. Such a change must not rescale the generating pathways.

NC data are optional for the core simulation. A small descriptive comparison of input SD, spectra and coherence could show where NC observations fall within the experimental grid. It requires reliable timing, but no generative training. Observed NC values should contextualize the grid, not be used to select conditions that favor MISO.

## A small primary experiment

Use one declared input-spectrum pair, one declared pathway pair, 4 Hz sampling, a 300-second retained observation, and one fixed Welch configuration. Preserve the current estimator initially. A standard-setting comparison can be secondary; do not tune Welch settings to maximize a winner.

Illustrative engineering pilot, **not physiological reference intervals**:

| Assigned factor | Pilot levels | Scientific question |
|---|---|---|
| Input magnitude-squared coherence | 0, 0.5, 0.95 | Can the two inputs be distinguished? |
| CO2/MAP contribution RMS ratio in a fixed calibration band | 0, 0.25, 1 | How much does omitting CO2 matter? |
| Output SNR | No added noise, 20 dB, 5 dB | When does finite-record noise outweigh the benefit of the second input? |

This is 27 explicit conditions, each repeated with new random realizations. A pilot of 100 repetitions per condition gives 2,700 paired estimator comparisons; final repetition counts should follow Monte Carlo precision, not a preferred outcome. Paired error differences and their uncertainty are more informative than one grand average over this artificially weighted grid. With 100 repetitions, a worst-case estimated win proportion still has a standard error of about five percentage points.

The contribution ratio means the RMS of the CO2-driven component divided by the RMS of the MAP-driven component, calculated from the designed input spectra and filters over a fixed band. Calibrate pathway scaling before random draws. It is not the fraction of total CBFV variance: correlated component powers have a cross-term. Hold input amplitudes fixed while varying this gain-based factor; check amplitude-based changes later if needed.

The zero-CO2 condition retains a varying CO2 input but sets its pathway to zero. This supplies a true unnecessary-input control. It requires a small implementation change because current validation requires positive gain ratios. Use absolute error for the zero pathway; normalized error and phase are undefined there.

Primary endpoint: normalized complex MAP-pathway error against the saved filter, combining gain and phase discrepancy. Report the CO2 pathway separately as secondary, with absolute error for its null case. Supporting outputs are gain error, circular phase error where meaningful, and failures. Coherence and conditioning explain results rather than becoming additional success scores. Retain absolute estimator-error plots alongside any advantage ratio, and retain failure counts on a common evaluation grid.

## Fairness and focused robustness

No generating system is assumption-free. A fixed linear two-input system matches the intended MISO model class and creates an omitted-input problem for SISO when CO2 contributes and inputs are correlated. That is a legitimate conditional experiment, not proof that MISO is universally superior.

Fairness comes from predeclared conditions, known filters selected independently of estimator results, identical observations/settings, and inclusion of conditions where SISO has little bias or MISO is unstable. Include absent CO2, independent inputs, nearly collinear inputs, and noisy observations. Do not discard valid cases, choose parameter ranges, or change evaluation bands after inspecting which estimator wins. Report recovery of the generating pathway as the target; the population pairwise SISO response is a different quantity when inputs correlate.

Then run three limited checks rather than another full factorial:

1. **Duration:** repeat selected conditions with a longer recording while preserving the underlying realization.
2. **Phase/delay:** vary input timing and pathway delay in separate experiments; generate CBFV after those interventions. MAP–CBFV and CO2–CBFV pairwise phases emerge from the combined system. At fixed input powers/coherence, a pure input-phase rotation does not change normalized input-matrix conditioning; hold absolute noise fixed when isolating phase so output-power changes do not covertly change noise too.
3. **Generator sensitivity:** repeat selected conditions with another defensible input spectrum and pathway shape, plus a declared colored-disturbance case. Input measurement noise/misalignment can be separate practical checks if central to the paper. Nonlinear extensions need a separately defined target and need not be part of the first paper.

This retains substantial variation and repeated random realizations. Simplification means fewer questions per experiment, not making signals deterministic or selecting only easy cases.

## Practical development scope

Keep the existing generator, spectral solvers, truth metrics, checkpoints and report regeneration. Add a small transparent study profile, explicit null controls and one parameter-evidence table; make the main report show the generating system, the 27-condition comparison, and selected robustness checks. Expose configuration through one user entry point while retaining reusable data/generation/analysis/report modules.

The learned-generator proposal remains a future option if the objective becomes population-realistic synthetic recordings. It is not required to establish the present estimator comparison, and `tfest` need not become another primary estimator merely because it is available.
