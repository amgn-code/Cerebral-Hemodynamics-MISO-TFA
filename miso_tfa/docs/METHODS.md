# Simulation and analysis methods

## Question and target

Under which conditions does MISO recover known MAP→CBFV and CO₂→CBFV responses more accurately than separate SISO models? The targets are the conditional generating pathways. SISO estimates pairwise relationships that may include an omitted-input contribution.

This is a controlled linear, time-invariant methods experiment. Repeated random recordings quantify finite-record variability. They do not establish physiological parameter distributions or the prevalence of conditions in a patient population.

## Generating a recording

1. Set a saved seed and generate independent standard normal sequences: shared source A and CO₂-specific source B.
2. Take their FFTs. In the default NC-derived mode, both input power shapes are `P(f) = 1/(1+(f/0.0290)^2.5514) + 0.01`. Multiply frequency amplitudes by `sqrt(P(f))`, because power is squared amplitude. This gives fresh random waveforms an intended average spectral shape.
3. Construct the CO₂ source as `sqrt(c)*delayed(A) + sqrt(1-c)*B`, where `c` is assigned magnitude-squared coherence. Input lag applies `exp(-i*2*pi*f*lag)` using signed FFT frequencies. This supports fractional-sample lags; the Nyquist component is projected to a real value during reconstruction.
4. Inverse FFT to real time series. Center and standardize the sequences; set MAP SD and the CO₂/MAP SD ratio. Amplitudes are defined on the master recording. A retained segment may have slightly different SD. Finite-record coherence fluctuates around its assigned value.
5. Build known kernels. MAP combines an immediate response with an exponential component that attenuates slow changes. CO₂ has a delayed exponential low-pass response. Scale it to the assigned ratio of band RMS transfer-function gain.
6. Filter each clean input and add its CBFV contribution. Discard burn-in. There is no nonlinear interaction term.
7. Select the recording prefix. Add input recording noise and output noise, then measurement misalignment. Input noise affects the observations after clean CBFV has been generated.
8. Analyze the observed signals using shared spectra and compare estimates with known responses in matching output units.

Master duration fixes the FFT grid across conditions. Repetition `r` uses seed `randomSeed + 2*(r-1)` in every condition, holding random sources fixed for controlled comparisons. Increasing repetitions preserves the previous prefix. Generation and bootstrapping restore the caller's RNG.

Signal-shaped output noise retains the clean CBFV amplitude spectrum and uses phases from an independent Gaussian source. White output noise is also an explicit option. Noise is centered and scaled to:

```text
noise power = clean signal power / 10^(SNRdB/10)
```

This is full-record time-domain SNR, not a guaranteed value at every frequency. Holding SNR fixed across pathway conditions can change absolute noise power.

## Origin of the input shape

Original characterization used 23 resting NC recordings and 90-second windows. At each frequency, participant median power was calculated separately for MAP and CO₂. Those curves were averaged in decibels and fitted over 0.033–0.35 Hz with a monotonic curve plus a dB offset. Only shape parameters were retained; the physical amplitude offset was discarded.

The common shape holds input frequency distributions equal while other conditions vary. It is a simplification, not evidence that human MAP and CO₂ spectra are identical. Evaluation outside the fitting interval is an extrapolation. The 0.01 power floor remains from the existing generator.

The older `"gaussian"` spectrum option permits a spectral-similarity sweep by moving CO₂'s spectral center relative to MAP. It is not a newly fitted physiological model. Such a sweep is rejected in `"ncMonotonic"` mode because the common shape would make that control ineffective.

## Conditions and pathway strength

`co2FluctuationRatio` sets CO₂ input SD divided by MAP input SD. `co2GainRatio` sets:

```text
RMS(|H_CO2(f)| over calibrationBandHz)
------------------------------------
RMS(|H_MAP(f)| over calibrationBandHz)
```

A large input can drive substantial CBFV variation through a weak pathway; a strong pathway can amplify a small input. The gain ratio uses the configured simulation scales, not a clinical normal reference.

The generator records CO₂ contribution power divided by the sum of separate MAP and CO₂ contribution powers. This is not a fraction of total CBFV variance: correlated contributions add covariance, and observed CBFV also contains noise.

Reference values and ranges are explicit experimental choices. Coherence 0.15 is informed by NC characterization (bias-corrected band-mean percentiles approximately 0.065, 0.129, and 0.177). Zero is an independent-input control; 0.50 and 0.95 test stronger dependence. Input-lag levels −6, 0, and 4 seconds were informed by approximate NC phase-lag fits. These are not established population limits.

The response shapes are physiologically motivated approximations. Their 3-second MAP time constant, 5-second CO₂ time constant, 3-second CO₂ delay, gain levels, amplitude-ratio bounds, durations, and noise levels are stated model or engineering conditions. The cited papers do not validate all exact numbers. The current reference coherence is NC-informed; the older paper's reference slices used 0.50. Every held setting is saved.

One-at-a-time results are conditional on the reference and do not rule out interactions. Factorial mode crosses selected ranges without pooling them; default figures remain reference slices. All combinations are exported for inspection and interaction analysis.

## Imported data and shared analysis

The import route retains CO₂ startup cleanup, bounded-gap linear resampling, and explicit delay correction. Startup cleanup removes leading zeros and unusually large initial transitions, using the visible limit and threshold fraction. General artifact repair is outside the input contract.

Positive `co2DelayCorrectionSeconds` advances recorded CO₂ by cropping unmatched edges. Simulation `alignmentErrorSeconds` uses the same sign; its net observed shift includes analysis correction. Neither is the true physiological CO₂ pathway delay. These observation shifts and the generating kernel's delay are rounded to the nearest sample; the FFT input lag supports fractional samples.

Real-data CBFV normalization is `100*CBFV/mean(CBFV)`. Simulation normalization is `100*CBFV/cbvNormalizationReference`. Simulation amplitudes are arbitrary units; a reference of 100 preserves original gains without calibrating absolute human CBFV. Truth kernels receive the same scale.

Whole-record detrending and mean removal apply in both modes. Welch uses linearly detrended segments, a Hann window, configured overlap, and optional smoothing of auto- and complex cross-spectra. The default 100-second window at 4 Hz has 0.01-Hz FFT spacing. The configured minimum window count is required.

At each frequency:

```text
SISO MAP response = S_MAP,CBFV / S_MAP,MAP
SISO CO2 response = S_CO2,CBFV / S_CO2,CO2

[ S_MAP,MAP   S_MAP,CO2 ] [ H_MAP ] = [ S_MAP,CBFV ]
[ S_CO2,MAP   S_CO2,CO2 ] [ H_CO2 ]   [ S_CO2,CBFV ]
```

The convention is `Sxy = conj(X).*Y`. MISO retains the unregularized solve. Singular systems produce unidentified/NaN estimates, rather than a substituted regularized fit. Normalized matrix condition number is saved.

Ordinary coherence is pairwise. Partial coherence conditions on the other input. Multiple coherence describes the joint system; input coherence describes MAP–CO₂ dependence. Higher multiple coherence does not establish more accurate individual responses.

## Errors, advantage, and differences

At each retained frequency:

```text
gain error    = abs(abs(estimated H) - abs(true H))
phase error   = abs(angle(estimated H * conj(true H)))
complex error = abs(estimated H - true H)^2 / mean_band(abs(true H)^2)
```

Phase is excluded where true gain falls below the configured fraction of band RMS gain or the numerical floor. A zero true or estimated response has no defined phase. For an entirely zero pathway, complex error uses absolute squared error without a zero normalization denominator.

```text
advantage = log10(mean paired SISO error / mean paired MISO error)
```

Positive favors MISO; negative favors SISO. One unit means a tenfold error ratio. This is a ratio of means, not a mean of individual log ratios. Both means use the same finite pairs; paired and invalid counts are exported. Undefined rows are grey. No artificial epsilon changes zero errors. Infinite advantages saturate only for display.

The paired bootstrap estimates Monte Carlo SE and percentile intervals by resampling repetitions. It measures finite-run uncertainty conditional on the generator, not uncertainty in physiological assumptions. The finite fraction of bootstrap results is exported. If any bootstrap advantages are nonfinite, SE and interval are left undefined rather than dropping an infinite tail.

Real-data differences are MISO-minus-SISO gain and shortest angular phase differences. They describe changed estimates, not known accuracy. Agreement with a simulation trend supports an assumption-dependent interpretation, not proof of a more accurate human pathway estimate.

## Groups and impulse responses

Gain and coherence use arithmetic means. Phase uses circular means and circular SD, `sqrt(-2*log(abs(mean(exp(i*phase)))))`. SD requires at least two valid recordings. Complex mean TF is stored separately from mean gain and circular mean phase.

Impulse responses retain the original uniform DC-to-Nyquist grid. Frequencies outside the reporting band are zeroed; negative frequencies are restored by conjugate symmetry; IFFT is multiplied by sampling rate. The result has gain units per second. Truth receives the identical restriction.

This is a band-limited periodic inverse, with period equal to the Welch window. Removing DC makes its integral zero. Band restriction introduces ringing and negative lags even for a causal true kernel; those features do not demonstrate noncausal physiology. The explanatory figure also shows unrestricted generating kernels.

## Evidence and implementation history

- [Morris, White, and Crowther (2019)](https://doi.org/10.1002/sim.8086): ADEMP planning/reporting and Monte Carlo uncertainty. Already cited in the original paper; no runtime framework is added.
- [Panerai et al. (2000)](https://doi.org/10.1109/10.827312) and [Peng et al. (2008)](https://doi.org/10.1007/s10439-007-9412-9): multivariate cerebral-hemodynamic analysis and relevant pathways.
- [CARNet white paper update](https://doi.org/10.1177/0271678X221119760): dCA/TFA interpretation and reporting context.
- [Sanders et al. (2018)](https://doi.org/10.1088/1361-6579/aae9fd): known-truth precedent. Its recorded-pressure protocol does not replace this synthetic two-input generator.
- [Wilson et al. (2017)](https://doi.org/10.1371/journal.pcbi.1005510): readable and reproducible scientific-computing practices.

Input generation, response rules, Welch calculations, and estimator equations are retained. Duplicate interfaces/presets, the separate prediction study, and old report/manuscript builders are removed. Earlier code and writing remain in the saved baseline branch.

Two editable-parameter edge cases were corrected: the CO₂/MAP SD ratio when MAP SD changes, and fractional-sample lags. Default generated signals were verified identical to the original; estimator outputs matched the saved baseline within 1e-12.
