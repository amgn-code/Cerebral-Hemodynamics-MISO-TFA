function settings = defaultKnownTruthSimulationSettings(profileName)
% defaultKnownTruthSimulationSettings Create known-truth simulation options.
%
% profileName can be "quick" for code checks and early figures or "paper"
% for the larger final analysis. The paper profile is intentionally large
% and can take a substantial amount of time.

    if nargin < 1
        profileName = "quick";
    end
    profileName = lower(string(profileName));

    settings.profileName = profileName;
    settings.randomSeed = 2026;
    settings.samplingFrequencyHz = 4;
    settings.frequencyRangeHz = [0.005 0.35];

    settings.inputTimeConstantSeconds = 8;
    settings.mapInputSd = 1;
    settings.mapPathwayGain = 1.5;
    settings.mapPathwayTimeConstantSeconds = 2;
    settings.co2PathwayGain = 4;
    settings.co2PathwayTimeConstantSeconds = 5;
    settings.filterDurationTimeConstants = 6;
    settings.burnInSeconds = 120;
    settings.extremeCoefficientThreshold = 25;

    settings.welch.windowLengthSeconds = 100;
    settings.welch.windowOverlap = 0.5;
    settings.welch.minimumWindows = 2;
    settings.welch.smoothingEnabled = true;
    settings.welch.smoothingKernel = [0.25 0.5 0.25];

    settings.phase.unwrapMethod = "standard";
    settings.ridgeLambdas = [0.001 0.01 0.1];

    if profileName == "quick"
        settings.progressEvery = 10;
        settings.numReplicates = 3;
        settings.inputCorrelations = [0 0.8 0.98];
        settings.co2InputSds = [0.15 0.4];
        settings.co2PathwayScales = [0.25 1];
        settings.outputSnrDb = [5 15];
        settings.durationSeconds = [300 900];
        settings.co2DelaysSeconds = 0;
        settings.misspecificationStrengths = 0;
    elseif profileName == "paper"
        settings.progressEvery = 100;
        settings.numReplicates = 50;
        settings.inputCorrelations = ...
            [0 0.3 0.6 0.8 0.9 0.95 0.98];
        settings.co2InputSds = [0.1 0.3 0.8];
        settings.co2PathwayScales = [0.1 0.5 1];
        settings.outputSnrDb = [5 15];
        settings.durationSeconds = [300 900];
        settings.co2DelaysSeconds = 0;
        settings.misspecificationStrengths = 0;
    else
        error( ...
            "TFA:UnknownSimulationProfile", ...
            "Simulation profileName must be ""quick"" or ""paper"".");
    end

end
