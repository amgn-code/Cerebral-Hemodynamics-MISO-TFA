function tfaResults = runTFA(bp, co2, cbf, fs)
% runTFA
%
% Pipeline:
%   PSD / cross-spectral 2-input transfer function analysis.
%
% Current model:
%
%       CBF(f) = H_BP(f)*BP(f) + H_CO2(f)*CO2(f)
%
% In the real physiological data, this will likely correspond to:
%
%       CBv(f) = H_MAP(f)*MAP(f) + H_pETCO2(f)*pETCO2(f)
%
% where:
%   input 1 = BP or MAP
%   input 2 = CO2 or pETCO2
%   output  = CBF / CBv / CBFV
%
% Main reason for MISO:
%   Standard TFA often models BP -> CBv.
%   But CO2 also affects CBv, so a 2-input model can separate:
%
%       pressure-driven CBv changes
%       CO2-driven CBv changes
%
% Method:
%   Estimate spectral quantities using Welch's method.
%   Then solve, at each frequency:
%
%       [H_BP; H_CO2] =
%       inv([S_BP_BP    S_BP_CO2;
%            S_CO2_BP   S_CO2_CO2]) *
%       [S_BP_CBF;
%        S_CO2_CBF]
%
% Sho's current requested settings:
%   Hanning window
%   128-second segments
%   50% overlap
%   frequency range: 0.0078125 to 0.5078125 Hz
%
% CARNet reference settings to remember:
%   Hanning window
%   >=100-second window length
%   ~50% overlap
%   triangular spectral smoothing [1/4, 1/2, 1/4]
%   standard reporting range often 0.02 to 0.5 Hz
%
% Benefit:
%   More stable than direct FFT division.
%   Accounts for correlation between BP and CO2.
%
% Limitation:
%   Time-averaged.
%   Does not capture time-varying behavior.

%% Make sure all signals are column vectors

bp  = reshape(bp, [], 1);
co2 = reshape(co2, [], 1);
cbf = reshape(cbf, [], 1);

%% Remove mean values before TFA

bp  = bp  - mean(bp,  'omitnan');
co2 = co2 - mean(co2, 'omitnan');
cbf = cbf - mean(cbf, 'omitnan');

%% TFA / Welch Settings

% Sho's requested settings
windowLength_seconds = 128;
windowLength_samples = windowLength_seconds * fs;

window = hann(windowLength_samples);
noverlap = windowLength_samples / 2;
nfft = windowLength_samples;

% Frequency resolution:
% delta_f = fs / nfft
% If fs = 4 and nfft = 512:
% delta_f = 4 / 512 = 0.0078125 Hz
frequencyResolution = fs / nfft;

% Sho's requested output frequency range
f_min = 0.0078125;
f_max = 0.5078125;

% CARNet settings to remember:
% windowLength_seconds = 100 or 102.4 in some reference implementations
% noverlap approximately 50%
% spectral smoothing sometimes uses triangular [1/4, 1/2, 1/4]
% standard reporting range often 0.02 to 0.5 Hz

%% Check signal length

if length(bp) < windowLength_samples
    error('Signal is shorter than the 128-second Welch window. Use a longer signal or shorten the window.');
end

%% PSDs / Auto-Spectra

[BP_Sxx, f] = pwelch(bp, window, noverlap, nfft, fs);
[CO2_Sxx, ~] = pwelch(co2, window, noverlap, nfft, fs);
[CBF_Syy, ~] = pwelch(cbf, window, noverlap, nfft, fs);

%% Cross Spectra: Input to Output

[BP_CBF_Sxy, ~] = cpsd(bp, cbf, window, noverlap, nfft, fs);
[CO2_CBF_Sxy, ~] = cpsd(co2, cbf, window, noverlap, nfft, fs);

%% Cross Spectra: Input to Input

[BP_CO2_Sxy, ~] = cpsd(bp, co2, window, noverlap, nfft, fs);
[CO2_BP_Sxy, ~] = cpsd(co2, bp, window, noverlap, nfft, fs);

%% MISO Transfer Functions with Reliability Checks

H_BP_CBF_MISO  = NaN(size(f));
H_CO2_CBF_MISO = NaN(size(f));

multipleCoherence = NaN(size(f));
conditionNumber = NaN(size(f));

estimateType = strings(size(f));

% Power thresholds
% These are relative thresholds, not absolute physiological thresholds.
% They say: only trust frequencies where power is not extremely tiny
% compared with the maximum power in that signal.
powerThreshold_BP  = 1e-6 * max(BP_Sxx);
powerThreshold_CO2 = 1e-6 * max(CO2_Sxx);
powerThreshold_CBF = 1e-6 * max(CBF_Syy);

% Matrix conditioning threshold
% If this is too large, the MISO solve is unstable.
conditionThreshold = 1e8;

for k = 1:length(f)

    S_matrix = [BP_Sxx(k),      BP_CO2_Sxy(k);
                CO2_BP_Sxy(k),  CO2_Sxx(k)];

    S_vector = [BP_CBF_Sxy(k);
                CO2_CBF_Sxy(k)];

    conditionNumber(k,1) = cond(S_matrix);

    enoughBPpower  = BP_Sxx(k)  > powerThreshold_BP;
    enoughCO2power = CO2_Sxx(k) > powerThreshold_CO2;
    enoughCBFpower = CBF_Syy(k) > powerThreshold_CBF;

    matrixIsStable = conditionNumber(k) < conditionThreshold;

    if enoughBPpower && enoughCO2power && enoughCBFpower && matrixIsStable

        % True MISO estimate
        H_vector = S_matrix \ S_vector;

        H_BP_CBF_MISO(k,1)  = H_vector(1);
        H_CO2_CBF_MISO(k,1) = H_vector(2);

        estimateType(k,1) = "MISO";

        % Multiple coherence is only meaningful for the true MISO case.
        % It asks how much output power is explained by both inputs together.
        explainedPower = real(H_vector' * S_matrix * H_vector);
        totalOutputPower = CBF_Syy(k);

        multipleCoherence(k,1) = explainedPower / totalOutputPower;

    elseif enoughBPpower && enoughCBFpower

        % BP-only fallback
        H_BP_CBF_MISO(k,1)  = BP_CBF_Sxy(k) / BP_Sxx(k);
        H_CO2_CBF_MISO(k,1) = NaN;

        estimateType(k,1) = "BP_SISO_fallback";

        % Not a true MISO estimate, so leave multiple coherence undefined.
        multipleCoherence(k,1) = NaN;

    elseif enoughCO2power && enoughCBFpower

        % CO2-only fallback
        H_BP_CBF_MISO(k,1)  = NaN;
        H_CO2_CBF_MISO(k,1) = CO2_CBF_Sxy(k) / CO2_Sxx(k);

        estimateType(k,1) = "CO2_SISO_fallback";

        % Not a true MISO estimate, so leave multiple coherence undefined.
        multipleCoherence(k,1) = NaN;

    else

        % Not enough information
        H_BP_CBF_MISO(k,1)  = NaN;
        H_CO2_CBF_MISO(k,1) = NaN;

        estimateType(k,1) = "insufficient_power";
        multipleCoherence(k,1) = NaN;

    end

end

%% Pairwise Magnitude-Squared Coherence

BP_CBF_coherence = abs(BP_CBF_Sxy).^2 ./ (BP_Sxx .* CBF_Syy);
CO2_CBF_coherence = abs(CO2_CBF_Sxy).^2 ./ (CO2_Sxx .* CBF_Syy);
BP_CO2_coherence = abs(BP_CO2_Sxy).^2 ./ (BP_Sxx .* CO2_Sxx);

% Mask coherence where power is too low
BP_CBF_coherence(BP_Sxx < powerThreshold_BP | CBF_Syy < powerThreshold_CBF) = NaN;
CO2_CBF_coherence(CO2_Sxx < powerThreshold_CO2 | CBF_Syy < powerThreshold_CBF) = NaN;
BP_CO2_coherence(BP_Sxx < powerThreshold_BP | CO2_Sxx < powerThreshold_CO2) = NaN;

%% Gain and Phase

gain_BP_CBF_MISO = abs(H_BP_CBF_MISO);
gain_CO2_CBF_MISO = abs(H_CO2_CBF_MISO);

phase_BP_CBF_MISO = angle(H_BP_CBF_MISO);      % radians
phase_CO2_CBF_MISO = angle(H_CO2_CBF_MISO);    % radians

%% Restrict Frequency Range

freqMask = f >= f_min & f <= f_max;

f_out = f(freqMask);

BP_Sxx_out = BP_Sxx(freqMask);
CO2_Sxx_out = CO2_Sxx(freqMask);
CBF_Syy_out = CBF_Syy(freqMask);

BP_CBF_Sxy_out = BP_CBF_Sxy(freqMask);
CO2_CBF_Sxy_out = CO2_CBF_Sxy(freqMask);

BP_CO2_Sxy_out = BP_CO2_Sxy(freqMask);
CO2_BP_Sxy_out = CO2_BP_Sxy(freqMask);

H_BP_CBF_MISO_out = H_BP_CBF_MISO(freqMask);
H_CO2_CBF_MISO_out = H_CO2_CBF_MISO(freqMask);

gain_BP_CBF_MISO_out = gain_BP_CBF_MISO(freqMask);
gain_CO2_CBF_MISO_out = gain_CO2_CBF_MISO(freqMask);

phase_BP_CBF_MISO_out = phase_BP_CBF_MISO(freqMask);
phase_CO2_CBF_MISO_out = phase_CO2_CBF_MISO(freqMask);

multipleCoherence_out = multipleCoherence(freqMask);

BP_CBF_coherence_out = BP_CBF_coherence(freqMask);
CO2_CBF_coherence_out = CO2_CBF_coherence(freqMask);
BP_CO2_coherence_out = BP_CO2_coherence(freqMask);

estimateType_out = estimateType(freqMask);
conditionNumber_out = conditionNumber(freqMask);

%% Reliability-Based Plotting Masks

% Coherence threshold for deciding which gain/phase estimates are reliable
% enough to display in the main transfer function plots.
coherenceThreshold = 0.51;

% Input-input coherence threshold.
% If BP and CO2 are too coherent with each other, the MISO model may have
% trouble separating their independent effects on CBF.
inputCoherenceThreshold = 0.80;

% Stronger power thresholds for plotting only.
% These are stricter than the numerical thresholds used to avoid division
% by very small values.
plotPowerThreshold_BP  = 1e-3 * max(BP_Sxx_out);
plotPowerThreshold_CO2 = 1e-3 * max(CO2_Sxx_out);
plotPowerThreshold_CBF = 1e-3 * max(CBF_Syy_out);

strongBPpower  = BP_Sxx_out  >= plotPowerThreshold_BP;
strongCO2power = CO2_Sxx_out >= plotPowerThreshold_CO2;
strongCBFpower = CBF_Syy_out >= plotPowerThreshold_CBF;

% Make plotting copies of the transfer functions.
% Raw transfer functions are still kept unchanged.
H_BP_CBF_MISO_plot  = H_BP_CBF_MISO_out;
H_CO2_CBF_MISO_plot = H_CO2_CBF_MISO_out;

%% MISO reliability masks

% BP MISO plot:
% To show BP->CBF from a true MISO estimate, require:
%   1. the point came from the full MISO solve,
%   2. BP has meaningful power,
%   3. CBF has meaningful power,
%   4. BP and CBF have sufficient pairwise coherence,
%   5. BP+CO2 together explain CBF sufficiently,
%   6. the matrix solve is stable,
%   7. BP and CO2 are not too strongly coupled.
validBP_MISOplot = ...
    estimateType_out == "MISO" & ...
    strongBPpower & ...
    strongCBFpower & ...
    BP_CBF_coherence_out >= coherenceThreshold & ...
    multipleCoherence_out >= coherenceThreshold & ...
    conditionNumber_out < conditionThreshold & ...
    BP_CO2_coherence_out < inputCoherenceThreshold;

% CO2 MISO plot:
% Same idea, but input-specific checks use CO2 power and CO2-CBF coherence.
validCO2_MISOplot = ...
    estimateType_out == "MISO" & ...
    strongCO2power & ...
    strongCBFpower & ...
    CO2_CBF_coherence_out >= coherenceThreshold & ...
    multipleCoherence_out >= coherenceThreshold & ...
    conditionNumber_out < conditionThreshold & ...
    BP_CO2_coherence_out < inputCoherenceThreshold;

%% SISO fallback reliability masks

% For fallback points, use pairwise coherence because these are no longer
% true two-input MISO estimates.
validBPfallbackPlot = ...
    estimateType_out == "BP_SISO_fallback" & ...
    strongBPpower & ...
    strongCBFpower & ...
    BP_CBF_coherence_out >= coherenceThreshold;

validCO2fallbackPlot = ...
    estimateType_out == "CO2_SISO_fallback" & ...
    strongCO2power & ...
    strongCBFpower & ...
    CO2_CBF_coherence_out >= coherenceThreshold;

%% Final plotting masks

% Use OR here because a point can be reliable through either:
%   true MISO pathway OR SISO fallback pathway.
validBPplot = validBP_MISOplot | validBPfallbackPlot;
validCO2plot = validCO2_MISOplot | validCO2fallbackPlot;

%% Hide unreliable points from plotting copies

H_BP_CBF_MISO_plot(~validBPplot) = NaN;
H_CO2_CBF_MISO_plot(~validCO2plot) = NaN;

%% Plot Coherence-Masked Transfer Functions

plotComplexMagnitudePhase(H_BP_CBF_MISO_plot, f_out, ...
    'MISO TFA H: BP to CBF');

plotComplexMagnitudePhase(H_CO2_CBF_MISO_plot, f_out, ...
    'MISO TFA H: CO2 to CBF');

%% Plot Coherence Diagnostics

figure();

plot(f_out, BP_CBF_coherence_out);
hold on;
plot(f_out, CO2_CBF_coherence_out);
hold on;
plot(f_out, multipleCoherence_out);

xlabel('Frequency (Hz)');
ylabel('Coherence');
legend('BP-CBF pairwise', 'CO2-CBF pairwise', 'MISO multiple coherence');
title('Coherence Diagnostics');
grid on;

%% Store Results

tfaResults.f = f_out;
tfaResults.freqMask = freqMask;
tfaResults.frequencyResolution = frequencyResolution;

tfaResults.windowLength_seconds = windowLength_seconds;
tfaResults.windowLength_samples = windowLength_samples;
tfaResults.noverlap = noverlap;
tfaResults.nfft = nfft;

tfaResults.BP_Sxx = BP_Sxx_out;
tfaResults.CO2_Sxx = CO2_Sxx_out;
tfaResults.CBF_Syy = CBF_Syy_out;

tfaResults.BP_CBF_Sxy = BP_CBF_Sxy_out;
tfaResults.CO2_CBF_Sxy = CO2_CBF_Sxy_out;

tfaResults.BP_CO2_Sxy = BP_CO2_Sxy_out;
tfaResults.CO2_BP_Sxy = CO2_BP_Sxy_out;

tfaResults.H_BP_CBF_MISO = H_BP_CBF_MISO_out;
tfaResults.H_CO2_CBF_MISO = H_CO2_CBF_MISO_out;

tfaResults.gain_BP_CBF_MISO = gain_BP_CBF_MISO_out;
tfaResults.gain_CO2_CBF_MISO = gain_CO2_CBF_MISO_out;

tfaResults.phase_BP_CBF_MISO = phase_BP_CBF_MISO_out;
tfaResults.phase_CO2_CBF_MISO = phase_CO2_CBF_MISO_out;

tfaResults.BP_CBF_coherence = BP_CBF_coherence_out;
tfaResults.CO2_CBF_coherence = CO2_CBF_coherence_out;
tfaResults.BP_CO2_coherence = BP_CO2_coherence_out;

tfaResults.multipleCoherence = multipleCoherence_out;

tfaResults.estimateType = estimateType_out;
tfaResults.conditionNumber = conditionNumber_out;

tfaResults.H_BP_CBF_MISO_plot = H_BP_CBF_MISO_plot;
tfaResults.H_CO2_CBF_MISO_plot = H_CO2_CBF_MISO_plot;

tfaResults.coherenceThreshold = coherenceThreshold;
tfaResults.inputCoherenceThreshold = inputCoherenceThreshold;

tfaResults.validBP_MISOplot = validBP_MISOplot;
tfaResults.validCO2_MISOplot = validCO2_MISOplot;
tfaResults.validBPfallbackPlot = validBPfallbackPlot;
tfaResults.validCO2fallbackPlot = validCO2fallbackPlot;

tfaResults.validBPplot = validBPplot;
tfaResults.validCO2plot = validCO2plot;

tfaResults.gain_BP_CBF_MISO_plot = abs(H_BP_CBF_MISO_plot);
tfaResults.gain_CO2_CBF_MISO_plot = abs(H_CO2_CBF_MISO_plot);

tfaResults.phase_BP_CBF_MISO_plot = angle(H_BP_CBF_MISO_plot);
tfaResults.phase_CO2_CBF_MISO_plot = angle(H_CO2_CBF_MISO_plot);

end