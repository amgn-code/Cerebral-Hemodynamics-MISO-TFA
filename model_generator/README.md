# Model generator

Status: deferred Step 2 research option, 13 September 2026. No model has been trained or installed by this proposal. The current priority is the [known-truth simulation protocol](../docs/known_truth_protocol/SIMULATION_PROTOCOL.md); learned generation is not needed for that study.

This module will learn representative MAP–PETCO2 input patterns and paired transfer-function variation from recordings, then generate reproducible synthetic recordings for MISO/SISO evaluation. Training and generation will run in MATLAB. The existing simulation remains the reference benchmark while this module is developed.

The three requirements are **reproducibility, understandability, and validity**.

In plain terms: learn what paired input recordings look like; learn what paired response curves look like; draw a new example of each; pass the inputs through those saved responses to make CBFV. Because we saved the responses we used, we can check how closely SISO and MISO recover them. Real data inform plausible examples; the simulator supplies exact, inspectable truth.

## Start here

- [Development proposal](DEVELOPMENT_PROPOSAL.md): scientific decisions, model candidates, user controls, module contracts, development stages, and acceptance criteria.
- [Python project review and research](RESEARCH_AND_PRIOR_WORK.md): what was actually implemented previously, relevant findings, primary sources, and practical MATLAB requirements.

## Intended workflow

```text
Recorded MAP, PETCO2, CBFV + verified timing and units
                       |
             Quality check and participant splits
                       |
          +------------+----------------------+
          |                                   |
  Paired input model                  Transfer-function library
  Learn MAP/CO2 spectra,               Compute MISO and both SISO;
  amplitudes, dependence,              evaluate compact fitted models;
  and recording variation             retain provenance and uncertainty
          |                                   |
  Generate new paired inputs          Learn/generate paired pathway models
          |                                   |
          +----------------+------------------+
                           |
             Apply known generating pathways
             Add separately specified disturbance/noise
                           |
                  Synthetic MAP, CO2, CBFV
                           |
             Run the existing MISO/SISO analysis
             Compare with exact simulator truth
```

MISO and SISO differences are **not a permanent roadblock**. SISO describes an input's pairwise relationship with the combined output; MISO describes pathways conditional on the other input. Their estimates must remain distinctly labeled. We cannot pool all of these curves as interchangeable physical pathways or sum two separately fitted SISO output predictions and call the result the same joint system.

## What is learned and what remains specified

| Item | Source |
|---|---|
| Input spectra, amplitudes, coherence, supported input phase, diversity | Learned from quality-controlled recordings |
| Candidate paired pathway shapes | Estimated from recordings, with method labels and uncertainty |
| Distribution of new pathway pairs | Learned from the accepted pathway library; simple baseline before neural generation |
| Exact truth for a synthetic recording | The saved filters actually used to generate its output |
| Controlled noise, timing errors, extrapolation, and stress conditions | Explicit experiment settings |
| Claim of physiological truth | Not established merely by fitting or generating plausible curves |

## Initial implementation milestone

Audit timing and data paths; reproduce the current spectral estimator against MATLAB's built-in; establish a MATLAB paired-input baseline and a provenance-rich transfer-function library. These are the prerequisites for generative training, not a substitute for it.

The earlier Python project is at `/Users/amoghn/Multiple Input TFA`. Its audited input generator is a linear paired autoregression. The known NC source folder is `/Users/amoghn/Desktop/ieem_data/NC` (23 workbooks at review time). Neither path will become a required hardcoded dependency of the module.

MATLAB attachment failed during this review. The source and saved Python results were inspected, but no fresh MATLAB fit, runtime comparison, or license check was completed.
