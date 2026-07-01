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
    mapRaw = randn(size(t));
    co2Raw = randn(size(t));

    %% Bandpass filter into dCA-ish range
    % Frequency range: 0.01 to 0.5 Hz
    [b,a] = butter(4, [0.01 0.5]/(fs/2), 'bandpass');

    map = filtfilt(b, a, mapRaw);
    co2 = filtfilt(b, a, co2Raw);

    %% Make CO2 independent/orthogonal from MAP
    % This removes the part of CO2 that points in the same direction as MAP.
    % It makes the MISO separation easier for the first test case.
    co2 = co2 - (dot(co2,map)/dot(map,map))*map;

    %% Define true gains
    trueHMap = 0.6;
    trueHCO2 = 0.8;

    %% Create output
    cbv = trueHMap*map + trueHCO2*co2 + 0.05*randn(size(t));

    %% Store results
    signalData.fs = fs;
    signalData.t = t;

    signalData.map = map;
    signalData.co2 = co2;
    signalData.cbv = cbv;

    signalData.mapRaw = mapRaw;
    signalData.co2Raw = co2Raw;

    signalData.trueHMap = trueHMap;
    signalData.trueHCO2 = trueHCO2;

    signalData.description = "Broadband-ish MISO toy signal with independent MAP and CO2 inputs";

end
