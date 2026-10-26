# Physiological time-series inputs for predicting cerebral blood-flow velocity

Research memo — 20 September 2026

## 1. Working thesis direction

The proposed direction is a multimodal, time-series model that predicts cerebral blood-flow velocity (CBFV; more precisely, cerebral blood velocity, CBv) from simultaneously measured physiological signals. The current project already has a strong starting point: beat-to-beat/low-frequency mean arterial pressure (MAP), end-tidal CO2 (PETCO2), and CBFV, analyzed in the 0.02–0.35 Hz physiological band.

The literature supports expanding the input set, but it also gives an important constraint: CBFV is not determined by one undifferentiated collection of “physiological variables.” It is the observable result of several coupled subsystems:

1. perfusion pressure and intracranial pressure;
2. arterial blood gases and ventilation;
3. cardiac output and autonomic regulation;
4. cerebral oxygenation and microvascular blood volume;
5. neural/metabolic demand;
6. posture, movement, experimental state, and treatment.

The thesis should therefore test *incremental physiological information* using nested input blocks and subject-held-out validation, rather than simply maximizing the number of channels.

## 2. Highest-priority candidate inputs

| Priority | Signal or derived series | Physiological role | Recommendation for the thesis |
|---|---|---|---|
| A | Continuous arterial pressure waveform; MAP, SBP, DBP, pulse pressure | Main systemic perfusion-pressure driver of CBFV and dynamic autoregulation | Required core input; retain the raw waveform if available, then derive beat-level variables |
| A | PETCO2/EtCO2; ideally PaCO2 or a calibrated arterial surrogate | Potent cerebrovascular vasodilator; explains CBFV changes not attributable to pressure | Required core input; explicitly estimate and validate the capnography-to-cerebral delay |
| A | ECG; heart rate and beat-to-beat/RR interval | Cardiac rhythm and autonomic modulation; demonstrated incremental predictive value beyond pressure and CO2 | Required if available; include both beat timing and HR-derived features |
| A | Respiration waveform; respiratory rate, tidal volume, minute ventilation, inspiratory/expiratory timing | Drives CO2 fluctuations and produces cardiorespiratory oscillations that can appear in CBFV | Required companion to PETCO2 whenever available; do not use respiratory rate as a replacement for PETCO2 |
| B | Stroke volume, cardiac output, cardiac index, or aortic outflow waveform | Central flow can influence cerebral flow independently of MAP in some settings | High-value secondary block; especially important during exercise, lower-body negative pressure, orthostasis, or cardiac disease |
| B | SpO2/SaO2; inspired O2 fraction; PETO2/PaO2 | Hypoxic vasodilation and oxygen-delivery effects; relevant during hypoxia, apnea, sleep-disordered breathing, or oxygen manipulation | Include when the protocol contains hypoxia/apnea/exercise; lower priority in stable normoxia |
| B | Cerebral NIRS: HbO2, HbR, total Hb, tissue oxygenation index/rSO2 | Microvascular oxygenation and blood-volume state; complementary to conduit-artery TCD | Strong secondary/auxiliary modality; useful for multi-task prediction or testing macro–microvascular coupling |
| B | Posture/head angle/head elevation; body-position or tilt-table signal | Changes hydrostatic pressure, venous/ICP conditions, and autonomic state | Include as a time-varying state variable, not merely as a participant label |
| C | Intracranial pressure (ICP); derived CPP = MAP at brain level − ICP | Directly changes cerebral perfusion pressure; essential in neurocritical-care recordings | Conditional but important for TBI, hydrocephalus, neurosurgery, or elevated ICP data; not expected in healthy resting studies |
| C | EEG or task-related neural activity; band powers, event markers, stimulus intensity | Captures neural demand and neurovascular coupling that pressure/CO2 cannot explain | Include for cognitive, visual, motor, or sensory paradigms; avoid treating EEG as a universal resting-state input without a clear hypothesis |
| C | Accelerometer/gyroscope, EMG, gait/force, exercise workload | Motion, muscle activity, exertion, and movement-induced autonomic changes | Include to identify motion and exertion states; often more useful as confounder/control channels than as direct causal inputs |
| C | PPG/BVP waveform and pulse-transit/pulse-arrival features | Noninvasive peripheral pulse and vascular timing; can provide cardiac and oxygenation information when ECG/ABP are unavailable | Worth testing as a low-cost input block; the literature includes an ANN CBFV-estimation example using PPG + SpO2 |
| D | Hematocrit, hemoglobin, blood viscosity proxies | Changes oxygen content and rheology; mainly explains between-subject/baseline differences | Treat as static or slowly varying subject covariates, not as high-frequency predictors |
| D | Glucose, HbA1c, lactate, pH, electrolytes, inflammatory/endothelial markers | Metabolic/vascular state; biologically relevant but usually measured intermittently | Use for stratification, calibration, or slow-state modeling when available; unlikely to contribute to a 0.02–0.35 Hz short-window model |
| D | Medication/vasopressor/sedative/caffeine/oxygen or CO2 dose | Changes vascular tone and systemic state; may create nonstationary regimes | Encode as time-varying dose or intervention/event channels and include in protocol metadata |
| D | Age, sex, BMI, vessel side/artery, insonation depth, vessel diameter, time of day, temperature | Explains baseline and subject-specific response differences | Use as static covariates and stratification variables; never let them substitute for missing continuous physiology |

## 3. Evidence for the major input blocks

### Pressure, CO2, and heart rate are the established dynamic core

The strongest precedent is multivariate cerebral-hemodynamic modeling. Panerai et al. used beat-to-beat MAP and breath-to-breath EtCO2 as concurrent inputs and found that adding EtCO2 significantly reduced CBFV reconstruction error relative to pressure alone. Marmarelis et al. extended the model with heart rate as a third input in 18 controls; adding HR significantly reduced prediction error beyond ABP and EtCO2, and the paper discusses plausible sympathetic and parasympathetic contributions.

These studies directly support the current thesis extension from two inputs to a structured three- or four-block model:

`ABP/MAP + PETCO2 + HR/RR + respiration -> CBFV`

The CO2/O2 literature provides another important extension. Peng and colleagues studied ABP together with breath-to-breath PETCO2 and PETO2; the additional gas inputs increased low-frequency multiple coherence and changed the interpretation of the ABP-to-CBFV transfer function. This makes PETO2 a scientifically justified conditional input, especially in hypoxia, exercise, apnea, or oxygen-manipulation protocols.

### Cardiac output and stroke volume are plausible but context-dependent

Human experiments have measured MAP, TCD velocity, beat-to-beat cardiac output/stroke volume, EtCO2, and ECG simultaneously during pressure or lower-body-negative-pressure challenges. These studies show that cardiac output can be associated with cerebral velocity, but the contribution is not necessarily independent of MAP, posture, or CO2. Therefore, cardiac output should be tested as an incremental block rather than assumed to be a universally dominant input.

This distinction is useful for the thesis: HR is cheap and continuously available; stroke volume/CO is more informative mechanistically but harder to obtain and often less temporally reliable. A nested comparison can test whether `HR` captures most of the available cardiac information or whether `SV/CO` adds independent predictive value.

### Oxygenation and NIRS provide a complementary cerebral state

Concurrent TCD–NIRS studies have measured CBFV, BP, EtCO2, and oxygenated/deoxygenated hemoglobin. CO2-induced CBFV changes were associated with changes in oxygenated hemoglobin, and other work has recorded NIRS-derived cerebral oxygen saturation alongside MAP, cardiac output, HR, ETCO2, and TCD during lower-body-negative-pressure challenges.

NIRS should be viewed in two ways:

* as an input block that may improve CBFV prediction by reporting microvascular oxygenation/blood-volume state;
* as an auxiliary output that lets the thesis test whether the model is learning a coherent macrovascular–microvascular response rather than merely exploiting correlations with CBFV.

NIRS is also vulnerable to superficial blood-flow and motion contamination. Short-window signal quality, optode contact, and extracranial physiology must therefore be recorded or estimated.

### Neural activity is relevant when the experiment contains activation

Simultaneous EEG and TCD experiments have shown task-related EEG changes and contralateral MCA velocity increases during motor activation. A more recent multimodal EEG–fNIRS–TCD protocol also synchronized EEG, fNIRS, TCD, BP, capnography, and HR during motor and visual tasks.

This supports EEG-derived time series for a neurovascular-coupling branch of the thesis, but not necessarily for a resting autoregulation model. The signal should be represented as causal, windowed neural features—e.g., band-limited power, event-related desynchronization, or task/stimulus markers—with a physiologically plausible lag to CBFV.

### Posture, movement, and autonomic state are not nuisance-only variables

Studies of posture, tilt, sit-to-stand, head position, and orthostatic challenge repeatedly measure CBFV together with BP, CO2, HR, respiration, oxygen saturation, and sometimes NIRS. These experiments show that the same nominal ABP–CBFV relationship can occur under different hydrostatic and autonomic states. A posture or movement channel is therefore useful both as a direct input and as a regime label for evaluating model stability.

The open PhysioNet Cerebral Vasoregulation in Elderly with Stroke dataset is particularly relevant to this direction. It contains TCD, high-resolution ECG/BP/CO2/respiration recordings during movement tasks, 24-hour BP/ECG, EMG, accelerometry, and gait-pressure recordings. A separate PhysioNet type-2-diabetes dataset contains ACA/MCA TCD, cardiovascular and respiratory signals during hyperventilation, CO2 rebreathing, Valsalva, head-up tilt, and sit-to-stand, plus MRI, laboratory, cognitive, and gait variables.

### ICP and CPP define a different, clinical version of the problem

For patients with elevated ICP, MAP alone is an incomplete pressure input. The physiologically relevant driving pressure is closer to CPP, with hydrostatic correction when ABP and ICP transducers are at different levels. The PhysioNet pediatric neurocritical-care dataset contains time-aligned ABP, ICP, CBFV, hematocrit, and transducer heights at 125 Hz, making it a useful external dataset for a clinical branch of the thesis.

This should not be mixed blindly with healthy resting data. A sensible design is to treat `ICP/CPP` as a conditional clinical block and to report performance separately for healthy, stroke, and neurocritical-care regimes.

### PPG and SpO2 have direct machine-learning precedent

An ANN study estimated the temporal CBFV waveform during breath-hold challenges from pulse-oximeter SpO2 and PPG. The authors reported acceptable within-protocol performance but emphasized the need for larger and more diverse datasets and features for generalization. This is not sufficient evidence that PPG + SpO2 can replace ABP + CO2 in general, but it is strong evidence that a low-cost physiological-signal branch is worth benchmarking.

## 4. Recommended thesis input hierarchy

### Tier 1 — acquire whenever possible

* continuous ABP waveform and beat-level MAP/SBP/DBP/pulse pressure;
* PETCO2/EtCO2 and the underlying capnogram;
* ECG with R-peak timestamps, HR, and RR intervals;
* respiratory waveform or at least respiratory rate plus tidal-volume/flow information;
* CBFV waveform with a signal-quality indicator, artery, side, insonation depth, and probe-lock status.

This is the minimum scientifically coherent model for spontaneous dynamic CBFV prediction.

### Tier 2 — high-value expansion

* stroke volume/cardiac output;
* SpO2/SaO2 and inspired oxygen fraction;
* NIRS HbO2, HbR, total Hb, and tissue oxygenation index/rSO2;
* posture/head angle/head elevation;
* motion/exertion markers.

These variables are likely to produce the largest improvement after the core because they represent central flow, oxygenation, microvascular state, and hydrostatic/autonomic regime.

### Tier 3 — protocol- or population-specific

* ICP and CPP;
* EEG and stimulus/task markers;
* EMG, force, gait, or workload;
* PETO2/PaO2/FiO2;
* PPG/BVP and pulse-arrival-time features;
* medication, vasoactive-drug, caffeine, and gas-mixture channels.

These should be added when the recording protocol creates the corresponding physiological perturbation or when the clinical population makes the signal relevant.

### Tier 4 — context and slow covariates

* age, sex, BMI, baseline BP, baseline CBFV, artery and hemisphere;
* hematocrit/hemoglobin;
* glucose/HbA1c and relevant laboratory markers;
* disease status, medications, sleep state, time of day, temperature, and caffeine/exercise history.

These variables should condition or calibrate the dynamic model. They should not be treated as if they were high-frequency causal inputs.

## 5. Modeling implications for the machine-learning study

### Use nested ablations, not one giant model

The most interpretable sequence is:

1. autoregressive CBFV-only baseline;
2. MAP/ABP;
3. MAP + PETCO2;
4. + HR/RR + respiration;
5. + SV/CO;
6. + SpO2/PETO2;
7. + NIRS;
8. + posture/motion;
9. conditional branches with ICP/CPP, EEG, or task markers.

Report the change in held-out error, calibration, and stability for each block. A small improvement from a difficult-to-measure signal may not justify its acquisition burden.

### Preserve causality and availability

For each proposed predictor, define whether it would be available at inference time. For example, future CBFV, future NIRS, or a lab value collected after the prediction window must not enter an online model. Other cerebral signals can be used as auxiliary outputs or as a separate offline model, but should not be called causal inputs unless the deployment scenario actually has them available.

### Align delays explicitly

The signals do not share the same physical delay. Capnography has sampling-line and breath-to-brain delay; NIRS and CBFV have different vascular transit and measurement dynamics; ECG-derived beat timing is effectively event-based. Keep raw timestamps, estimate or measure channel delay, and include a documented lag-search or causal convolution stage. The CARNet literature emphasizes synchronization and recommends beat-level representation for dynamic autoregulation work.

### Keep a high-rate and a low-rate representation

For raw ABP and CBFV acquisition, CARNet guidance recommends at least 50 Hz. For beat-averaged MAP and CBv time-domain modeling, later recommendations place the useful resampling range around 1–5 Hz; the current project’s 4 Hz representation is therefore defensible for the slow autoregulatory model. Preserve the original high-rate waveforms for quality control, morphology features, and future clinical/ICP work.

### Evaluate across physiology, not only random windows

Random window splits will overstate performance because adjacent windows from the same person share baseline and measurement characteristics. Use subject-held-out splits, recording-held-out splits, and perturbation-held-out tests. Report results separately for rest, orthostasis, breathing manipulation, exercise/hypoxia, and clinical data.

## 6. Best immediate research plan

The most defensible next study is a **hierarchical multimodal CBFV model** with one primary output and several optional auxiliary outputs:

* Primary output: mean MCA CBFV, with left/right hemispheres treated separately or as a multi-task pair.
* Core input branch: ABP/MAP, PETCO2, ECG-derived HR/RR, respiration.
* Expansion branches: SV/CO, SpO2/PETO2, NIRS, posture/motion.
* Conditional branches: ICP/CPP, EEG/task markers, PPG, medication/intervention state.
* Auxiliary outputs: contralateral CBFV, NIRS oxygenation, or derived autoregulation indices where the data support them.

The central scientific question should be phrased as: **Which physiological signal blocks provide reproducible, subject-generalizable information about CBFV beyond MAP and CO2, and under which physiological regimes?** That question is more precise and testable than simply asking which model predicts CBFV most accurately.

## 7. Sources and candidate datasets

Primary/authoritative sources consulted in this first scan:

1. Panerai et al., *Multivariate dynamic analysis of cerebral blood flow regulation in humans* (MAP + EtCO2; multivariate FIR modeling): [PubMed](https://pubmed.ncbi.nlm.nih.gov/10743786/).
2. Marmarelis et al., *Multiple-input nonlinear modelling of cerebral haemodynamics using spontaneous arterial blood pressure, end-tidal CO2 and heart rate measurements* (ABP + EtCO2 + HR): [PMC full text](https://pmc.ncbi.nlm.nih.gov/articles/PMC4822442/).
3. Peng et al., *Multivariate system identification for cerebral autoregulation* (ABP + PETCO2 + PETO2): [Oxford Research Archive](https://ora.ox.ac.uk/objects/uuid%3A20fad100-eded-4fc7-acbc-decd6625fcbb).
4. Ainslie et al., *Alterations in cerebral autoregulation and cerebral blood flow velocity during acute hypoxia: rest and exercise* (ventilation, end-tidal gases, HR, BP, CO, NIRS, SaO2, TCD): [American Journal of Physiology](https://journals.physiology.org/doi/abs/10.1152/ajpheart.00639.2006).
5. Fanelli et al., *Neurocritical care waveform recordings in pediatric patients* (ABP + ICP + CBFV + Hct): [PhysioNet](https://physionet.org/content/neurocritical-pediatric/1.0.0/).
6. Novak et al., *Cerebral Vasoregulation in Elderly with Stroke* (TCD, ECG, BP, CO2, respiration, EMG, accelerometry, gait pressure): [PhysioNet](https://physionet.org/content/cves/1.0.0/).
7. Novak et al., *Cerebral perfusion and cognitive decline in type 2 diabetes* (ACA/MCA TCD, cardiovascular/respiratory signals, tilt, sit-to-stand, Valsalva, CO2, MRI, labs, gait): [PhysioNet](https://physionet.org/content/cerebral-perfusion-diabetes/1.0.1/data/).
8. Alam et al., *Measurement of neurovascular coupling in human motor cortex using simultaneous TCD and EEG*: [PubMed](https://pubmed.ncbi.nlm.nih.gov/29799813/).
9. Eke et al., *Two-Tiered Response of Cardiorespiratory-Cerebrovascular Network to Orthostatic Challenge* (ABP, cardiac intervals, respiration, TCD, NIRS): [PhysioNet dataset](https://www.physionet.org/content/cardioresp-response-orthostat/1.0/) and [Frontiers article](https://www.frontiersin.org/journals/physiology/articles/10.3389/fphys.2021.622569/full).
10. Al-Abed et al., *Estimation of cerebral blood flow velocity during breath-hold challenge using artificial neural networks* (SpO2 + PPG -> CBFV): [open manuscript](https://www.osti.gov/servlets/purl/1800233).
11. Panerai et al., *Transfer function analysis of dynamic cerebral autoregulation: a CARNet white paper 2022 update* (minimum data assemblage, acquisition, synchronization, and reporting): [Journal article](https://journals.sagepub.com/doi/10.1177/0271678X221119760).
12. Kostoglou et al., *Time-domain methods for quantifying dynamic cerebral blood flow autoregulation* (time-domain modeling and recommended 1–5 Hz beat-level representation): [Journal article](https://journals.sagepub.com/doi/10.1177/0271678X241249276).

This memo is an initial literature scan, not yet a systematic review. The next pass should extract the exact channel names, sampling rates, recording durations, populations, and train/test designs from the most relevant datasets and build a source-to-signal evidence matrix.
