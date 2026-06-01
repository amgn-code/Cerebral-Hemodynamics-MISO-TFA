function signalData = createBroadbandMisoToySignal()
% createBroadbandMisoToySignal
%
% Creates a broadband-ish two-input, one-output toy signal for testing
% the MISO transfer function pipeline.
%
% Inputs:
%   none
%
% Outputs:
%   signalData - struct containing time, sampling rate, inputs, output,
%                and known true gains

    %% Sampling setup
    fs = 4;
    t = (0:1/fs:600)';   % column vector

    rng(1);

    %% Create random raw inputs
    bp_raw = randn(size(t));
    co2_raw = randn(size(t));

    %% Bandpass filter into dCA-ish range
    % Frequency range: 0.01 to 0.5 Hz
    [b,a] = butter(4, [0.01 0.5]/(fs/2), 'bandpass');

    bp = filtfilt(b, a, bp_raw);
    co2 = filtfilt(b, a, co2_raw);

    %% Make CO2 independent/orthogonal from BP
    % This removes the part of CO2 that points in the same direction as BP.
    % It makes the MISO separation easier for the first test case.
    co2 = co2 - (dot(co2,bp)/dot(bp,bp))*bp;

    %% Define true gains
    true_H_BP = 0.6;
    true_H_CO2 = 0.8;

    %% Create output
    cbf = true_H_BP*bp + true_H_CO2*co2 + 0.05*randn(size(t));

    %% Store results
    signalData.fs = fs;
    signalData.t = t;

    signalData.bp = bp;
    signalData.co2 = co2;
    signalData.cbf = cbf;

    signalData.bp_raw = bp_raw;
    signalData.co2_raw = co2_raw;

    signalData.true_H_BP = true_H_BP;
    signalData.true_H_CO2 = true_H_CO2;

    signalData.description = "Broadband-ish MISO toy signal with independent BP and CO2 inputs";

end