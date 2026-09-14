function settings = defaultTfaNumericalSettings()
% defaultTfaNumericalSettings Return settings used by the numerical core.
%
% These settings describe signal preparation and transfer-function
% estimation only. Figures, exports, group statistics, and simulation
% controls belong to their respective interfaces.

    %% Models and Frequency Range

    settings.runMISO = true;
    settings.runSISO = true;
    settings.misoSolver = defaultMisoSolverSettings();
    settings.retainAnalysisInput = false;

    settings.fsTarget = 4;
    settings.frequencyRangeHz = [0 0.35];
    settings.frequencyBandEdgesHz = ...
        [0.005; 0.024; 0.070; 0.200; 0.350];
    settings.frequencyBandNames = ["VVLF"; "VLF"; "LF"; "HF"];

    %% Preprocessing and Welch Spectra

    settings.preprocessing.normalizeCbv = true;
    settings.preprocessing.detrendEnabled = false;
    settings.preprocessing.detrendOrder = 1;
    settings.preprocessing.meanRemovalEnabled = true;
    settings.preprocessing.co2DelayCorrectionSeconds = 0;

    settings.pwelch.windowLengthSeconds = 128;
    settings.pwelch.windowOverlap = 0.5;
    settings.pwelch.minimumWindows = 3;
    settings.pwelch.smoothingEnabled = true;
    settings.pwelch.smoothingKernel = [0.25 0.50 0.25];

    %% Phase

    settings.phase.unwrapMethod = "standard";
    settings.phase.custom.windowSize = 11;
    settings.phase.custom.numPasses = 3;
    settings.phase.custom.useCoherenceWeights = true;
    settings.phase.custom.weightMode = "power";
    settings.phase.custom.weightPower = 4;
    settings.phase.custom.expAlpha = 4;
    settings.phase.custom.minWeight = 0.01;

end
