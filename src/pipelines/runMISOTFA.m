function misoTFAResults = runMISOTFA(map, co2, cbv, fs)
%
%Assuming Trecord = 300s and fs = 50Hz
%
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

if isempty(coherence_threshold)
    warning('num_windows does not match coherence lookup table. Using default threshold of 0.51.');
    coherence_threshold = 0.51;
end

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
% Should Input-Input Coherence be considered? When Input-Input coherence is
% high, the Transfer Function Matrix is harder to invert.

%% Coherence Plots

% SISO Coherence
map_cbv_coherence = abs(S_mapcbv_smoothed).^2 ./ ...
    real(S_mapmap_smoothed .* S_cbvcbv_smoothed);

co2_cbv_coherence = abs(S_co2cbv_smoothed).^2 ./ ...
    real(S_co2co2_smoothed .* S_cbvcbv_smoothed);

figure('Name', 'MisoCoherenceDiagnostics', 'NumberTitle', 'off')

subplot(2,1,1)
plot(f, map_cbv_coherence, 'LineWidth', 1.0)
hold on
plot(f, co2_cbv_coherence, 'LineWidth', 1.0)
plot(f, multiple_coherence, 'LineWidth', 1.0)
xlabel('Frequency (Hz)')
ylabel('Coherence')
title('Pairwise and Multiple Coherence')
legend('MAP-CBV coherence', 'CO2-CBV coherence', 'Multiple coherence', ...
    'Location', 'best')
xlim([0.005 0.50])
ylim([0 1])
grid on
addFrequencyBandLines()

subplot(2,1,2)
plot(f, partial_coh_map_cbv_given_co2, 'LineWidth', 1.0)
hold on
plot(f, partial_coh_co2_cbv_given_map, 'LineWidth', 1.0)
plot(f, multiple_coherence, 'LineWidth', 1.0)
xlabel('Frequency (Hz)')
ylabel('Coherence')
title('Partial and Multiple Coherence')
legend('MAP-CBV | CO2', 'CO2-CBV | MAP', 'Multiple coherence', ...
    'Location', 'best')
xlim([0.005 0.50])
ylim([0 1])
grid on
addFrequencyBandLines()

sgtitle('MISO Coherence Diagnostics')

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
xlim([0.005 0.50])
grid on

subplot(1,2,2)
stem(f, input_input_phase, 'filled')
title('MAP-CO2 Cross-Spectral Phase')
xlabel('Frequency (Hz)')
ylabel('Phase (rad)')
xlim([0.005 0.50])
grid on

sgtitle('Input-Input Relationship')

%% Condition Number Plot

figure('Name', 'MisoInputMatrixConditionNumber', 'NumberTitle', 'off')

semilogy(f, condition_number, 'LineWidth', 1.2)
xlabel('Frequency (Hz)')
ylabel('Condition Number')
title('Condition Number of MISO Input Matrix')
xlim([0.005 0.50])
grid on
hold on
addFrequencyBandLines()
xlim([0.005 0.50])

%% Band Averages

bandAverages = computeMISOBandAverages( ...
    f, ...
    H_mapcbv, ...
    H_co2cbv, ...
    multiple_coherence, ...
    partial_coh_map_cbv_given_co2, ...
    partial_coh_co2_cbv_given_map, ...
    input_input_coherence, ...
    input_input_phase, ...
    condition_number, ...
    coherence_threshold);

%% Store Results

misoTFAResults.f = f;

misoTFAResults.mapPower = S_mapmap;
misoTFAResults.mapPowerSmooth = S_mapmap_smoothed;
misoTFAResults.co2Power = S_co2co2;
misoTFAResults.co2PowerSmooth = S_co2co2_smoothed;
misoTFAResults.cbvPower = S_cbvcbv;
misoTFAResults.cbvPowerSmooth = S_cbvcbv_smoothed;

misoTFAResults.mapcbvGain = abs(H_mapcbv);
misoTFAResults.mapcbvPhase = angle(H_mapcbv);

misoTFAResults.co2cbvGain = abs(H_co2cbv);
misoTFAResults.co2cbvPhase = angle(H_co2cbv);

misoTFAResults.multCoh = multiple_coherence;
misoTFAResults.partCohMap = partial_coh_map_cbv_given_co2;
misoTFAResults.partCohCo2 = partial_coh_co2_cbv_given_map;

misoTFAResults.ininCoh = input_input_coherence;
misoTFAResults.ininPhase = input_input_phase;

misoTFAResults.condNum = condition_number;

misoTFAResults.bandAverages = bandAverages;

end

