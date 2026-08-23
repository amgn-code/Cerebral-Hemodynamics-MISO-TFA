function family = createKnownTruthFamily( ...
    familyRow, settings)
% createKnownTruthFamily Generate training and validation baseline signals.

    scenario = familyRowToScenario(familyRow);
    longestDurationSeconds = max([ ...
        settings.observations.durationSeconds(:); ...
        settings.observations.referenceDurationSeconds]);
    familySeed = familyRow.FamilySeed;

    family.familyId = familyRow.FamilyID;
    family.scenarioId = familyRow.ScenarioID;
    family.scenario = scenario;
    family.training = generateKnownTruthRealization( ...
        scenario, settings, familySeed, longestDurationSeconds);
    family.validation = generateKnownTruthRealization( ...
        scenario, settings, familySeed + 1, longestDurationSeconds);

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
    scenario.mapPathwayTimeConstantSeconds = ...
        familyRow.MAPPathwayTimeConstantSeconds;
    scenario.co2PathwayTimeConstantSeconds = ...
        familyRow.CO2PathwayTimeConstantSeconds;

end
