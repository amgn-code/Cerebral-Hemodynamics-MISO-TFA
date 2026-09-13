# Machine-learning cerebrovascular simulator: language and prior-work landscape

Research snapshot: 5 September 2026

## Bottom line

Python can be every bit as object-oriented and modular as C++. Language choice does not determine whether a new physiological input, mechanism, or model parameter is easy to add; the determining factors are stable interfaces, separation of configuration from implementation, tests, and data contracts. C++ becomes valuable when the finished model has a concrete deployment requirement such as hard or near-real-time execution, an embedded target, predictable memory/latency, or integration into an existing C/C++ system.

The scientifically important finding is that nonlinear two-input modeling of MAP/ABP and end-tidal CO2 to predict CBFV is already established. The proposed project should therefore not claim novelty for that mapping alone or call a learned model absolute physiological ground truth. Its defensible contribution may instead be a reproducible **known-simulator-truth benchmark**: learn a plausible conditional cerebral-hemodynamic simulator, freeze it, define local responses of that simulator under controlled perturbations, and measure how accurately SISO and MISO TFA recover them as recording duration, input correlation, nonlinearity, and measurement noise vary.

## Python versus C++

Python's class system bundles data and behavior and supports inheritance and method overriding, so C++ does not have a monopoly on object-oriented design ([Python class documentation](https://docs.python.org/3/tutorial/classes.html)). Python also has modules, abstract base classes, dataclasses, protocols/type annotations, and mature test/configuration ecosystems. In a research project, those features usually make architectural changes faster because there is no compile/link cycle and the machine-learning ecosystem is strongest in Python.

C++ offers different advantages:

- explicit ownership and tighter control over allocation and data layout;
- static typing and compile-time checking;
- lower interpreter overhead and more predictable runtime behavior;
- better suitability for embedded, real-time, or existing native systems.

Those advantages matter for deployment, but they do not inherently make the model easier to extend. A monolithic C++ program is less modular than a well-factored Python package; a well-factored C++ program can likewise be excellent.

### Recommended division of labor

1. Train, analyze, and run research experiments in Python.
2. Define a small, language-independent inference contract early, for example `[batch, time, 2] -> [batch, time, 1]`, plus explicit state if the model is recurrent.
3. Keep preprocessing constants, channel names/units, sampling rate, window length, and physiological/model parameters in a versioned configuration rather than hard-coded in a class.
4. Export frozen models to ONNX and run parity tests on representative signals. PyTorch documents `torch.onnx.export(..., dynamo=True)` as its current recommended exporter ([PyTorch ONNX documentation](https://docs.pytorch.org/docs/stable/onnx.html)).
5. Load the exported model in a small C++ runtime only when deployment requirements justify it. ONNX Runtime provides a C++ API and packages for major desktop platforms ([ONNX Runtime C++ documentation](https://onnxruntime.ai/docs/get-started/with-cpp.html)).

This preserves rapid Python experimentation while leaving a disciplined migration path. If low-level work is personally motivating, a small C++ inference harness can be built early against a dummy linear model; it should not hold up the scientific prototype.

## Direct scientific precedents

| Work | Inputs and output | Method | Implication for this project |
|---|---|---|---|
| Mitsis et al. (2004) | Beat-to-beat MAP and breath-to-breath ETCO2 -> beat-to-beat CBFV | Multiple-input nonlinear Laguerre–Volterra network | This is a direct precedent for the core conditional mapping. It reported important CO2 effects and nonlinear interactions at low frequencies. ([PubMed](https://pubmed.ncbi.nlm.nih.gov/15536895/), [paper](https://www.eng.ucy.ac.cy/gmitsis/Publications/IEEE_TBME_LVNmult_2004.pdf)) |
| Panerai et al. (2004) | ABP -> CBFV | Time-lagged recurrent neural network | Neural dynamic modeling of cerebral autoregulation is also longstanding, although this study did not include CO2. ([PubMed](https://pubmed.ncbi.nlm.nih.gov/14644597/)) |
| Marmarelis et al. (2012) | MABP and ETCO2 -> MCBFV | Linear/nonlinear principal dynamic modes derived from Volterra modeling | Establishes another compact nonlinear multi-input framework and model-derived responses. ([PMC](https://pmc.ncbi.nlm.nih.gov/articles/PMC3377891/)) |
| Mitsis et al. (2016) | ABP, ETCO2, and heart rate -> CBFV | Three-input nonlinear principal dynamic modes | Demonstrates that the model can be expanded with an additional physiological input; adding inputs is not unique to modern deep learning. ([PMC](https://pmc.ncbi.nlm.nih.gov/articles/PMC4822442/)) |
| Marmarelis et al. (2013) | Coupled MAP, CBFV, and ETCO2 | Closed-loop nonlinear PDM models | Relevant if pressure and flow feedback makes a strictly open-loop causal interpretation inadequate. ([PMC](https://pmc.ncbi.nlm.nih.gov/articles/PMC3625507/)) |
| Briggs et al. (2026), CereBRLSIM | CPP/physiological drivers including ETCO2 -> CBF/CBV-related dynamics and latent regulation | Physics-informed ODE digital twin personalized to patient data | A current mechanistic alternative and comparator. It is not the same as a joint MAP–CO2 stochastic generator plus learned CBFV emulator. ([article](https://www.nature.com/articles/s41746-026-02600-x), [MIT-licensed MATLAB code](https://github.com/jenniferkbriggs/CereBRLSIM)) |

These precedents mean that “a sophisticated nonlinear model with MAP and CO2 inputs and CBFV output” is not, by itself, a new scientific contribution. A modern LSTM, GRU, or temporal convolutional network is a different implementation, not automatically a new research question.

## What can be reused

### 1. Established nonlinear baselines

The 2004 Laguerre–Volterra network and later PDM models should be treated as scientific baselines, not ignored. USC's LYSIS 7.2 package is a MATLAB system-identification suite available by registration; its site lists non-parametric modeling, neural networks, and principal-mode analysis, but its terms prohibit redistribution without permission ([LYSIS download and terms](https://bmsr.usc.edu/software/lysis/download/)). It may help reproduce established methods, although an independent, tested implementation may eventually be preferable for reproducibility and licensing.

### 2. Mechanistic model

[CereBRLSIM](https://github.com/jenniferkbriggs/CereBRLSIM) provides MIT-licensed MATLAB ODE code and fake example data. It can be used as:

- a mechanistic comparator to a learned emulator;
- a source of physiologically interpretable stress tests;
- a second simulator for checking whether conclusions about SISO versus MISO depend on one learned model.

It should not simply replace the proposed model without checking whether its variables, time scale, cohort, and output definition match the IEEM/TFA question. The accompanying study used six neurocritical-care patient datasets for personalization and explicitly notes that operational real-time bidirectional deployment and validation of the physiological meaning of inferred parameters remain future work ([article](https://www.nature.com/articles/s41746-026-02600-x)).

### 3. Processing and conventional analysis

[CAAos](https://caaosplatform.github.io/CAAos/index.html) is an open-source Python platform for preprocessing and analyzing multichannel cerebral-autoregulation records. It is useful as an external reference for preprocessing and conventional CA metrics; it is not a trained MAP/CO2/CBFV generator. Its repository is GPL-3.0, so code-copying implications should be reviewed before integration ([GitHub](https://github.com/CAAosPlatform/CAAos)).

### 4. External datasets

PhysioNet hosts potentially relevant synchronized physiological datasets. For example, [Cerebral Vasoregulation in Elderly with Stroke](https://physionet.org/content/cves/1.0.0/) contains 60 stroke participants and 60 controls with high-resolution blood-pressure, CO2, respiration, and transcranial-Doppler recordings across protocols. [Cerebral Perfusion and Cognitive Decline in Type 2 Diabetes](https://physionet.org/content/cerebral-perfusion-diabetes/1.0.0/) contains TCD velocity and cardiovascular/respiratory variables in 70 participants with type 2 diabetes and 70 controls. These are promising for external validation, but channel synchronization, protocol compatibility, units, missingness, access conditions, and cohort differences must be audited before combining them with IEEM data.

## Where the proposed contribution can still be new

Subject to a formal systematic review, the following combination appears distinct from the direct precedents located in this search:

1. a learned joint generator for synchronized MAP and ETCO2 that preserves their empirical cross-dependence while allowing controlled dependence manipulations;
2. a separate conditional dynamic model `CBFV = f(history of MAP, history of ETCO2, subject/condition, latent variation)`;
3. explicit freezing and versioning of the simulator;
4. operational definitions of the simulator's local/oracle MAP-to-CBFV and CO2-to-CBFV responses under specified baselines and perturbation amplitudes;
5. systematic comparison of SISO and MISO TFA recovery under controlled duration, noise, correlation, nonstationarity, and nonlinear regime changes;
6. evaluation across both learned and mechanistic simulators to expose simulator-dependent conclusions;
7. a Python research implementation with verified C++ inference parity.

The word **truth** needs qualification. The frozen model gives exact truth about its own input-output mapping, not guaranteed truth about human physiology. Recommended terminology is **known simulator truth**, **oracle response of the frozen simulator**, or **model-defined reference**. The gap between this reference and physiology must be quantified with held-out subjects, external datasets, baseline models, uncertainty intervals, and failure-case testing.

## Recommended first implementation

Start with a deliberately simple hierarchy before a large generative model:

1. Preserve the current known linear simulation as a unit-test oracle.
2. Reproduce a two-input linear finite-impulse-response baseline in Python.
3. Fit a nonlinear conditional sequence model using real paired MAP/ETCO2 histories to predict CBFV; compare a small temporal convolutional network or GRU against the linear baseline and, if feasible, an LVN/PDM baseline.
4. Split by subject, never by random overlapping windows, to prevent leakage.
5. Build a separate joint MAP–ETCO2 generator only after the conditional CBFV model passes held-out spectral, temporal, and physiological checks. The generator must reproduce marginal spectra, MAP–CO2 cross-spectrum/coherence, plausible ranges, and subject/condition variability.
6. Freeze a version and calculate local responses by perturbing one input while holding the other input trajectory and model state under a precisely documented protocol. For a nonlinear system, there is generally no single global transfer function; the response depends on operating point and perturbation size.
7. Run the existing SISO/MISO analysis against pristine and degraded observations, then repeat against more than one simulator family.
8. Export the final conditional model to ONNX and validate Python-versus-C++ output tolerances on fixed test vectors.

This plan uses prior work where it is strongest, avoids rebranding an established mapping as novel, and preserves a clear thesis contribution centered on estimator validation.

## Scope of this search

This was a targeted landscape review of original MAP/ABP–ETCO2–CBFV nonlinear modeling studies, current cerebral-hemodynamic digital twins, reusable code/toolboxes, public datasets, and official Python/PyTorch/ONNX deployment documentation. It is not a patent search or a PRISMA systematic review. The novelty statement should therefore be written as “to our knowledge” until a formal database search with documented inclusion criteria is completed.
