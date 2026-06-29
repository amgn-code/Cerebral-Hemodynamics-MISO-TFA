function sisoResults = runSISOTFA(bp, co2, cbf, fs)

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

% Correct MATLAB cpsd phase convention for H = output / input
S_bpcbf_tf  = conj(S_bpcbf_smoothed);
S_co2cbf_tf = conj(S_co2cbf_smoothed);

Eps_BP = 1e-6 * max(real(S_bpbp_smoothed));
Eps_CO2 = 1e-6 * max(real(S_co2co2_smoothed));

H_bpcbf = S_bpcbf_tf ./ (S_bpbp_smoothed + Eps_BP);
H_co2cbf = S_co2cbf_tf ./ (S_co2co2_smoothed + Eps_CO2);

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

%% H BP -> CBF with standard coherence overlay

figure('Name', 'SisoBpToCbfTransferFunction', 'NumberTitle', 'off')

subplot(1,2,1)
yyaxis left
h_tf_gain = stem(f, abs(H_bpcbf), 'filled');
ylabel('Magnitude')
xlabel('Frequency (Hz)')
title('BP to CBF Gain')
grid on
hold on

left_min = min(abs(H_bpcbf), [], 'omitnan');
left_max = max(abs(H_bpcbf), [], 'omitnan');
left_min = min(left_min, 0);
left_max = max(left_max, 0);

if left_min == left_max
    left_min = left_min - 1;
    left_max = left_max + 1;
end

yyaxis right
h_coh_gain = plot(f, bp_cbf_coherence, 'LineWidth', 0.7);
ylabel('Coherence')

right_max = max([1; bp_cbf_coherence(:)], [], 'omitnan');
right_max = 1.05 * right_max;

alignRightYAxisZero(left_min, left_max, right_max)

legend([h_tf_gain, h_coh_gain], ...
    {'Transfer function', 'Coherence'}, ...
    'Location', 'best')


subplot(1,2,2)
yyaxis left
h_tf_phase = stem(f, angle(H_bpcbf), 'filled');
ylabel('Phase (rad)')
xlabel('Frequency (Hz)')
title('BP to CBF Phase')
grid on
hold on

left_min = min(angle(H_bpcbf), [], 'omitnan');
left_max = max(angle(H_bpcbf), [], 'omitnan');
left_min = min(left_min, 0);
left_max = max(left_max, 0);

if left_min == left_max
    left_min = left_min - 1;
    left_max = left_max + 1;
end

yyaxis right
h_coh_phase = plot(f, bp_cbf_coherence, 'LineWidth', 0.7);
ylabel('Coherence')

right_max = max([1; bp_cbf_coherence(:)], [], 'omitnan');
right_max = 1.05 * right_max;

alignRightYAxisZero(left_min, left_max, right_max)

legend([h_tf_phase, h_coh_phase], ...
    {'Transfer function', 'Coherence'}, ...
    'Location', 'best')

sgtitle('BP to CBF Transfer Function')


%% H CO2 -> CBF with standard coherence overlay

figure('Name', 'SisoCo2ToCbfTransferFunction', 'NumberTitle', 'off')

subplot(1,2,1)
yyaxis left
h_tf_gain = stem(f, abs(H_co2cbf), 'filled');
ylabel('Magnitude')
xlabel('Frequency (Hz)')
title('CO2 to CBF Gain')
grid on
hold on

left_min = min(abs(H_co2cbf), [], 'omitnan');
left_max = max(abs(H_co2cbf), [], 'omitnan');
left_min = min(left_min, 0);
left_max = max(left_max, 0);

if left_min == left_max
    left_min = left_min - 1;
    left_max = left_max + 1;
end

yyaxis right
h_coh_gain = plot(f, co2_cbf_coherence, 'LineWidth', 0.7);
ylabel('Coherence')

right_max = max([1; co2_cbf_coherence(:)], [], 'omitnan');
right_max = 1.05 * right_max;

alignRightYAxisZero(left_min, left_max, right_max)

legend([h_tf_gain, h_coh_gain], ...
    {'Transfer function', 'Coherence'}, ...
    'Location', 'best')


subplot(1,2,2)
yyaxis left
h_tf_phase = stem(f, angle(H_co2cbf), 'filled');
ylabel('Phase (rad)')
xlabel('Frequency (Hz)')
title('CO2 to CBF Phase')
grid on
hold on

left_min = min(angle(H_co2cbf), [], 'omitnan');
left_max = max(angle(H_co2cbf), [], 'omitnan');
left_min = min(left_min, 0);
left_max = max(left_max, 0);

if left_min == left_max
    left_min = left_min - 1;
    left_max = left_max + 1;
end

yyaxis right
h_coh_phase = plot(f, co2_cbf_coherence, 'LineWidth', 0.7);
ylabel('Coherence')

right_max = max([1; co2_cbf_coherence(:)], [], 'omitnan');
right_max = 1.05 * right_max;

alignRightYAxisZero(left_min, left_max, right_max)

legend([h_tf_phase, h_coh_phase], ...
    {'Transfer function', 'Coherence'}, ...
    'Location', 'best')

sgtitle('CO2 to CBF Transfer Function')


%% VLF, LF, HF partitioned

bands = getFrequencyBands(f);

vlf = bands.vlf.f;
lf  = bands.lf.f;
hf  = bands.hf.f;

vlf_H_bpcbf = H_bpcbf(bands.vlf.idx);
lf_H_bpcbf  = H_bpcbf(bands.lf.idx);
hf_H_bpcbf  = H_bpcbf(bands.hf.idx);

vlf_H_co2cbf = H_co2cbf(bands.vlf.idx);
lf_H_co2cbf  = H_co2cbf(bands.lf.idx);
hf_H_co2cbf  = H_co2cbf(bands.hf.idx);

vlf_bp_cbf_coherence = bp_cbf_coherence(bands.vlf.idx);
lf_bp_cbf_coherence  = bp_cbf_coherence(bands.lf.idx);
hf_bp_cbf_coherence  = bp_cbf_coherence(bands.hf.idx);

vlf_co2_cbf_coherence = co2_cbf_coherence(bands.vlf.idx);
lf_co2_cbf_coherence  = co2_cbf_coherence(bands.lf.idx);
hf_co2_cbf_coherence  = co2_cbf_coherence(bands.hf.idx);


%% Partitioned BP to CBF with coherence overlay

figure('Name', 'PartitionedSisoBpToCbfTransferFunction', 'NumberTitle', 'off')

% VLF gain
subplot(3,2,1)
yyaxis left
h_tf = stem(vlf, abs(vlf_H_bpcbf), 'filled');
ylabel('Magnitude')
xlabel('Frequency (Hz)')
title('VLF BP to CBF Gain')
grid on
hold on

left_min = min(abs(vlf_H_bpcbf), [], 'omitnan');
left_max = max(abs(vlf_H_bpcbf), [], 'omitnan');
left_min = min(left_min, 0);
left_max = max(left_max, 0);
if left_min == left_max
    left_min = left_min - 1;
    left_max = left_max + 1;
end

yyaxis right
h_coh = plot(vlf, vlf_bp_cbf_coherence, 'LineWidth', 0.7);
ylabel('Coherence')
right_max = 1.05 * max([1; vlf_bp_cbf_coherence(:)], [], 'omitnan');
alignRightYAxisZero(left_min, left_max, right_max)
legend([h_tf, h_coh], {'Transfer function', 'Coherence'}, 'Location', 'best')

% VLF phase
subplot(3,2,2)
yyaxis left
h_tf = stem(vlf, angle(vlf_H_bpcbf), 'filled');
ylabel('Phase (rad)')
xlabel('Frequency (Hz)')
title('VLF BP to CBF Phase')
grid on
hold on

left_min = min(angle(vlf_H_bpcbf), [], 'omitnan');
left_max = max(angle(vlf_H_bpcbf), [], 'omitnan');
left_min = min(left_min, 0);
left_max = max(left_max, 0);
if left_min == left_max
    left_min = left_min - 1;
    left_max = left_max + 1;
end

yyaxis right
h_coh = plot(vlf, vlf_bp_cbf_coherence, 'LineWidth', 0.7);
ylabel('Coherence')
right_max = 1.05 * max([1; vlf_bp_cbf_coherence(:)], [], 'omitnan');
alignRightYAxisZero(left_min, left_max, right_max)
legend([h_tf, h_coh], {'Transfer function', 'Coherence'}, 'Location', 'best')

% LF gain
subplot(3,2,3)
yyaxis left
h_tf = stem(lf, abs(lf_H_bpcbf), 'filled');
ylabel('Magnitude')
xlabel('Frequency (Hz)')
title('LF BP to CBF Gain')
grid on
hold on

left_min = min(abs(lf_H_bpcbf), [], 'omitnan');
left_max = max(abs(lf_H_bpcbf), [], 'omitnan');
left_min = min(left_min, 0);
left_max = max(left_max, 0);
if left_min == left_max
    left_min = left_min - 1;
    left_max = left_max + 1;
end

yyaxis right
h_coh = plot(lf, lf_bp_cbf_coherence, 'LineWidth', 0.7);
ylabel('Coherence')
right_max = 1.05 * max([1; lf_bp_cbf_coherence(:)], [], 'omitnan');
alignRightYAxisZero(left_min, left_max, right_max)
legend([h_tf, h_coh], {'Transfer function', 'Coherence'}, 'Location', 'best')

% LF phase
subplot(3,2,4)
yyaxis left
h_tf = stem(lf, angle(lf_H_bpcbf), 'filled');
ylabel('Phase (rad)')
xlabel('Frequency (Hz)')
title('LF BP to CBF Phase')
grid on
hold on

left_min = min(angle(lf_H_bpcbf), [], 'omitnan');
left_max = max(angle(lf_H_bpcbf), [], 'omitnan');
left_min = min(left_min, 0);
left_max = max(left_max, 0);
if left_min == left_max
    left_min = left_min - 1;
    left_max = left_max + 1;
end

yyaxis right
h_coh = plot(lf, lf_bp_cbf_coherence, 'LineWidth', 0.7);
ylabel('Coherence')
right_max = 1.05 * max([1; lf_bp_cbf_coherence(:)], [], 'omitnan');
alignRightYAxisZero(left_min, left_max, right_max)
legend([h_tf, h_coh], {'Transfer function', 'Coherence'}, 'Location', 'best')

% HF gain
subplot(3,2,5)
yyaxis left
h_tf = stem(hf, abs(hf_H_bpcbf), 'filled');
ylabel('Magnitude')
xlabel('Frequency (Hz)')
title('HF BP to CBF Gain')
grid on
hold on

left_min = min(abs(hf_H_bpcbf), [], 'omitnan');
left_max = max(abs(hf_H_bpcbf), [], 'omitnan');
left_min = min(left_min, 0);
left_max = max(left_max, 0);
if left_min == left_max
    left_min = left_min - 1;
    left_max = left_max + 1;
end

yyaxis right
h_coh = plot(hf, hf_bp_cbf_coherence, 'LineWidth', 0.7);
ylabel('Coherence')
right_max = 1.05 * max([1; hf_bp_cbf_coherence(:)], [], 'omitnan');
alignRightYAxisZero(left_min, left_max, right_max)
legend([h_tf, h_coh], {'Transfer function', 'Coherence'}, 'Location', 'best')

% HF phase
subplot(3,2,6)
yyaxis left
h_tf = stem(hf, angle(hf_H_bpcbf), 'filled');
ylabel('Phase (rad)')
xlabel('Frequency (Hz)')
title('HF BP to CBF Phase')
grid on
hold on

left_min = min(angle(hf_H_bpcbf), [], 'omitnan');
left_max = max(angle(hf_H_bpcbf), [], 'omitnan');
left_min = min(left_min, 0);
left_max = max(left_max, 0);
if left_min == left_max
    left_min = left_min - 1;
    left_max = left_max + 1;
end

yyaxis right
h_coh = plot(hf, hf_bp_cbf_coherence, 'LineWidth', 0.7);
ylabel('Coherence')
right_max = 1.05 * max([1; hf_bp_cbf_coherence(:)], [], 'omitnan');
alignRightYAxisZero(left_min, left_max, right_max)
legend([h_tf, h_coh], {'Transfer function', 'Coherence'}, 'Location', 'best')

sgtitle('Partitioned BP to CBF Transfer Function')


%% Partitioned CO2 to CBF with coherence overlay

figure('Name', 'PartitionedSisoCo2ToCbfTransferFunction', 'NumberTitle', 'off')

% VLF gain
subplot(3,2,1)
yyaxis left
h_tf = stem(vlf, abs(vlf_H_co2cbf), 'filled');
ylabel('Magnitude')
xlabel('Frequency (Hz)')
title('VLF CO2 to CBF Gain')
grid on
hold on

left_min = min(abs(vlf_H_co2cbf), [], 'omitnan');
left_max = max(abs(vlf_H_co2cbf), [], 'omitnan');
left_min = min(left_min, 0);
left_max = max(left_max, 0);
if left_min == left_max
    left_min = left_min - 1;
    left_max = left_max + 1;
end

yyaxis right
h_coh = plot(vlf, vlf_co2_cbf_coherence, 'LineWidth', 0.7);
ylabel('Coherence')
right_max = 1.05 * max([1; vlf_co2_cbf_coherence(:)], [], 'omitnan');
alignRightYAxisZero(left_min, left_max, right_max)
legend([h_tf, h_coh], {'Transfer function', 'Coherence'}, 'Location', 'best')

% VLF phase
subplot(3,2,2)
yyaxis left
h_tf = stem(vlf, angle(vlf_H_co2cbf), 'filled');
ylabel('Phase (rad)')
xlabel('Frequency (Hz)')
title('VLF CO2 to CBF Phase')
grid on
hold on

left_min = min(angle(vlf_H_co2cbf), [], 'omitnan');
left_max = max(angle(vlf_H_co2cbf), [], 'omitnan');
left_min = min(left_min, 0);
left_max = max(left_max, 0);
if left_min == left_max
    left_min = left_min - 1;
    left_max = left_max + 1;
end

yyaxis right
h_coh = plot(vlf, vlf_co2_cbf_coherence, 'LineWidth', 0.7);
ylabel('Coherence')
right_max = 1.05 * max([1; vlf_co2_cbf_coherence(:)], [], 'omitnan');
alignRightYAxisZero(left_min, left_max, right_max)
legend([h_tf, h_coh], {'Transfer function', 'Coherence'}, 'Location', 'best')

% LF gain
subplot(3,2,3)
yyaxis left
h_tf = stem(lf, abs(lf_H_co2cbf), 'filled');
ylabel('Magnitude')
xlabel('Frequency (Hz)')
title('LF CO2 to CBF Gain')
grid on
hold on

left_min = min(abs(lf_H_co2cbf), [], 'omitnan');
left_max = max(abs(lf_H_co2cbf), [], 'omitnan');
left_min = min(left_min, 0);
left_max = max(left_max, 0);
if left_min == left_max
    left_min = left_min - 1;
    left_max = left_max + 1;
end

yyaxis right
h_coh = plot(lf, lf_co2_cbf_coherence, 'LineWidth', 0.7);
ylabel('Coherence')
right_max = 1.05 * max([1; lf_co2_cbf_coherence(:)], [], 'omitnan');
alignRightYAxisZero(left_min, left_max, right_max)
legend([h_tf, h_coh], {'Transfer function', 'Coherence'}, 'Location', 'best')

% LF phase
subplot(3,2,4)
yyaxis left
h_tf = stem(lf, angle(lf_H_co2cbf), 'filled');
ylabel('Phase (rad)')
xlabel('Frequency (Hz)')
title('LF CO2 to CBF Phase')
grid on
hold on

left_min = min(angle(lf_H_co2cbf), [], 'omitnan');
left_max = max(angle(lf_H_co2cbf), [], 'omitnan');
left_min = min(left_min, 0);
left_max = max(left_max, 0);
if left_min == left_max
    left_min = left_min - 1;
    left_max = left_max + 1;
end

yyaxis right
h_coh = plot(lf, lf_co2_cbf_coherence, 'LineWidth', 0.7);
ylabel('Coherence')
right_max = 1.05 * max([1; lf_co2_cbf_coherence(:)], [], 'omitnan');
alignRightYAxisZero(left_min, left_max, right_max)
legend([h_tf, h_coh], {'Transfer function', 'Coherence'}, 'Location', 'best')

% HF gain
subplot(3,2,5)
yyaxis left
h_tf = stem(hf, abs(hf_H_co2cbf), 'filled');
ylabel('Magnitude')
xlabel('Frequency (Hz)')
title('HF CO2 to CBF Gain')
grid on
hold on

left_min = min(abs(hf_H_co2cbf), [], 'omitnan');
left_max = max(abs(hf_H_co2cbf), [], 'omitnan');
left_min = min(left_min, 0);
left_max = max(left_max, 0);
if left_min == left_max
    left_min = left_min - 1;
    left_max = left_max + 1;
end

yyaxis right
h_coh = plot(hf, hf_co2_cbf_coherence, 'LineWidth', 0.7);
ylabel('Coherence')
right_max = 1.05 * max([1; hf_co2_cbf_coherence(:)], [], 'omitnan');
alignRightYAxisZero(left_min, left_max, right_max)
legend([h_tf, h_coh], {'Transfer function', 'Coherence'}, 'Location', 'best')

% HF phase
subplot(3,2,6)
yyaxis left
h_tf = stem(hf, angle(hf_H_co2cbf), 'filled');
ylabel('Phase (rad)')
xlabel('Frequency (Hz)')
title('HF CO2 to CBF Phase')
grid on
hold on

left_min = min(angle(hf_H_co2cbf), [], 'omitnan');
left_max = max(angle(hf_H_co2cbf), [], 'omitnan');
left_min = min(left_min, 0);
left_max = max(left_max, 0);
if left_min == left_max
    left_min = left_min - 1;
    left_max = left_max + 1;
end

yyaxis right
h_coh = plot(hf, hf_co2_cbf_coherence, 'LineWidth', 0.7);
ylabel('Coherence')
right_max = 1.05 * max([1; hf_co2_cbf_coherence(:)], [], 'omitnan');
alignRightYAxisZero(left_min, left_max, right_max)
legend([h_tf, h_coh], {'Transfer function', 'Coherence'}, 'Location', 'best')

sgtitle('Partitioned CO2 to CBF Transfer Function')


%% Coherence-filtered H BP -> CBF

coh_filtered_H_bpcbf = filterByCoherence( ...
    H_bpcbf, bp_cbf_coherence, coherence_threshold);

figure('Name', 'CohFilteredSisoBpToCbfTransferFunction', 'NumberTitle', 'off')

subplot(1,2,1)
stem(f, abs(coh_filtered_H_bpcbf), 'filled')
title('BP to CBF Gain')
xlabel('Frequency (Hz)')
ylabel('Magnitude')
xlim([0.02 0.50])
grid on
hold on
addFrequencyBandLines()

subplot(1,2,2)
stem(f, angle(coh_filtered_H_bpcbf), 'filled')
title('BP to CBF Phase')
xlabel('Frequency (Hz)')
ylabel('Phase (rad)')
xlim([0.02 0.50])
grid on
hold on
addFrequencyBandLines()

sgtitle('Coherence Filtered BP to CBF Transfer Function')


%% Coherence-filtered H CO2 -> CBF

coh_filtered_H_co2cbf = filterByCoherence( ...
    H_co2cbf, co2_cbf_coherence, coherence_threshold);

figure('Name', 'CohFilteredSisoCo2ToCbfTransferFunction', 'NumberTitle', 'off')

subplot(1,2,1)
stem(f, abs(coh_filtered_H_co2cbf), 'filled')
title('CO2 to CBF Gain')
xlabel('Frequency (Hz)')
ylabel('Magnitude')
xlim([0.02 0.50])
grid on
hold on
addFrequencyBandLines()

subplot(1,2,2)
stem(f, angle(coh_filtered_H_co2cbf), 'filled')
title('CO2 to CBF Phase')
xlabel('Frequency (Hz)')
ylabel('Phase (rad)')
xlim([0.02 0.50])
grid on
hold on
addFrequencyBandLines()

sgtitle('Coherence Filtered CO2 to CBF Transfer Function')
%% Store results

sisoResults.f = f;


end