function surrogateResults = runCo2CircularShiftSurrogates( ...
    analysisInput, analysisSettings, surrogateSettings)
% runCo2CircularShiftSurrogates Build an empirical CO2 timing null.
%
% Circular shifting preserves the CO2 samples and total power while
% changing their timing relative to MAP and CBFV. Spectra and both models
% are recomputed after every shift.

    if nargin < 3
        surrogateSettings.numSurrogates = 200;
        surrogateSettings.randomSeed = 2026;
        surrogateSettings.minimumShiftSeconds = 30;
    end

    previousRandomState = rng;
    restoreRandomState = onCleanup(@() rng(previousRandomState));
    rng(surrogateSettings.randomSeed, "twister");

    fs = analysisInput.fs;
    numSamples = numel(analysisInput.co2);
    minimumShiftSamples = round( ...
        surrogateSettings.minimumShiftSeconds*fs);
    maximumShiftSamples = numSamples - minimumShiftSamples;
    if maximumShiftSamples <= minimumShiftSamples
        error( ...
            "TFA:SignalTooShortForSurrogateShift", ...
            ['The retained signal is too short for the requested minimum ' ...
             'circular shift.']);
    end

    allRows = table();
    shiftLog = table();

    for surrogateIndex = 0:surrogateSettings.numSurrogates
        if surrogateIndex == 0
            shiftSamples = 0;
            resultType = "Observed";
        else
            shiftSamples = randi( ...
                [minimumShiftSamples maximumShiftSamples]);
            resultType = "Circular-shift surrogate";
        end

        shiftedCo2 = circularShiftSignal( ...
            analysisInput.co2, shiftSamples);
        comparison = runModelComparisonForSignals( ...
            analysisInput.map, shiftedCo2, analysisInput.cbv, fs, ...
            analysisSettings);
        currentRows = summarizeGainModelComparisonByBand( ...
            comparison, analysisSettings);
        currentRows.SurrogateIndex = repmat( ...
            surrogateIndex, height(currentRows), 1);
        currentRows.ResultType = repmat( ...
            resultType, height(currentRows), 1);
        currentRows.ShiftSamples = repmat( ...
            shiftSamples, height(currentRows), 1);
        currentRows.ShiftSeconds = repmat( ...
            shiftSamples/fs, height(currentRows), 1);
        allRows = [allRows; currentRows];

        shiftLog = [shiftLog; table( ...
            surrogateIndex, resultType, shiftSamples, ...
            shiftSamples/fs, ...
            'VariableNames', { ...
                'SurrogateIndex', 'ResultType', 'ShiftSamples', ...
                'ShiftSeconds'})];
    end

    surrogateResults.summary = allRows;
    surrogateResults.shiftLog = shiftLog;
    surrogateResults.settings = surrogateSettings;

    clear restoreRandomState

end
