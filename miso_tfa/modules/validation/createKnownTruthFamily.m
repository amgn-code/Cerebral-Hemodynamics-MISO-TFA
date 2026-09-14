function family = createKnownTruthFamily( ...
    familyRow, settings)
% createKnownTruthFamily Generate training and validation baseline signals.

    scenario = familyRowToScenario(familyRow);
    if isfield(settings, "generator") && ...
            isfield(settings.generator, "realizationLengthSeconds")
        realizationLengthSeconds = ...
            settings.generator.realizationLengthSeconds;
    else
        % Compatibility fallback for settings saved before the protocol
        % freeze. New settings always declare this length explicitly.
        realizationLengthSeconds = max([ ...
            settings.observations.durationSeconds(:); ...
            settings.observations.referenceDurationSeconds]);
    end
    requiredLengthSeconds = max([ ...
        settings.observations.durationSeconds(:); ...
        settings.observations.referenceDurationSeconds]);
    if realizationLengthSeconds < requiredLengthSeconds
        error("TFA:RealizationLengthTooShort", ...
            "The fixed realization length must cover every observation.");
    end
    familySeed = familyRow.FamilySeed;

    family.familyId = familyRow.FamilyID;
    family.scenarioId = familyRow.ScenarioID;
    family.scenario = scenario;
    family.training = generateKnownTruthRealization( ...
        scenario, settings, familySeed, realizationLengthSeconds);
    family.validation = generateKnownTruthRealization( ...
        scenario, settings, familySeed + 1, realizationLengthSeconds);

end

function scenario = familyRowToScenario(familyRow)
% familyRowToScenario Convert one table row to a readable scenario struct.

    scenario.targetInputCoherence = ...
        familyRow.TargetInputCoherence;
    scenario.spectralSimilarityControl = ...
        familyRow.SpectralSimilarityControl;
    scenario.petco2ToMapFluctuationSdRatio = ...
        familyRow.PETCO2ToMAPFluctuationSDRatio;
    scenario.petco2ToMapBandGainRatio = ...
        familyRow.PETCO2ToMAPBandGainRatio;
    scenario.co2DelaySeconds = familyRow.CO2DelaySeconds;
    scenario.inputPhaseLagSeconds = familyRow.InputPhaseLagSeconds;
    scenario.mapPathwayTimeConstantSeconds = ...
        familyRow.MAPPathwayTimeConstantSeconds;
    scenario.co2PathwayTimeConstantSeconds = ...
        familyRow.CO2PathwayTimeConstantSeconds;

end
