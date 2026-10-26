# Research and prior-work review

Reviewed 13 September 2026. This document distinguishes inspected implementation, saved experimental results, published evidence, and proposed development. Previous experiments were not rerun for this proposal. MATLAB attachment failed, so live behavior and current toolbox availability remain unverified.

## 1. What the Python project actually contains

Project: `/Users/amoghn/Multiple Input TFA`. The complete original modeling workflow is in [main.ipynb](</Users/amoghn/Multiple Input TFA/main.ipynb>); `main.py` primarily loads, cleans, and splits data. Later investigations are documented in the [model audit](</Users/amoghn/Multiple Input TFA/research/2026-09-model-audit/REPORT.md>) and [model-improvement findings](</Users/amoghn/Multiple Input TFA/research/model-improvement/FINDINGS.md>). Notebook code and saved tabular results were inspected in addition to those reports.

| Component | Inspected implementation | What to carry into MATLAB |
|---|---|---|
| Data | 23 NC baseline workbooks; synchronized 4 Hz interpolation; mean-centered MAP/CO2 in mmHg; CBFV centered after percentage-of-baseline normalization | Explicit channel/unit adapters, participant splits, saved preprocessing |
| G: paired inputs | Linear two-output autoregression, 60 prior paired samples (15 seconds), correlated Gaussian innovations | A useful trained baseline; check free-running stability and recording diversity |
| F: output | Linear FIR, 40 MAP coefficients and 240 delayed CO2 coefficients | The learned coefficients already define two transfer functions; retain compact causal representations |
| Model selection | Original 14/4/5 participant split; final training on 18; later repeated participant-held-out comparisons | Preserve grouping, but acknowledge that the historical test cohort has been reused |
| Later compact model | Paired smooth basis kernels with regularization; bootstrap coefficient draws | A baseline for paired pathway representations, with estimation uncertainty separated from population variation |

The original G and F were trained linear models, not deep neural networks. Learning transfer functions is therefore partly a change in representation, objective, and population modeling: the old F already implies transfer functions. The new proposal explicitly learns a distribution of paired pathway shapes and judges generation separately from waveform prediction.

### Saved results that change the development priorities

| Evidence | Result | Interpretation |
|---|---|---|
| Original F reproduction | Aggregate historical test R² approximately 0.148 | Modest output prediction; not a percentage accuracy |
| Repeated participant-held-out audit | Mean R² approximately 0.277 compact time-domain FIR, 0.274 dense FIR, 0.222 frequency-loss FIR | Frequency-based fitting did not automatically improve waveform prediction; the evaluation target matters |
| G one-step evaluation | Mean MAP/CO2 R² approximately 0.996/0.998 | Measured recent history and interpolation make this an easy prediction task |
| G at ten seconds | Mean MAP R² approximately −0.119, CO2 approximately 0.008 | One-step scores do not establish future waveform accuracy; stochastic generation needs distributional evaluation |
| G free-running statistics | Average amplitudes/coherence broadly similar to recorded averages | A useful baseline exists already |
| G diversity | Between-record spread of CO2 SD about 0.13 for Gaussian generations versus 0.68 for recordings | Matching the population average did not reproduce population diversity |
| Residual diagnostics | Median one-second residual autocorrelation about 0.917; some residual/input dependence | Unexplained output cannot automatically be modeled as independent white measurement noise |

These are historical exploratory results. In particular, the generation comparison includes 23 recorded participants while the original G was fitted to 18; it is not a clean held-out demonstration. The ten-second numbers were checked against `g_horizon.csv`; the generation comparison against `g_generation.csv`. This review does not establish that a new architecture improves either score.

The prior frequency-fitting audit identified an implementation issue worth retaining as a regression check: filtering a complete input and then windowing its output is generally different from multiplying a windowed input FFT by a long filter response. Generate/filter using adequate preceding history before applying analysis windows.

### Timing must be settled before learning phase

The saved [timing audit](</Users/amoghn/Multiple Input TFA/research/model-improvement/raw_cleaned_timing.csv>) reports internal omitted beats in 13 of 23 workbooks, with a maximum raw-versus-cleaned elapsed-span difference of approximately 19.565 seconds. Its reconstruction matches retained measurements to raw rows and uses cumulative raw RR timing. This suggests the cleaned clock compresses omitted intervals; it does not independently establish the acquisition clock.

Recheck those source assumptions before deciding the authoritative time axis. Treating deleted observations as deleted elapsed time can alter frequency and phase. The prior waveform sensitivity was small on average, but that is not a validation of spectral timing. A generator trained on timing artifacts can reproduce them faithfully and still be scientifically misleading.

The NC directory observed during review is `/Users/amoghn/Desktop/ieem_data/NC`, with 23 baseline workbooks. The Downloads NC path configured in the MATLAB project was absent. The new module should accept a path and generate a manifest, rather than guess between these locations. No workbooks were copied or modified.

## 2. What the current MATLAB simulation contributes

The existing project already has known generating filters, explicit scenarios, random seeds, saved settings, reproducibility metadata, and extensive estimator diagnostics. It is not wholly unreproducible. Its weaknesses are partly how experimental choices are coupled and explained.

Relevant entry points are [defaultKnownTruthSimulationSettings.m](../src/validation/defaultKnownTruthSimulationSettings.m), [estimateWelchSpectra.m](../src/analysis/estimateWelchSpectra.m), [solveMisoSpectralSystem.m](../src/analysis/solveMisoSpectralSystem.m), [runMISOTFA.m](../src/analysis/runMISOTFA.m), and [runSISOTFA.m](../src/analysis/runSISOTFA.m).

| Current design | Consequence for the new module |
|---|---|
| Synthetic input spectral shapes and parameter ranges are assigned rather than learned from NC | Describe them as controlled scenarios; do not present them as estimated physiological ranges |
| Shared/independent innovations and real spectral shaping produce a restricted input cross-phase construction | Add an explicit valid complex cross-spectrum for input-phase experiments |
| MAP high-pass-like and CO2 delayed low-pass filters | Keep these as independent analytic references even after learning a pathway library |
| Gain calibration uses the analysis frequency band | Separate generation/calibration settings from reporting settings |
| Generation horizon and family enumeration affect random construction | Stable model/scenario IDs and fixed generation rules are needed for reproducibility across study edits |
| Manual joint spectral solve includes project-specific diagnostics and options | Verify against the built-in unregularized estimator; preserve useful diagnostics rather than assuming the entire implementation is redundant |
| Historical manifests record versions and commit | Also capture dirty source state, data hashes, exact resolved configurations, fitted models, and replayable records |

At 4 Hz, sample spacing is 0.25 seconds, but frequency-bin spacing depends on FFT length. For the project's 128-second/512-sample Welch segment with a 512-point FFT, it is **4/512 = 0.0078125 Hz**. A 300-second full-record transform has spacing 1/300 Hz. Zero-padding gives a finer plotted grid without adding independent resolving information. Spikes at every possible frequency combination are neither necessary nor a feasible exhaustive physiological model: a valid joint spectrum provides a methodical description of power and input relationships across frequencies.

## 3. Primary research supporting the design

| Source | Relevant evidence | Boundary of that evidence |
|---|---|---|
| [Peng et al., 2008, DOI 10.1007/s10439-007-9412-9](https://pubmed.ncbi.nlm.nih.gov/18066666/) | Multivariate cerebral-flow analysis including pressure and respiratory gases changed pairwise transfer estimates and improved multiple coherence, especially at low frequency | Does not show that two inputs explain all physiology or that MISO always has lower finite-sample error |
| [Mitsis et al., 2004](https://www.eng.ucy.ac.cy/gmitsis/Publications/IEEE_TBME_LVNmult_2004.pdf) | Two-input dynamic modeling supports different pressure and CO2 response shapes, with important slow CO2 contributions; also investigates nonlinear behavior | Reported dynamics and delays are study-specific, not universal ranges for this NC cohort |
| [CARNet TFA update](https://pmc.ncbi.nlm.nih.gov/articles/PMC9875346/) | Standardized interpolation, recording duration, preprocessing, and frequency-band reporting make comparisons interpretable | Sampling at 4 Hz does not restore unmeasured information; recommendations do not validate a generative model |
| [Li, Li and Chen, 2011, DOI 10.1155/2011/842183](https://doi.org/10.1155/2011/842183) | Multivariate random-process synthesis from specified spectral relationships supplies a mathematical foundation for paired spectral generation | An engineering construction of second-order statistics is not evidence of physiological realism or higher-order fidelity |
| [Morris, White and Crowther, 2019](https://doi.org/10.1002/sim.8086) | ADEMP separates simulation aims, generating mechanisms, targets, methods and performance; Monte Carlo uncertainty matters | Scientific scenarios and acceptable physiological support still need domain evidence |
| [Yoon, Jarrett and van der Schaar, TimeGAN, 2019](https://proceedings.neurips.cc/paper/2019/hash/c9efe5f26cd17ba6216bbe2a7d26d490-Abstract.html) | Learned time-series generation should assess temporal structure as well as generated distributions | Does not establish controllable MAP/CO2 generation from 23 subjects; it is a possible later comparison, not the recommended first implementation |

The proposed conditional spectral VAE and paired-kernel generator are engineering hypotheses informed by these methods. None of these papers validates this exact combined architecture. Likewise, no literature-based universal MAP–CO2 phase or coherence range has been established here. Estimate cohort/protocol-specific support, with uncertainty, before attaching physiological labels to controls.

## 4. MATLAB functionality and its role

| Capability | Proposed use | Official reference |
|---|---|---|
| `tfestimate` with explicit MIMO mode | Reference implementation for joint Welch-based estimates; two inputs and one output are a MISO case | [Signal Processing Toolbox documentation](https://www.mathworks.com/help/signal/ref/tfestimate.html) |
| `tfest` | Fit compact parameterized transfer functions to recorded data or estimated frequency responses; evaluate shape constraints and model bias | [System Identification Toolbox documentation](https://www.mathworks.com/help/ident/ref/tfest.html) |
| `varm` | Trained paired autoregressive input baseline | [Econometrics Toolbox documentation](https://www.mathworks.com/help/econ/varm.html) |
| `dlnetwork` and modern training APIs | Small generative-network experiments after baseline/library validation; custom loss/loop when needed | [Time-series training](https://www.mathworks.com/help/deeplearning/ug/training-neural-networks-with-time-series-data.html), [VAE implementation example](https://www.mathworks.com/help/deeplearning/ug/train-a-variational-autoencoder-vae-to-generate-images.html) |

`tfestimate` and `tfest` answer different modeling questions. The former estimates frequency responses from spectra; the latter fits a selected pole/zero structure. `tfest` may supply smooth compact library candidates, but selecting more poles is not automatically more accurate. Neither function trains a distribution of new pathway pairs. The VAE example demonstrates MATLAB mechanics, not a ready-to-use physiological network.

No new model was trained, toolbox installed, or Python source changed for this proposal. The next work is defined by stages 0–3 in the [development proposal](DEVELOPMENT_PROPOSAL.md): data/environment audit, estimator verification, paired-input baselines, and the transfer-function library.
