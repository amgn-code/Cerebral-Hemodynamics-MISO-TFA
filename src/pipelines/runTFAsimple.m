function tfaSimpleResults = runTFAsimple(map, co2, cbv, fs)

%% Assuming Trecord = 300s and fs = 50Hz

map_clean = reshape(map, 1, []);
co2_clean = reshape(co2, 1, []);
cbv_clean = reshape(cbv, 1, []);

%% Window Settings for Welch

window_length_s = 128; 
window_overlap = 0.5;

[window, window_overlap_n, fft_length_n, num_windows] = ...
    windowSettings(window_length_s, window_overlap, fs, length(map));


%% Transfer Function Formulation

%{

Input overlap matrix          Transfer functions        Input-output relationships

[ S_bp,bp    S_bp,co2  ]     [ H_bp→cbf  ]      =      [ S_bp,cbf  ]
[ S_co2,bp   S_co2,co2 ]     [ H_co2→cbf ]             [ S_co2,cbf ]

%}

%% Auto & Cross Power Spectra

[S_mapmap, f] = cpsd(map_clean, map_clean, window, window_overlap_n, fft_length_n, fs);
[S_mapco2_conj, ~] = cpsd(map_clean, co2_clean, window, window_overlap_n, fft_length_n, fs);
[S_co2map_conj, ~] = cpsd(co2_clean, map_clean, window, window_overlap_n, fft_length_n, fs);
[S_co2co2, ~] = cpsd(co2_clean, co2_clean, window, window_overlap_n, fft_length_n, fs);

[S_mapcbv_conj, ~] = cpsd(map_clean, cbv_clean, window, window_overlap_n, fft_length_n, fs);
[S_co2cbv_conj, ~] = cpsd(co2_clean, cbv_clean, window, window_overlap_n, fft_length_n, fs);

[S_cbvcbv, ~] = cpsd(cbv_clean, cbv_clean, window, window_overlap_n, fft_length_n, fs);

%% CPSD in MATLAB defined as X(Y*) not (X*)Y

S_mapco2 = conj(S_mapco2_conj);
S_co2map = conj(S_co2map_conj);

S_mapcbv = conj(S_mapcbv_conj);
S_co2cbv = conj(S_co2cbv_conj);

%% Apply triangular smoothing to the cross-spectral densities

triangular_smoothing_window = [0.25,0.5,0.25];

S_mapmap_smoothed = conv(S_mapmap, triangular_smoothing_window, 'same');
S_mapco2_smoothed = conv(S_mapco2, triangular_smoothing_window, 'same');
S_co2map_smoothed = conv(S_co2map, triangular_smoothing_window, 'same');
S_co2co2_smoothed = conv(S_co2co2, triangular_smoothing_window, 'same');
S_mapcbv_smoothed = conv(S_mapcbv, triangular_smoothing_window, 'same');
S_co2cbv_smoothed = conv(S_co2cbv, triangular_smoothing_window, 'same');
S_cbvcbv_smoothed = conv(S_cbvcbv, triangular_smoothing_window, 'same');

%% Coherence Critical Values

num_welch_windows = [3, 4, 5, 6, 7, 8, 9,10, 15, 20, 25];
coherence_critical_vals = [0.51, 0.41, 0.34, 0.29, 0.25, 0.22, 0.20, 0.18, 0.12, 0.09, 0.08];
coherence_threshold = coherence_critical_vals(find(num_windows == num_welch_windows));

%% Solving for MISO System

H_mapcbv = NaN(size(f));
H_co2cbv = NaN(size(f));
multiple_coherence = NaN(size(f));

condition_number = NaN(size(f));

for k = 1:length(f)

    S_xx = [S_mapmap_smoothed(k), S_mapco2_smoothed(k);
            S_co2map_smoothed(k), S_co2co2_smoothed(k)];

    S_xy = [S_mapcbv_smoothed(k);
           S_co2cbv_smoothed(k)];

    condition_number(k) = cond(S_xx);

    %H = inv(S_xx)*S_xy;
    %Better Formulation to reduce Noise
    Eps = 1e-6 * max(diag(S_xx)); % Dynamic safety threshold based on peak power
    H = (S_xx + Eps*eye(2)) \ S_xy; % Robust, regularized matrix division

    H_mapcbv(k) = H(1,1);
    H_co2cbv(k) = H(2,1);

    % Multiple Coherence from Peng
    multiple_coherence(k) = real(H'*S_xx*H) / (S_cbvcbv_smoothed(k));  


end

%% Input Power Thresholding?
%
%
% 
%
%

%% Partial Coherence as Defined by Perreault 

% Needed conjugate spectra
S_cbvco2 = conj(S_co2cbv_smoothed);
S_co2map = conj(S_mapco2_smoothed);

% Residual spectra after removing CO2
S_mapcbv_given_co2 = S_mapcbv_smoothed - ...
    (S_mapco2_smoothed .* S_co2cbv_smoothed) ./ S_co2co2_smoothed;

S_mapmap_given_co2 = S_mapmap_smoothed - ...
    (S_mapco2_smoothed .* S_co2map) ./ S_co2co2_smoothed;

S_cbvcbv_given_co2 = S_cbvcbv_smoothed - ...
    (S_cbvco2 .* S_co2cbv_smoothed) ./ S_co2co2_smoothed;

% Partial coherence: MAP-CBV after removing CO2
partial_coh_map_cbv_given_co2 = abs(S_mapcbv_given_co2).^2 ./ ...
    real(S_mapmap_given_co2 .* S_cbvcbv_given_co2);

% Needed conjugate spectra
S_cbvmap = conj(S_mapcbv_smoothed);
S_mapco2 = conj(S_co2map_smoothed);

% Residual spectra after removing MAP
S_co2cbv_given_map = S_co2cbv_smoothed - ...
    (S_co2map_smoothed .* S_mapcbv_smoothed) ./ S_mapmap_smoothed;

S_co2co2_given_map = S_co2co2_smoothed - ...
    (S_co2map_smoothed .* S_mapco2) ./ S_mapmap_smoothed;

S_cbvcbv_given_map = S_cbvcbv_smoothed - ...
    (S_cbvmap .* S_mapcbv_smoothed) ./ S_mapmap_smoothed;

% Partial coherence: CO2-CBV after removing MAP
partial_coh_co2_cbv_given_map = abs(S_co2cbv_given_map).^2 ./ ...
    real(S_co2co2_given_map .* S_cbvcbv_given_map);

%% Original MISO H Plot w/ Multiple and Partial Coherence Overlayed

plotMISOwCoherence( ...
    f, ...
    H_mapcbv, ...
    multiple_coherence, ...
    partial_coh_map_cbv_given_co2, ...
    'MAP to CBV', ...
    'MisoMapToCbvTransferFunction');

plotMISOwCoherence( ...
    f, ...
    H_co2cbv, ...
    multiple_coherence, ...
    partial_coh_co2_cbv_given_map, ...
    'CO2 to CBV', ...
    'MisoCo2ToCbvTransferFunction');

%% Original MISO H Plot w/ Multiple and Partial Coherence Overlayed & Partitioned into Frequency Bands

plotPartitionedMISOwCoherence( ...
    f, ...
    H_mapcbv, ...
    multiple_coherence, ...
    partial_coh_map_cbv_given_co2, ...
    'MAP to CBV', ...
    'PartitionedMisoMapToCbvTransferFunction');

plotPartitionedMISOwCoherence( ...
    f, ...
    H_co2cbv, ...
    multiple_coherence, ...
    partial_coh_co2_cbv_given_map, ...
    'CO2 to CBV', ...
    'PartitionedMisoCo2ToCbvTransferFunction');

%% Multiple Coherence Filtered Transfer Functions

multcoh_filtered_H_mapcbv = filterByCoherence( ...
    H_mapcbv, multiple_coherence, coherence_threshold);

multcoh_filtered_H_co2cbv = filterByCoherence( ...
    H_co2cbv, multiple_coherence, coherence_threshold);

plotFilteredMISO( ...
    f, ...
    multcoh_filtered_H_mapcbv, ...
    'MAP to CBV', ...
    'Multiple Coherence Filtered', ...
    'MultCohFilteredMisoMapToCbvTransferFunction');

plotFilteredMISO( ...
    f, ...
    multcoh_filtered_H_co2cbv, ...
    'CO2 to CBV', ...
    'Multiple Coherence Filtered', ...
    'MultCohFilteredMisoCo2ToCbvTransferFunction');


%% Partial Coherence Filtered Transfer Functions

partcoh_filtered_H_mapcbv = filterByCoherence( ...
    H_mapcbv, partial_coh_map_cbv_given_co2, coherence_threshold);

partcoh_filtered_H_co2cbv = filterByCoherence( ...
    H_co2cbv, partial_coh_co2_cbv_given_map, coherence_threshold);

plotFilteredMISO( ...
    f, ...
    partcoh_filtered_H_mapcbv, ...
    'MAP to CBV', ...
    'Partial Coherence Filtered', ...
    'PartCohFilteredMisoMapToCbvTransferFunction');

plotFilteredMISO( ...
    f, ...
    partcoh_filtered_H_co2cbv, ...
    'CO2 to CBV', ...
    'Partial Coherence Filtered', ...
    'PartCohFilteredMisoCo2ToCbvTransferFunction'); 

%% End of Results

%% Questions & Discussion
%  
% Should Input Power be considered as another threshold when evaluating
% the Transfer Function?
%
% Should Input-Input Coherence be considered? when Input-Input coherence is
% low, the Transfer Function Matrix is harder to invert.

%% Input-Input Coherence & Spectra Phase Plots to Discuss

input_input_coherence = abs(S_mapco2_smoothed).^2 ./ ...
    real(S_mapmap_smoothed .* S_co2co2_smoothed);

input_input_phase = angle(S_mapco2_smoothed);

figure('Name', 'InputInputCoherenceAndPhase', 'NumberTitle', 'off')

subplot(1,2,1)
stem(f, input_input_coherence, 'filled')
title('MAP-CO2 Input-Input Coherence')
xlabel('Frequency (Hz)')
ylabel('Coherence')
xlim([0.02 0.50])
grid on

subplot(1,2,2)
stem(f, input_input_phase, 'filled')
title('MAP-CO2 Cross-Spectral Phase')
xlabel('Frequency (Hz)')
ylabel('Phase (rad)')
xlim([0.02 0.50])
grid on

sgtitle('Input-Input Relationship')

%% Condition Number Plot

figure('Name', 'MisoInputMatrixConditionNumber', 'NumberTitle', 'off')

semilogy(f, condition_number, 'LineWidth', 1.2)
xlabel('Frequency (Hz)')
ylabel('Condition Number')
title('Condition Number of MISO Input Matrix')
xlim([0.02 0.50])
grid on
hold on
addFrequencyBandLines()
xlim([0.02 0.50])



%{

input_input_coherence = abs(S_mapco2_smoothed).^2 ./ ...
    real(S_mapmap_smoothed .* S_co2co2_smoothed);

figure()
subplot(1,2,1)
stem(f, input_input_coherence)
title('Input-Input Coherence')

subplot(1,2,2)
stem(f, angle(S_mapco2_smoothed))
title('Input-Input Power Phase')


% H MAP -> CBV

figure('Name', 'MisoMapToCbvTransferFunction1', 'NumberTitle', 'off')
subplot(1,2,1)
stem(f, abs(H_mapcbv))
hold on
plot(f, multiple_coherence)
title('MAP to CBV Gain')
xlabel('Frequency (Hz)')
ylabel('Magnitude')
grid on

subplot(1,2,2)
stem(f, angle(H_mapcbv))
hold on
plot(f, multiple_coherence)
title('MAP to CBV Phase')
xlabel('Frequency (Hz)')
ylabel('Phase (rad)')
grid on

sgtitle('MAP to CBV Transfer Function')


% H CO2 -> CBV

figure('Name', 'MisoCo2ToCbvTransferFunction1', 'NumberTitle', 'off')
subplot(1,2,1)
stem(f, abs(H_co2cbv))
hold on
plot(f, multiple_coherence)
title('CO2 to CBV Gain')
xlabel('Frequency (Hz)')
ylabel('Magnitude')
grid on

subplot(1,2,2)
stem(f, angle(H_co2cbv))
hold on
plot(f, multiple_coherence)
title('CO2 to CBV Phase')
xlabel('Frequency (Hz)')
ylabel('Phase (rad)')
grid on

sgtitle('CO2 to CBV Transfer Function')


% vlf, lf, hf partitioned
vlf = f(f>=0.02 & f<=0.07);
lf = f(f>0.07 & f<=0.20);
hf = f(f>0.20 & f<=0.50);

vlf_H_mapcbv = H_mapcbv((f>=0.02 & f<=0.07));
lf_H_mapcbv = H_mapcbv((f>0.07 & f<=0.20));
hf_H_mapcbv = H_mapcbv((f>0.20 & f<=0.50));

vlf_H_co2cbv = H_co2cbv((f>=0.02 & f<=0.07));
lf_H_co2cbv = H_co2cbv((f>0.07 & f<=0.20));
hf_H_co2cbv = H_co2cbv((f>0.20 & f<=0.50));

vlf_multiple_coherence = multiple_coherence(f>=0.02 & f<=0.07);
lf_multiple_coherence = multiple_coherence(f>0.07 & f<=0.20);
hf_multiple_coherence = multiple_coherence(f>0.20 & f<=0.50);


% vlf, lf, hf for MAP to CBV

figure('Name', 'PartitionedMisoMapToCbvTransferFunction', 'NumberTitle', 'off')
subplot(3,2,1)
stem(vlf, abs(vlf_H_mapcbv))
hold on
plot(vlf, vlf_multiple_coherence)
title('VLF MAP to CBV')
xlabel('Frequency (Hz)')
ylabel('Gain')
grid on

subplot(3,2,2)
stem(vlf, angle(vlf_H_mapcbv))
hold on
plot(vlf, vlf_multiple_coherence)
title('VLF MAP to CBV')
xlabel('Frequency (Hz)')
ylabel('Phase (rad)')
grid on

subplot(3,2,3)
stem(lf, abs(lf_H_mapcbv))
hold on
plot(lf, lf_multiple_coherence)
title('LF MAP to CBV')
xlabel('Frequency (Hz)')
ylabel('Gain')
grid on

subplot(3,2,4)
stem(lf, angle(lf_H_mapcbv))
hold on
plot(lf, lf_multiple_coherence)
title('LF MAP to CBV')
xlabel('Frequency (Hz)')
ylabel('Phase (rad)')
grid on

subplot(3,2,5)
stem(hf, abs(hf_H_mapcbv))
hold on
plot(hf, hf_multiple_coherence)
title('HF MAP to CBV')
xlabel('Frequency (Hz)')
ylabel('Gain')
grid on

subplot(3,2,6)
stem(hf, angle(hf_H_mapcbv))
hold on
plot(hf, hf_multiple_coherence)
title('HF MAP to CBV')
xlabel('Frequency (Hz)')
ylabel('Phase (rad)')
grid on

sgtitle('Partitioned MAP to CBV Transfer Function')


% vlf, lf, hf for H CO2 to CBV

figure('Name', 'PartitionedMisoCo2ToCbvTransferFunction', 'NumberTitle', 'off')
subplot(3,2,1)
stem(vlf, abs(vlf_H_co2cbv))
hold on
plot(vlf, vlf_multiple_coherence)
title('VLF CO2 to CBV')
xlabel('Frequency (Hz)')
ylabel('Gain')
grid on

subplot(3,2,2)
stem(vlf, angle(vlf_H_co2cbv))
hold on
plot(vlf, vlf_multiple_coherence)
title('VLF CO2 to CBV')
xlabel('Frequency (Hz)')
ylabel('Phase (rad)')
grid on

subplot(3,2,3)
stem(lf, abs(lf_H_co2cbv))
hold on
plot(lf, lf_multiple_coherence)
title('LF CO2 to CBV')
xlabel('Frequency (Hz)')
ylabel('Gain')
grid on

subplot(3,2,4)
stem(lf, angle(lf_H_co2cbv))
hold on
plot(lf, lf_multiple_coherence)
title('LF CO2 to CBV')
xlabel('Frequency (Hz)')
ylabel('Phase (rad)')
grid on

subplot(3,2,5)
stem(hf, abs(hf_H_co2cbv))
hold on
plot(hf, hf_multiple_coherence)
title('HF CO2 to CBV')
xlabel('Frequency (Hz)')
ylabel('Gain')
grid on

subplot(3,2,6)
stem(hf, angle(hf_H_co2cbv))
hold on
plot(hf, hf_multiple_coherence)
title('HF CO2 to CBV')
xlabel('Frequency (Hz)')
ylabel('Phase (rad)')
grid on

sgtitle('Partitioned CO2 to CBV Transfer Function')

% Multiple Coherence Filtered H MAP -> CBV

multcoh_filtered_H_mapcbv = H_mapcbv;
multcoh_filtered_H_mapcbv(multiple_coherence < coherence_threshold) = NaN;

figure('Name', 'MultCohFilteredMisoMapToCbvTransferFunction', 'NumberTitle', 'off')
subplot(1,2,1)
stem(f, abs(multcoh_filtered_H_mapcbv))
xlabel('Frequency (Hz)')
ylabel('Magnitude')
grid on

subplot(1,2,2)
stem(f, angle(multcoh_filtered_H_mapcbv))
xlabel('Frequency (Hz)')
ylabel('Phase (rad)')
grid on

sgtitle('Filtered MAP to CBV Transfer Function')

% Multiple Coherence Filtered H CO2 -> CBV

multcoh_filtered_H_co2cbv = H_co2cbv;
multcoh_filtered_H_co2cbv(multiple_coherence < coherence_threshold) = NaN;

figure('Name', 'MultCohFilteredMisoCo2ToCbvTransferFunction', 'NumberTitle', 'off')
subplot(1,2,1)
stem(f, abs(multcoh_filtered_H_co2cbv))
xlabel('Frequency (Hz)')
ylabel('Magnitude')
grid on

subplot(1,2,2)
stem(f, angle(multcoh_filtered_H_co2cbv))
xlabel('Frequency (Hz)')
ylabel('Phase (rad)')
grid on

sgtitle('Filtered CO2 to CBV Transfer Function')


% Multiple Coherence Filtered H vlf, lf, hf partitioned

vlf_mult_filtered_H_mapcbv = vlf_H_mapcbv;
lf_mult_filtered_H_mapcbv = lf_H_mapcbv;
hf_mult_filtered_H_mapcbv = hf_H_mapcbv;

vlf_mult_filtered_H_mapcbv(vlf_multiple_coherence < coherence_threshold) = NaN;
lf_mult_filtered_H_mapcbv(lf_multiple_coherence < coherence_threshold) = NaN;
hf_mult_filtered_H_mapcbv(hf_multiple_coherence < coherence_threshold) = NaN;

vlf_mult_filtered_H_co2cbv = vlf_H_co2cbv;
lf_mult_filtered_H_co2cbv = lf_H_co2cbv;
hf_mult_filtered_H_co2cbv = hf_H_co2cbv;

vlf_mult_filtered_H_co2cbv(vlf_multiple_coherence < coherence_threshold) = NaN;
lf_mult_filtered_H_co2cbv(lf_multiple_coherence < coherence_threshold) = NaN;
hf_mult_filtered_H_co2cbv(hf_multiple_coherence < coherence_threshold) = NaN;


% VLF, LF, HF for Multiple Coherence Filtered MAP to CBV

figure('Name', 'PartitionedMultCohFilteredMisoMapToCbvTransferFunction', 'NumberTitle', 'off')

subplot(3,2,1)
stem(vlf, abs(vlf_mult_filtered_H_mapcbv))
title('VLF MAP to CBV')
xlabel('Frequency (Hz)')
ylabel('Gain')
grid on

subplot(3,2,2)
stem(vlf, angle(vlf_mult_filtered_H_mapcbv))
title('VLF MAP to CBV')
xlabel('Frequency (Hz)')
ylabel('Phase (rad)')
grid on

subplot(3,2,3)
stem(lf, abs(lf_mult_filtered_H_mapcbv))
title('LF MAP to CBV')
xlabel('Frequency (Hz)')
ylabel('Gain')
grid on

subplot(3,2,4)
stem(lf, angle(lf_mult_filtered_H_mapcbv))
title('LF MAP to CBV')
xlabel('Frequency (Hz)')
ylabel('Phase (rad)')
grid on

subplot(3,2,5)
stem(hf, abs(hf_mult_filtered_H_mapcbv))
title('HF MAP to CBV')
xlabel('Frequency (Hz)')
ylabel('Gain')
grid on

subplot(3,2,6)
stem(hf, angle(hf_mult_filtered_H_mapcbv))
title('HF MAP to CBV')
xlabel('Frequency (Hz)')
ylabel('Phase (rad)')
grid on

sgtitle('Filtered MAP to CBV Transfer Function')


% VLF, LF, HF for Multiple Coherence Filtered CO2 to CBV

figure('Name', 'PartitionedMultCohFilteredMisoCo2ToCbvTransferFunction', 'NumberTitle', 'off')

subplot(3,2,1)
stem(vlf, abs(vlf_mult_filtered_H_co2cbv))
title('VLF CO2 to CBV')
xlabel('Frequency (Hz)')
ylabel('Gain')
grid on

subplot(3,2,2)
stem(vlf, angle(vlf_mult_filtered_H_co2cbv))
title('VLF CO2 to CBV')
xlabel('Frequency (Hz)')
ylabel('Phase (rad)')
grid on

subplot(3,2,3)
stem(lf, abs(lf_mult_filtered_H_co2cbv))
title('LF CO2 to CBV')
xlabel('Frequency (Hz)')
ylabel('Gain')
grid on

subplot(3,2,4)
stem(lf, angle(lf_mult_filtered_H_co2cbv))
title('LF CO2 to CBV')
xlabel('Frequency (Hz)')
ylabel('Phase (rad)')
grid on

subplot(3,2,5)
stem(hf, abs(hf_mult_filtered_H_co2cbv))
title('HF CO2 to CBV')
xlabel('Frequency (Hz)')
ylabel('Gain')
grid on

subplot(3,2,6)
stem(hf, angle(hf_mult_filtered_H_co2cbv))
title('HF CO2 to CBV')
xlabel('Frequency (Hz)')
ylabel('Phase (rad)')
grid on

sgtitle('Filtered CO2 to CBV Transfer Function')





% H MAP -> CBV

figure('Name', 'MisoMapToCbvTransferFunction2', 'NumberTitle', 'off')
subplot(1,2,1)
stem(f, abs(H_mapcbv))
hold on
plot(f, multiple_coherence)
hold on
plot(f, partial_coh_map_cbv_given_co2)
title('MAP to CBV Gain')
xlabel('Frequency (Hz)')
ylabel('Magnitude')
grid on

subplot(1,2,2)
stem(f, angle(H_mapcbv))
hold on
plot(f, multiple_coherence)
hold on
plot(f, partial_coh_map_cbv_given_co2)
title('MAP to CBV Phase')
xlabel('Frequency (Hz)')
ylabel('Phase (rad)')
grid on

sgtitle('MAP to CBV Transfer Function')


% H CO2 -> CBV

figure('Name', 'MisoCo2ToCbvTransferFunction2', 'NumberTitle', 'off')
subplot(1,2,1)
stem(f, abs(H_co2cbv))
hold on
plot(f, multiple_coherence)
hold on
plot(f, partial_coh_co2_cbv_given_map)
title('CO2 to CBV Gain')
xlabel('Frequency (Hz)')
ylabel('Magnitude')
grid on

subplot(1,2,2)
stem(f, angle(H_co2cbv))
hold on
plot(f, multiple_coherence)
hold on
plot(f, partial_coh_co2_cbv_given_map)
title('CO2 to CBV Phase')
xlabel('Frequency (Hz)')
ylabel('Phase (rad)')
grid on

sgtitle('CO2 to CBV Transfer Function')

% Multiple & Partial Coherence Filtered H MAP -> CBV

multpartcoh_filtered_H_mapcbv = multcoh_filtered_H_mapcbv;
multpartcoh_filtered_H_mapcbv(partial_coh_map_cbv_given_co2 < coherence_threshold) = NaN;

figure('Name', 'FilteredMultPartCohFilteredMisoMapToCbvTransferFunction', 'NumberTitle', 'off')
subplot(1,2,1)
stem(f, abs(multpartcoh_filtered_H_mapcbv))
xlabel('Frequency (Hz)')
ylabel('Magnitude')
grid on

subplot(1,2,2)
stem(f, angle(multpartcoh_filtered_H_mapcbv))
xlabel('Frequency (Hz)')
ylabel('Phase (rad)')
grid on

sgtitle('Multiple & Partial Coherence Filtered MAP to CBV Transfer Function')

% Multiple & Partial Coherence Filtered H CO2 -> CBV

multpartcoh_filtered_H_co2cbv = H_co2cbv;
multpartcoh_filtered_H_co2cbv(partial_coh_co2_cbv_given_map < coherence_threshold) = NaN;

figure('Name', 'FilteredMultPartCohFilteredMisoCo2ToCbvTransferFunction', 'NumberTitle', 'off')
subplot(1,2,1)
stem(f, abs(multpartcoh_filtered_H_co2cbv))
xlabel('Frequency (Hz)')
ylabel('Magnitude')
grid on

subplot(1,2,2)
stem(f, angle(multpartcoh_filtered_H_co2cbv))
xlabel('Frequency (Hz)')
ylabel('Phase (rad)')
grid on

sgtitle('Multiple & Partial Coherence Filtered CO2 to CBV Transfer Function')


% Multiple Coherence Filtered H vlf, lf, hf partitioned

vlf_multpart_filtered_H_mapcbv = multpartcoh_filtered_H_mapcbv(f>=0.02 & f<=0.07);
lf_multpart_filtered_H_mapcbv = multpartcoh_filtered_H_mapcbv(f>0.07 & f<=0.20);
hf_multpart_filtered_H_mapcbv = multpartcoh_filtered_H_mapcbv(f>0.20 & f<=0.50);


vlf_multpart_filtered_H_co2cbv = multpartcoh_filtered_H_co2cbv(f>=0.02 & f<=0.07);
lf_multpart_filtered_H_co2cbv = multpartcoh_filtered_H_co2cbv(f>0.07 & f<=0.20);
hf_multpart_filtered_H_co2cbv = multpartcoh_filtered_H_co2cbv(f>0.20 & f<=0.50);


% VLF, LF, HF for Multiple + Partial Coherence Filtered MAP to CBV

figure('Name', 'PartitionedFilteredMultPartCohFilteredMisoMapToCbvTransferFunction', 'NumberTitle', 'off')

subplot(3,2,1)
stem(vlf, abs(vlf_multpart_filtered_H_mapcbv))
title('VLF MAP to CBV')
xlabel('Frequency (Hz)')
ylabel('Gain')
grid on

subplot(3,2,2)
stem(vlf, angle(vlf_multpart_filtered_H_mapcbv))
title('VLF MAP to CBV')
xlabel('Frequency (Hz)')
ylabel('Phase (rad)')
grid on

subplot(3,2,3)
stem(lf, abs(lf_multpart_filtered_H_mapcbv))
title('LF MAP to CBV')
xlabel('Frequency (Hz)')
ylabel('Gain')
grid on

subplot(3,2,4)
stem(lf, angle(lf_multpart_filtered_H_mapcbv))
title('LF MAP to CBV')
xlabel('Frequency (Hz)')
ylabel('Phase (rad)')
grid on

subplot(3,2,5)
stem(hf, abs(hf_multpart_filtered_H_mapcbv))
title('HF MAP to CBV')
xlabel('Frequency (Hz)')
ylabel('Gain')
grid on

subplot(3,2,6)
stem(hf, angle(hf_multpart_filtered_H_mapcbv))
title('HF MAP to CBV')
xlabel('Frequency (Hz)')
ylabel('Phase (rad)')
grid on

sgtitle('Multiple + Partial Coherence Filtered MAP to CBV Transfer Function')


% VLF, LF, HF for Multiple + Partial Coherence Filtered CO2 to CBV

figure('Name', 'PartitionedFilteredMultPartCohFilteredMisoCo2ToCbvTransferFunction', 'NumberTitle', 'off')

subplot(3,2,1)
stem(vlf, abs(vlf_multpart_filtered_H_co2cbv))
title('VLF CO2 to CBV')
xlabel('Frequency (Hz)')
ylabel('Gain')
grid on

subplot(3,2,2)
stem(vlf, angle(vlf_multpart_filtered_H_co2cbv))
title('VLF CO2 to CBV')
xlabel('Frequency (Hz)')
ylabel('Phase (rad)')
grid on

subplot(3,2,3)
stem(lf, abs(lf_multpart_filtered_H_co2cbv))
title('LF CO2 to CBV')
xlabel('Frequency (Hz)')
ylabel('Gain')
grid on

subplot(3,2,4)
stem(lf, angle(lf_multpart_filtered_H_co2cbv))
title('LF CO2 to CBV')
xlabel('Frequency (Hz)')
ylabel('Phase (rad)')
grid on

subplot(3,2,5)
stem(hf, abs(hf_multpart_filtered_H_co2cbv))
title('HF CO2 to CBV')
xlabel('Frequency (Hz)')
ylabel('Gain')
grid on

subplot(3,2,6)
stem(hf, angle(hf_multpart_filtered_H_co2cbv))
title('HF CO2 to CBV')
xlabel('Frequency (Hz)')
ylabel('Phase (rad)')
grid on

sgtitle('Multiple + Partial Coherence Filtered CO2 to CBV Transfer Function')


%


%}






tfaSimpleResults.f = f;
tfaSimpleResults.mapcbvGain = 





end