function psdResults = runSISO(bp, co2, cbf, fs)
% runPSDPipeline
%
% SISO PSD / cross-spectral transfer function pipeline.
%
% This pipeline estimates two separate single-input transfer functions:
%
%   H_BP_CBF(f)  = S_BP_CBF(f)  / S_BP_BP(f)
%   H_CO2_CBF(f) = S_CO2_CBF(f) / S_CO2_CO2(f)
%
% These are SISO estimates, meaning:
%   - BP -> CBF is estimated while ignoring CO2.
%   - CO2 -> CBF is estimated while ignoring BP.
%
% This is useful for comparison against the MISO pipeline.
%
% Important:
%   SISO does not account for BP-CO2 coupling.
%   MISO does account for BP-CO2 coupling through the input spectral matrix.

%% Make sure all signals are column vectors

bp  = reshape(bp,  [], 1);
co2 = reshape(co2, [], 1);
cbf = reshape(cbf, [], 1);

%% Remove mean values

% This removes the DC component.
% It is not the same thing as aggressive detrending.
bp  = bp  - mean(bp,  'omitnan');
co2 = co2 - mean(co2, 'omitnan');
cbf = cbf - mean(cbf, 'omitnan');

%% Welch / spectral settings

% Match these to your MISO TFA pipeline.
windowLength_seconds = 128;
windowLength_samples = round(windowLength_seconds * fs);

window = hann(windowLength_samples);
noverlap = round(windowLength_samples / 2);
nfft = windowLength_samples;

frequencyResolution = fs / nfft;

% Frequency range used for plotting/reporting.
% This matches the current MISO-style range.
f_min = 0.0078125;
f_max = 0.5078125;

if length(bp) < windowLength_samples
    error('Signal is shorter than the Welch window. Use a longer signal or reduce windowLength_seconds.');
end

%% Auto-spectra / PSDs

[BP_Sxx, f]    = pwelch(bp,  window, noverlap, nfft, fs);
[CO2_Sxx, ~]   = pwelch(co2, window, noverlap, nfft, fs);
[CBF_Syy, ~]   = pwelch(cbf, window, noverlap, nfft, fs);

%% Cross-spectra

[BP_CBF_Sxy, ~]  = cpsd(bp,  cbf, window, noverlap, nfft, fs);
[CO2_CBF_Sxy, ~] = cpsd(co2, cbf, window, noverlap, nfft, fs);

%% SISO transfer functions

% H = Sxy / Sxx
H_BP_CBF_PSD  = BP_CBF_Sxy  ./ BP_Sxx;
H_CO2_CBF_PSD = CO2_CBF_Sxy ./ CO2_Sxx;

%% Pairwise coherence

% Coherence tells us whether each input-output relationship is reliable.
BP_CBF_coherence = abs(BP_CBF_Sxy).^2 ./ (BP_Sxx .* CBF_Syy);
CO2_CBF_coherence = abs(CO2_CBF_Sxy).^2 ./ (CO2_Sxx .* CBF_Syy);

% Avoid impossible numerical values caused by tiny numerical errors.
BP_CBF_coherence(BP_CBF_coherence > 1) = 1;
CO2_CBF_coherence(CO2_CBF_coherence > 1) = 1;

BP_CBF_coherence(BP_CBF_coherence < 0) = 0;
CO2_CBF_coherence(CO2_CBF_coherence < 0) = 0;

%% Restrict frequency range

freqMask = f >= f_min & f <= f_max;

f_out = f(freqMask);

BP_Sxx_out = BP_Sxx(freqMask);
CO2_Sxx_out = CO2_Sxx(freqMask);
CBF_Syy_out = CBF_Syy(freqMask);

BP_CBF_Sxy_out = BP_CBF_Sxy(freqMask);
CO2_CBF_Sxy_out = CO2_CBF_Sxy(freqMask);

H_BP_CBF_PSD_out = H_BP_CBF_PSD(freqMask);
H_CO2_CBF_PSD_out = H_CO2_CBF_PSD(freqMask);

BP_CBF_coherence_out = BP_CBF_coherence(freqMask);
CO2_CBF_coherence_out = CO2_CBF_coherence(freqMask);

%% Reliability-based plotting masks

% Same basic coherence threshold idea as your MISO pipeline.
% Later, this can be replaced by a CARNet-style threshold based on
% the number of Welch windows.
coherenceThreshold = 0.51;

% Plotting power thresholds.
% These are stricter than numerical thresholds.
% They decide what is meaningful enough to display.
plotPowerThreshold_BP  = 1e-3 * max(BP_Sxx_out);
plotPowerThreshold_CO2 = 1e-3 * max(CO2_Sxx_out);
plotPowerThreshold_CBF = 1e-3 * max(CBF_Syy_out);

strongBPpower  = BP_Sxx_out  >= plotPowerThreshold_BP;
strongCO2power = CO2_Sxx_out >= plotPowerThreshold_CO2;
strongCBFpower = CBF_Syy_out >= plotPowerThreshold_CBF;

% Make plotting copies.
% Raw transfer functions remain stored separately.
H_BP_CBF_PSD_plot  = H_BP_CBF_PSD_out;
H_CO2_CBF_PSD_plot = H_CO2_CBF_PSD_out;

% BP SISO plotting mask:
% Show BP->CBF only where BP has power, CBF has power,
% and BP-CBF coherence is high enough.
validBP_SISOplot = ...
    strongBPpower & ...
    strongCBFpower & ...
    BP_CBF_coherence_out >= coherenceThreshold;

% CO2 SISO plotting mask:
% Show CO2->CBF only where CO2 has power, CBF has power,
% and CO2-CBF coherence is high enough.
validCO2_SISOplot = ...
    strongCO2power & ...
    strongCBFpower & ...
    CO2_CBF_coherence_out >= coherenceThreshold;

% Hide unreliable points in plotting copies.
H_BP_CBF_PSD_plot(~validBP_SISOplot) = NaN;
H_CO2_CBF_PSD_plot(~validCO2_SISOplot) = NaN;

%% Gain and phase

gain_BP_CBF_PSD = abs(H_BP_CBF_PSD_out);
gain_CO2_CBF_PSD = abs(H_CO2_CBF_PSD_out);

phase_BP_CBF_PSD = angle(H_BP_CBF_PSD_out);
phase_CO2_CBF_PSD = angle(H_CO2_CBF_PSD_out);

gain_BP_CBF_PSD_plot = abs(H_BP_CBF_PSD_plot);
gain_CO2_CBF_PSD_plot = abs(H_CO2_CBF_PSD_plot);

phase_BP_CBF_PSD_plot = angle(H_BP_CBF_PSD_plot);
phase_CO2_CBF_PSD_plot = angle(H_CO2_CBF_PSD_plot);

%% Plot SISO transfer functions

figure()
plotComplexMagnitudePhase(H_BP_CBF_PSD_plot, f_out, ...
    'SISO PSD H: BP to CBF');

figure()
plotComplexMagnitudePhase(H_CO2_CBF_PSD_plot, f_out, ...
    'SISO PSD H: CO2 to CBF');

%% Store results

psdResults.f = f_out;
psdResults.freqMask = freqMask;
psdResults.frequencyResolution = frequencyResolution;

psdResults.windowLength_seconds = windowLength_seconds;
psdResults.windowLength_samples = windowLength_samples;
psdResults.noverlap = noverlap;
psdResults.nfft = nfft;

psdResults.f_min = f_min;
psdResults.f_max = f_max;

psdResults.BP_Sxx = BP_Sxx_out;
psdResults.CO2_Sxx = CO2_Sxx_out;
psdResults.CBF_Syy = CBF_Syy_out;

psdResults.BP_CBF_Sxy = BP_CBF_Sxy_out;
psdResults.CO2_CBF_Sxy = CO2_CBF_Sxy_out;

psdResults.H_BP_CBF_PSD = H_BP_CBF_PSD_out;
psdResults.H_CO2_CBF_PSD = H_CO2_CBF_PSD_out;

psdResults.H_BP_CBF_PSD_plot = H_BP_CBF_PSD_plot;
psdResults.H_CO2_CBF_PSD_plot = H_CO2_CBF_PSD_plot;

psdResults.gain_BP_CBF_PSD = gain_BP_CBF_PSD;
psdResults.gain_CO2_CBF_PSD = gain_CO2_CBF_PSD;

psdResults.phase_BP_CBF_PSD = phase_BP_CBF_PSD;
psdResults.phase_CO2_CBF_PSD = phase_CO2_CBF_PSD;

psdResults.gain_BP_CBF_PSD_plot = gain_BP_CBF_PSD_plot;
psdResults.gain_CO2_CBF_PSD_plot = gain_CO2_CBF_PSD_plot;

psdResults.phase_BP_CBF_PSD_plot = phase_BP_CBF_PSD_plot;
psdResults.phase_CO2_CBF_PSD_plot = phase_CO2_CBF_PSD_plot;

psdResults.BP_CBF_coherence = BP_CBF_coherence_out;
psdResults.CO2_CBF_coherence = CO2_CBF_coherence_out;

psdResults.coherenceThreshold = coherenceThreshold;

psdResults.plotPowerThreshold_BP = plotPowerThreshold_BP;
psdResults.plotPowerThreshold_CO2 = plotPowerThreshold_CO2;
psdResults.plotPowerThreshold_CBF = plotPowerThreshold_CBF;

psdResults.strongBPpower = strongBPpower;
psdResults.strongCO2power = strongCO2power;
psdResults.strongCBFpower = strongCBFpower;

psdResults.validBP_SISOplot = validBP_SISOplot;
psdResults.validCO2_SISOplot = validCO2_SISOplot;

end