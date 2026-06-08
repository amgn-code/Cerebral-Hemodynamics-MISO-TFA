function sisoResults = runSISO(bp, co2, cbf, fs)

% runSISO
%
% SISO PSD / cross-spectral transfer function pipeline.
%
% Estimates two independent SISO transfer functions:
%
%   H_BP_CBF(f)  = S_BP_CBF(f)  / S_BP_BP(f)
%   H_CO2_CBF(f) = S_CO2_CBF(f) / S_CO2_CO2(f)
%
% SISO limitation:
%   BP -> CBF is estimated while ignoring CO2.
%   CO2 -> CBF is estimated while ignoring BP.
%
% This is useful as a comparison against the MISO pipeline.

%% Format signals

bp_clean  = reshape(bp,  1, []);
co2_clean = reshape(co2, 1, []);
cbf_clean = reshape(cbf, 1, []);

%% Remove means

bp_clean  = bp_clean  - mean(bp_clean,  'omitnan');
co2_clean = co2_clean - mean(co2_clean, 'omitnan');
cbf_clean = cbf_clean - mean(cbf_clean, 'omitnan');

%% Welch settings

window_length_s = 128;
window_overlap = 0.5;

window_length_n = window_length_s * fs;
window = hann(window_length_n);
window_overlap_n = window_length_n * window_overlap;
fft_length_n = window_length_n;
window_step_n = window_length_n - window_overlap_n;
num_windows = floor((length(bp_clean) - window_length_n) / window_step_n) + 1;

if length(bp_clean) < window_length_n
    error('Signal is shorter than the Welch window. Use a longer signal or reduce window_length_s.');
end

frequencyResolution = fs / fft_length_n;

%% Spectral estimates

[S_bpbp, f]   = cpsd(bp_clean,  bp_clean,  window, window_overlap_n, fft_length_n, fs);
[S_co2co2, ~] = cpsd(co2_clean, co2_clean, window, window_overlap_n, fft_length_n, fs);
[S_cbfcfb, ~] = cpsd(cbf_clean, cbf_clean, window, window_overlap_n, fft_length_n, fs);

[S_bpcbf, ~]  = cpsd(bp_clean,  cbf_clean, window, window_overlap_n, fft_length_n, fs);
[S_co2cbf, ~] = cpsd(co2_clean, cbf_clean, window, window_overlap_n, fft_length_n, fs);

%% Triangular smoothing

triangular_smoothing_window = [0.25, 0.5, 0.25];

S_bpbp_smoothed   = conv(S_bpbp,   triangular_smoothing_window, 'same');
S_co2co2_smoothed = conv(S_co2co2, triangular_smoothing_window, 'same');
S_cbfcfb_smoothed = conv(S_cbfcfb, triangular_smoothing_window, 'same');

S_bpcbf_smoothed  = conv(S_bpcbf,  triangular_smoothing_window, 'same');
S_co2cbf_smoothed = conv(S_co2cbf, triangular_smoothing_window, 'same');

%% Coherence critical values

num_welch_windows = [3, 4, 5, 6, 7, 8, 9, 10, 15, 20, 25];
coherence_critical_vals = [0.51, 0.41, 0.34, 0.29, 0.25, 0.22, 0.20, 0.18, 0.12, 0.09, 0.08];

coherence_threshold = coherence_critical_vals(find(num_windows == num_welch_windows, 1));

if isempty(coherence_threshold)
    warning('num_windows does not match coherence lookup table. Using default threshold of 0.51.');
    coherence_threshold = 0.51;
end

%% SISO transfer functions

Eps_BP = 1e-6 * max(real(S_bpbp_smoothed));
Eps_CO2 = 1e-6 * max(real(S_co2co2_smoothed));

H_bpcbf = S_bpcbf_smoothed ./ (S_bpbp_smoothed + Eps_BP);
H_co2cbf = S_co2cbf_smoothed ./ (S_co2co2_smoothed + Eps_CO2);


%% Univariate coherence

bp_cbf_coherence = abs(S_bpcbf_smoothed).^2 ./ ...
    real(S_bpbp_smoothed .* S_cbfcfb_smoothed);

co2_cbf_coherence = abs(S_co2cbf_smoothed).^2 ./ ...
    real(S_co2co2_smoothed .* S_cbfcfb_smoothed);

% Clean impossible numerical values
bp_cbf_coherence = real(bp_cbf_coherence);
co2_cbf_coherence = real(co2_cbf_coherence);

bp_cbf_coherence(bp_cbf_coherence > 1) = 1;
co2_cbf_coherence(co2_cbf_coherence > 1) = 1;

bp_cbf_coherence(bp_cbf_coherence < 0) = 0;
co2_cbf_coherence(co2_cbf_coherence < 0) = 0;

%% H BP -> CBF with coherence overlay

figure('Name', 'SisoBpToCbfTransferFunction1', 'NumberTitle', 'off')

subplot(1,2,1)
yyaxis left
stem(f, abs(H_bpcbf))
ylabel('Magnitude')
hold on

yyaxis right
plot(f, bp_cbf_coherence, 'LineWidth', 1.5)
ylabel('Coherence')
ylim([0 1])

title('BP to CBF Gain')
xlabel('Frequency (Hz)')
grid on

subplot(1,2,2)
yyaxis left
stem(f, angle(H_bpcbf))
ylabel('Phase (rad)')
hold on

yyaxis right
plot(f, bp_cbf_coherence, 'LineWidth', 1.5)
ylabel('Coherence')
ylim([0 1])

title('BP to CBF Phase')
xlabel('Frequency (Hz)')
grid on

sgtitle('BP to CBF Transfer Function')

%% H CO2 -> CBF with coherence overlay

figure('Name', 'SisoCo2ToCbfTransferFunction1', 'NumberTitle', 'off')

subplot(1,2,1)
yyaxis left
stem(f, abs(H_co2cbf))
ylabel('Magnitude')
hold on

yyaxis right
plot(f, co2_cbf_coherence, 'LineWidth', 1.5)
ylabel('Coherence')
ylim([0 1])

title('CO2 to CBF Gain')
xlabel('Frequency (Hz)')
grid on

subplot(1,2,2)
yyaxis left
stem(f, angle(H_co2cbf))
ylabel('Phase (rad)')
hold on

yyaxis right
plot(f, co2_cbf_coherence, 'LineWidth', 1.5)
ylabel('Coherence')
ylim([0 1])

title('CO2 to CBF Phase')
xlabel('Frequency (Hz)')
grid on

sgtitle('CO2 to CBF Transfer Function')

%% VLF, LF, HF partitioned

vlf = f(f >= 0.02 & f <= 0.07);
lf  = f(f > 0.07 & f <= 0.20);
hf  = f(f > 0.20 & f <= 0.50);

vlf_H_bpcbf = H_bpcbf(f >= 0.02 & f <= 0.07);
lf_H_bpcbf  = H_bpcbf(f > 0.07 & f <= 0.20);
hf_H_bpcbf  = H_bpcbf(f > 0.20 & f <= 0.50);

vlf_H_co2cbf = H_co2cbf(f >= 0.02 & f <= 0.07);
lf_H_co2cbf  = H_co2cbf(f > 0.07 & f <= 0.20);
hf_H_co2cbf  = H_co2cbf(f > 0.20 & f <= 0.50);

vlf_bp_cbf_coherence = bp_cbf_coherence(f >= 0.02 & f <= 0.07);
lf_bp_cbf_coherence  = bp_cbf_coherence(f > 0.07 & f <= 0.20);
hf_bp_cbf_coherence  = bp_cbf_coherence(f > 0.20 & f <= 0.50);

vlf_co2_cbf_coherence = co2_cbf_coherence(f >= 0.02 & f <= 0.07);
lf_co2_cbf_coherence  = co2_cbf_coherence(f > 0.07 & f <= 0.20);
hf_co2_cbf_coherence  = co2_cbf_coherence(f > 0.20 & f <= 0.50);

%% VLF, LF, HF for BP to CBF

figure('Name', 'PartitionedSisoBpToCbfTransferFunction', 'NumberTitle', 'off')

subplot(3,2,1)
yyaxis left
stem(vlf, abs(vlf_H_bpcbf))
ylabel('Gain')
hold on
yyaxis right
plot(vlf, vlf_bp_cbf_coherence, 'LineWidth', 1.5)
ylabel('Coherence')
ylim([0 1])
title('VLF BP to CBF')
xlabel('Frequency (Hz)')
grid on

subplot(3,2,2)
yyaxis left
stem(vlf, angle(vlf_H_bpcbf))
ylabel('Phase (rad)')
hold on
yyaxis right
plot(vlf, vlf_bp_cbf_coherence, 'LineWidth', 1.5)
ylabel('Coherence')
ylim([0 1])
title('VLF BP to CBF')
xlabel('Frequency (Hz)')
grid on

subplot(3,2,3)
yyaxis left
stem(lf, abs(lf_H_bpcbf))
ylabel('Gain')
hold on
yyaxis right
plot(lf, lf_bp_cbf_coherence, 'LineWidth', 1.5)
ylabel('Coherence')
ylim([0 1])
title('LF BP to CBF')
xlabel('Frequency (Hz)')
grid on

subplot(3,2,4)
yyaxis left
stem(lf, angle(lf_H_bpcbf))
ylabel('Phase (rad)')
hold on
yyaxis right
plot(lf, lf_bp_cbf_coherence, 'LineWidth', 1.5)
ylabel('Coherence')
ylim([0 1])
title('LF BP to CBF')
xlabel('Frequency (Hz)')
grid on

subplot(3,2,5)
yyaxis left
stem(hf, abs(hf_H_bpcbf))
ylabel('Gain')
hold on
yyaxis right
plot(hf, hf_bp_cbf_coherence, 'LineWidth', 1.5)
ylabel('Coherence')
ylim([0 1])
title('HF BP to CBF')
xlabel('Frequency (Hz)')
grid on

subplot(3,2,6)
yyaxis left
stem(hf, angle(hf_H_bpcbf))
ylabel('Phase (rad)')
hold on
yyaxis right
plot(hf, hf_bp_cbf_coherence, 'LineWidth', 1.5)
ylabel('Coherence')
ylim([0 1])
title('HF BP to CBF')
xlabel('Frequency (Hz)')
grid on

sgtitle('Partitioned BP to CBF Transfer Function')

%% VLF, LF, HF for CO2 to CBF

figure('Name', 'PartitionedSisoCo2ToCbfTransferFunction', 'NumberTitle', 'off')

subplot(3,2,1)
yyaxis left
stem(vlf, abs(vlf_H_co2cbf))
ylabel('Gain')
hold on
yyaxis right
plot(vlf, vlf_co2_cbf_coherence, 'LineWidth', 1.5)
ylabel('Coherence')
ylim([0 1])
title('VLF CO2 to CBF')
xlabel('Frequency (Hz)')
grid on

subplot(3,2,2)
yyaxis left
stem(vlf, angle(vlf_H_co2cbf))
ylabel('Phase (rad)')
hold on
yyaxis right
plot(vlf, vlf_co2_cbf_coherence, 'LineWidth', 1.5)
ylabel('Coherence')
ylim([0 1])
title('VLF CO2 to CBF')
xlabel('Frequency (Hz)')
grid on

subplot(3,2,3)
yyaxis left
stem(lf, abs(lf_H_co2cbf))
ylabel('Gain')
hold on
yyaxis right
plot(lf, lf_co2_cbf_coherence, 'LineWidth', 1.5)
ylabel('Coherence')
ylim([0 1])
title('LF CO2 to CBF')
xlabel('Frequency (Hz)')
grid on

subplot(3,2,4)
yyaxis left
stem(lf, angle(lf_H_co2cbf))
ylabel('Phase (rad)')
hold on
yyaxis right
plot(lf, lf_co2_cbf_coherence, 'LineWidth', 1.5)
ylabel('Coherence')
ylim([0 1])
title('LF CO2 to CBF')
xlabel('Frequency (Hz)')
grid on

subplot(3,2,5)
yyaxis left
stem(hf, abs(hf_H_co2cbf))
ylabel('Gain')
hold on
yyaxis right
plot(hf, hf_co2_cbf_coherence, 'LineWidth', 1.5)
ylabel('Coherence')
ylim([0 1])
title('HF CO2 to CBF')
xlabel('Frequency (Hz)')
grid on

subplot(3,2,6)
yyaxis left
stem(hf, angle(hf_H_co2cbf))
ylabel('Phase (rad)')
hold on
yyaxis right
plot(hf, hf_co2_cbf_coherence, 'LineWidth', 1.5)
ylabel('Coherence')
ylim([0 1])
title('HF CO2 to CBF')
xlabel('Frequency (Hz)')
grid on

sgtitle('Partitioned CO2 to CBF Transfer Function')

%% Coherence-filtered H BP -> CBF

coh_filtered_H_bpcbf = H_bpcbf;
coh_filtered_H_bpcbf(bp_cbf_coherence < coherence_threshold) = NaN;

figure('Name', 'CohFilteredSisoBpToCbfTransferFunction', 'NumberTitle', 'off')

subplot(1,2,1)
stem(f, abs(coh_filtered_H_bpcbf))
xlabel('Frequency (Hz)')
ylabel('Magnitude')
grid on

subplot(1,2,2)
stem(f, angle(coh_filtered_H_bpcbf))
xlabel('Frequency (Hz)')
ylabel('Phase (rad)')
grid on

sgtitle('Coherence Filtered BP to CBF Transfer Function')

%% Coherence-filtered H CO2 -> CBF

coh_filtered_H_co2cbf = H_co2cbf;
coh_filtered_H_co2cbf(co2_cbf_coherence < coherence_threshold) = NaN;

figure('Name', 'CohFilteredSisoCo2ToCbfTransferFunction', 'NumberTitle', 'off')

subplot(1,2,1)
stem(f, abs(coh_filtered_H_co2cbf))
xlabel('Frequency (Hz)')
ylabel('Magnitude')
grid on

subplot(1,2,2)
stem(f, angle(coh_filtered_H_co2cbf))
xlabel('Frequency (Hz)')
ylabel('Phase (rad)')
grid on

sgtitle('Coherence Filtered CO2 to CBF Transfer Function')

%% Coherence-filtered H vlf, lf, hf partitioned

vlf_coh_filtered_H_bpcbf = vlf_H_bpcbf;
lf_coh_filtered_H_bpcbf  = lf_H_bpcbf;
hf_coh_filtered_H_bpcbf  = hf_H_bpcbf;

vlf_coh_filtered_H_bpcbf(vlf_bp_cbf_coherence < coherence_threshold) = NaN;
lf_coh_filtered_H_bpcbf(lf_bp_cbf_coherence < coherence_threshold) = NaN;
hf_coh_filtered_H_bpcbf(hf_bp_cbf_coherence < coherence_threshold) = NaN;

vlf_coh_filtered_H_co2cbf = vlf_H_co2cbf;
lf_coh_filtered_H_co2cbf  = lf_H_co2cbf;
hf_coh_filtered_H_co2cbf  = hf_H_co2cbf;

vlf_coh_filtered_H_co2cbf(vlf_co2_cbf_coherence < coherence_threshold) = NaN;
lf_coh_filtered_H_co2cbf(lf_co2_cbf_coherence < coherence_threshold) = NaN;
hf_coh_filtered_H_co2cbf(hf_co2_cbf_coherence < coherence_threshold) = NaN;

%% VLF, LF, HF for coherence-filtered BP to CBF

figure('Name', 'PartitionedCohFilteredSisoBpToCbfTransferFunction', 'NumberTitle', 'off')

subplot(3,2,1)
stem(vlf, abs(vlf_coh_filtered_H_bpcbf))
title('VLF BP to CBF')
xlabel('Frequency (Hz)')
ylabel('Gain')
grid on

subplot(3,2,2)
stem(vlf, angle(vlf_coh_filtered_H_bpcbf))
title('VLF BP to CBF')
xlabel('Frequency (Hz)')
ylabel('Phase (rad)')
grid on

subplot(3,2,3)
stem(lf, abs(lf_coh_filtered_H_bpcbf))
title('LF BP to CBF')
xlabel('Frequency (Hz)')
ylabel('Gain')
grid on

subplot(3,2,4)
stem(lf, angle(lf_coh_filtered_H_bpcbf))
title('LF BP to CBF')
xlabel('Frequency (Hz)')
ylabel('Phase (rad)')
grid on

subplot(3,2,5)
stem(hf, abs(hf_coh_filtered_H_bpcbf))
title('HF BP to CBF')
xlabel('Frequency (Hz)')
ylabel('Gain')
grid on

subplot(3,2,6)
stem(hf, angle(hf_coh_filtered_H_bpcbf))
title('HF BP to CBF')
xlabel('Frequency (Hz)')
ylabel('Phase (rad)')
grid on

sgtitle('Coherence Filtered BP to CBF Transfer Function')

%% VLF, LF, HF for coherence-filtered CO2 to CBF

figure('Name', 'PartitionedCohFilteredSisoCo2ToCbfTransferFunction', 'NumberTitle', 'off')

subplot(3,2,1)
stem(vlf, abs(vlf_coh_filtered_H_co2cbf))
title('VLF CO2 to CBF')
xlabel('Frequency (Hz)')
ylabel('Gain')
grid on

subplot(3,2,2)
stem(vlf, angle(vlf_coh_filtered_H_co2cbf))
title('VLF CO2 to CBF')
xlabel('Frequency (Hz)')
ylabel('Phase (rad)')
grid on

subplot(3,2,3)
stem(lf, abs(lf_coh_filtered_H_co2cbf))
title('LF CO2 to CBF')
xlabel('Frequency (Hz)')
ylabel('Gain')
grid on

subplot(3,2,4)
stem(lf, angle(lf_coh_filtered_H_co2cbf))
title('LF CO2 to CBF')
xlabel('Frequency (Hz)')
ylabel('Phase (rad)')
grid on

subplot(3,2,5)
stem(hf, abs(hf_coh_filtered_H_co2cbf))
title('HF CO2 to CBF')
xlabel('Frequency (Hz)')
ylabel('Gain')
grid on

subplot(3,2,6)
stem(hf, angle(hf_coh_filtered_H_co2cbf))
title('HF CO2 to CBF')
xlabel('Frequency (Hz)')
ylabel('Phase (rad)')
grid on

sgtitle('Coherence Filtered CO2 to CBF Transfer Function')

%% Store results

sisoResults.f = f;

sisoResults.frequencyResolution = frequencyResolution;
sisoResults.window_length_s = window_length_s;
sisoResults.window_length_n = window_length_n;
sisoResults.window_overlap = window_overlap;
sisoResults.window_overlap_n = window_overlap_n;
sisoResults.fft_length_n = fft_length_n;
sisoResults.num_windows = num_windows;

sisoResults.S_bpbp = S_bpbp;
sisoResults.S_co2co2 = S_co2co2;
sisoResults.S_cbfcfb = S_cbfcfb;
sisoResults.S_bpcbf = S_bpcbf;
sisoResults.S_co2cbf = S_co2cbf;

sisoResults.S_bpbp_smoothed = S_bpbp_smoothed;
sisoResults.S_co2co2_smoothed = S_co2co2_smoothed;
sisoResults.S_cbfcfb_smoothed = S_cbfcfb_smoothed;
sisoResults.S_bpcbf_smoothed = S_bpcbf_smoothed;
sisoResults.S_co2cbf_smoothed = S_co2cbf_smoothed;

sisoResults.H_bpcbf = H_bpcbf;
sisoResults.H_co2cbf = H_co2cbf;

sisoResults.bp_cbf_coherence = bp_cbf_coherence;
sisoResults.co2_cbf_coherence = co2_cbf_coherence;

sisoResults.coherence_threshold = coherence_threshold;

sisoResults.vlf = vlf;
sisoResults.lf = lf;
sisoResults.hf = hf;

sisoResults.vlf_H_bpcbf = vlf_H_bpcbf;
sisoResults.lf_H_bpcbf = lf_H_bpcbf;
sisoResults.hf_H_bpcbf = hf_H_bpcbf;

sisoResults.vlf_H_co2cbf = vlf_H_co2cbf;
sisoResults.lf_H_co2cbf = lf_H_co2cbf;
sisoResults.hf_H_co2cbf = hf_H_co2cbf;

sisoResults.coh_filtered_H_bpcbf = coh_filtered_H_bpcbf;
sisoResults.coh_filtered_H_co2cbf = coh_filtered_H_co2cbf;

sisoResults.vlf_coh_filtered_H_bpcbf = vlf_coh_filtered_H_bpcbf;
sisoResults.lf_coh_filtered_H_bpcbf = lf_coh_filtered_H_bpcbf;
sisoResults.hf_coh_filtered_H_bpcbf = hf_coh_filtered_H_bpcbf;

sisoResults.vlf_coh_filtered_H_co2cbf = vlf_coh_filtered_H_co2cbf;
sisoResults.lf_coh_filtered_H_co2cbf = lf_coh_filtered_H_co2cbf;
sisoResults.hf_coh_filtered_H_co2cbf = hf_coh_filtered_H_co2cbf;

end