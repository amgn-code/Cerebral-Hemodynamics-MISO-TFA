function study = runFinalSimulationStudy( ...
    repetitionsPerCondition, outputSettings)
% runFinalSimulationStudy Run the frozen core and secondary experiments.

    base = defaultKnownTruthSimulationSettings("simple");
    if nargin < 1 || isempty(repetitionsPerCondition)
        repetitionsPerCondition = ...
            base.production.repetitionsPerCondition;
    end
    validateattributes(repetitionsPerCondition, {'numeric'}, ...
        {'scalar', 'integer', 'positive', 'finite'});
    if nargin < 2 || isempty(outputSettings)
        outputSettings = defaultSimulationOutputSettings("off");
        outputSettings.createFigures = false;
        outputSettings.savePng = false;
        outputSettings.saveCsv = false;
        outputSettings.saveMat = false;
    else
        outputSettings = completeSimulationOutputSettings(outputSettings);
    end
    outputSettings.bootstrap.numSamples = ...
        base.production.bootstrapSamples;

    coreSettings = configureExperiment( ...
        base, repetitionsPerCondition, "core");
    core = runKnownTruthSimulationGrid(coreSettings);
    coreOutputs = createSimulationOutputs(core, outputSettings);
    colorLimit = coreOutputs.settings.resolvedAdvantageColorLimit;

    co2Maps = createCoreCo2Maps( ...
        core, colorLimit, outputSettings);

    phaseSettings = configureExperiment( ...
        base, repetitionsPerCondition, "phase");
    phase = runKnownTruthSimulationGrid(phaseSettings);
    phaseMaps = createPhaseMaps( ...
        phase, colorLimit, outputSettings);

    inputNoiseSettings = configureExperiment( ...
        base, repetitionsPerCondition, "inputNoise");
    inputNoise = runKnownTruthSimulationGrid(inputNoiseSettings);
    inputNoiseMaps = createInputNoiseMaps( ...
        inputNoise, colorLimit, outputSettings);

    alignmentSettings = configureExperiment( ...
        base, repetitionsPerCondition, "alignment");
    alignment = runKnownTruthSimulationGrid(alignmentSettings);
    alignmentMap = createAlignmentMap( ...
        alignment, colorLimit, outputSettings);

    whiteNoiseSettings = configureExperiment( ...
        base, repetitionsPerCondition, "whiteNoise");
    whiteNoise = runKnownTruthSimulationGrid(whiteNoiseSettings);
    whiteNoiseMap = createWhiteNoiseMap( ...
        whiteNoise, colorLimit, outputSettings);

    study.schemaVersion = "final-simulation-study-v1";
    study.createdUTC = string(datetime("now", TimeZone="UTC", ...
        Format="yyyy-MM-dd'T'HH:mm:ss'Z'"));
    study.repetitionsPerCondition = repetitionsPerCondition;
    study.outputSettings = outputSettings;
    study.experiments.core.results = core;
    study.experiments.core.outputs = coreOutputs;
    study.experiments.phase.results = phase;
    study.experiments.phase.maps = phaseMaps;
    study.experiments.inputNoise.results = inputNoise;
    study.experiments.inputNoise.maps = inputNoiseMaps;
    study.experiments.alignment.results = alignment;
    study.experiments.alignment.maps = alignmentMap;
    study.experiments.whiteNoise.results = whiteNoise;
    study.experiments.whiteNoise.maps = whiteNoiseMap;
    study.supplementary.co2Maps = co2Maps;
    study.precision = createProductionPrecisionSummary( ...
        coreOutputs.primaryMaps, repetitionsPerCondition, base.production);
    study.claim = ...
        "Controlled linear mechanism study of finite-record conditional pathway recovery.";

end

function settings = configureExperiment(base, repetitions, experimentName)
% configureExperiment Restrict each run to its declared population.

    settings = base;
    settings.families.repetitionsPerCondition = repetitions;
    settings.families.progressEvery = max(1, round(repetitions/10));
    settings.observations.runInputNoiseExperiment = false;
    settings.observations.runAlignmentExperiment = false;
    settings.observations.runWhiteNoiseRobustness = false;

    switch lower(string(experimentName))
        case "core"
            settings.observations.experimentSet = "core";
        case "phase"
            settings.families.targetCoherenceValues = ...
                settings.secondary.phaseCoherenceValues;
            settings.families.petco2ToMapBandGainRatioValues = 1;
            settings.families.inputPhaseLagSecondsValues = ...
                settings.secondary.inputPhaseLagSecondsValues;
            settings.observations.experimentSet = "reference";
        case "inputnoise"
            settings = setReferenceFamilyOnly(settings);
            settings.observations.experimentSet = "inputNoise";
            settings.observations.runInputNoiseExperiment = true;
        case "alignment"
            settings = setReferenceFamilyOnly(settings);
            settings.observations.experimentSet = "alignment";
            settings.observations.runAlignmentExperiment = true;
        case "whitenoise"
            settings = setReferenceFamilyOnly(settings);
            settings.observations.experimentSet = "whiteNoise";
            settings.observations.runWhiteNoiseRobustness = true;
        otherwise
            error("TFA:UnknownFinalExperiment", ...
                "Unknown final experiment: %s", experimentName);
    end

end

function settings = setReferenceFamilyOnly(settings)
% setReferenceFamilyOnly Use the declared stress-reference family.

    settings.families.targetCoherenceValues = ...
        settings.families.referenceTargetInputCoherence;
    settings.families.petco2ToMapBandGainRatioValues = ...
        settings.families.referencePETCO2ToMAPBandGainRatio;
    settings.families.inputPhaseLagSecondsValues = 0;

end

function maps = createCoreCo2Maps(results, colorLimit, outputSettings)
% createCoreCo2Maps Create supplementary CO2 pathway views.

    observations = results.observations;
    main = observations.Experiment == "Main";
    reference = referenceMask(results);
    masks = { ...
        main & observations.DurationSeconds == 300 & ...
            observations.OutputSNRdB == 10 & ...
            observations.AssignedPETCO2ToMAPBandGainRatio == 1; ...
        main & observations.DurationSeconds == 300 & ...
            observations.OutputSNRdB == 10 & ...
            observations.TargetInputCoherence == 0.50; ...
        main & observations.OutputSNRdB == 10 & reference; ...
        main & observations.DurationSeconds == 300 & reference};
    fields = ["TargetInputCoherence" ...
        "AssignedPETCO2ToMAPBandGainRatio" "DurationSeconds" "OutputSNRdB"];
    labels = ["MAP-CO2 input coherence" ...
        "Assigned CO2-to-MAP pathway ratio" ...
        "Recording duration (s)" "CBFV output SNR (dB)"];
    names = ["co2_recovery_input_coherence" ...
        "co2_recovery_pathway_ratio" ...
        "co2_recovery_recording_duration" ...
        "co2_recovery_output_snr"];
    maps = repmat(emptyNamedMap(), 4, 1);
    for mapIndex = 1:4
        maps(mapIndex) = createNamedSimulationMap( ...
            results, masks{mapIndex}, fields(mapIndex), labels(mapIndex), ...
            "co2", names(mapIndex), colorLimit, outputSettings);
    end

end

function maps = createPhaseMaps(results, colorLimit, outputSettings)
% createPhaseMaps Keep phase panels separate by input coherence.

    coherence = results.settings.secondary.phaseCoherenceValues;
    maps = repmat(emptyNamedMap(), numel(coherence), 1);
    for levelIndex = 1:numel(coherence)
        rows = results.observations.Experiment == "Main" & ...
            results.observations.TargetInputCoherence == coherence(levelIndex);
        maps(levelIndex) = createNamedSimulationMap( ...
            results, rows, "InputPhaseLagSeconds", ...
            "CO2 lag relative to MAP (s)", "map", ...
            "phase_coherence_" + string(coherence(levelIndex)), ...
            colorLimit, outputSettings);
    end

end

function maps = createInputNoiseMaps(results, colorLimit, outputSettings)
% createInputNoiseMaps Keep MAP and CO2 measurement noise separate.

    mapRows = results.observations.Experiment == "MAP input noise";
    co2Rows = results.observations.Experiment == "CO2 input noise";
    maps(1,1) = createNamedSimulationMap( ...
        results, mapRows, "MAPInputSNRdB", "MAP input SNR (dB)", ...
        "map", "map_input_noise", colorLimit, outputSettings);
    maps(2,1) = createNamedSimulationMap( ...
        results, co2Rows, "CO2InputSNRdB", "CO2 input SNR (dB)", ...
        "map", "co2_input_noise", colorLimit, outputSettings);

end

function map = createAlignmentMap(results, colorLimit, outputSettings)
% createAlignmentMap Create the acquisition-alignment robustness view.

    rows = results.observations.Experiment == "Alignment";
    map = createNamedSimulationMap( ...
        results, rows, "AlignmentErrorSeconds", ...
        "CO2 measurement alignment error (s)", "map", ...
        "co2_alignment", colorLimit, outputSettings);

end

function map = createWhiteNoiseMap(results, colorLimit, outputSettings)
% createWhiteNoiseMap Create the white-output-noise contrast.

    rows = results.observations.Experiment == "White output noise";
    map = createNamedSimulationMap( ...
        results, rows, "OutputSNRdB", ...
        "White CBFV output SNR (dB)", "map", ...
        "white_output_noise", colorLimit, outputSettings);

end

function mask = referenceMask(results)
% referenceMask Select the declared family-level reference condition.

    observations = results.observations;
    mask = observations.TargetInputCoherence == ...
        results.settings.families.referenceTargetInputCoherence & ...
        observations.AssignedPETCO2ToMAPBandGainRatio == ...
        results.settings.families.referencePETCO2ToMAPBandGainRatio;

end

function map = emptyNamedMap()
% emptyNamedMap Define the named-map schema for preallocation.

    map = struct( ...
        "name", "", "kind", "", "variableName", "", ...
        "label", "", "pathway", "", "figureHandle", [], ...
        "frequencyTable", table(), "metadata", table(), ...
        "companions", struct(), "selectedObservationCount", 0, ...
        "selectedExperiments", strings(0, 1));

end
