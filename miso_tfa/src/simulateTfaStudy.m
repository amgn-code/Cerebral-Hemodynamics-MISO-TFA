function results = simulateTfaStudy(settings)
% simulateTfaStudy Compare recovery across explicit experimental conditions.
%
% A repetition is a new random recording, not a newly calibrated patient.
% Repetition r uses the same seed in every condition. This holds the random
% sources fixed when a condition changes. Both estimators see each record.
% Training/validation prediction and population selection are not needed.

    simulation = settings.simulation;
    conditions = createSimulationConditions(simulation);
    count = height(conditions);
    repeats = simulation.repetitions;
    analyses = cell(count*repeats, 1);
    summaries = cell(count, 1);
    generator = simulation;
    generator.samplingFrequencyHz = settings.analysis.fsTarget;
    example = [];
    for conditionIndex = 1:count
        condition = table2struct(conditions(conditionIndex, :));
        scenario = generatingScenario(condition);
        errors = struct();
        fprintf("Condition %d/%d: %s (%d repetitions)\n", ...
            conditionIndex, count, condition.label, repeats);
        for repetition = 1:repeats
            seed = simulation.randomSeed + 2*(repetition - 1);
            realization = generateKnownTruthRealization(scenario, generator, ...
                seed, simulation.masterDurationSeconds);
            observed = observeSimulation(realization, condition, simulation, settings.analysis);
            result = analyzeTfaRecording(observed, settings.analysis, observed.truth);
            result.id = "Condition" + conditionIndex + "_Replicate" + repetition;
            result.group = condition.label;
            result.conditionID = conditionIndex;
            result.repetition = repetition;
            analyses{(conditionIndex - 1)*repeats + repetition} = result;
            for pathway = ["map", "co2"]
                for model = ["siso", "miso"]
                    current = calculateFrequencyTruthErrors( ...
                        result.(model).(pathway).transferFunction, ...
                        result.truth.(pathway).transferFunction, 1e-12, ...
                        simulation.phaseMinimumTruthGainFraction);
                    for metric = simulation.metrics
                        if repetition == 1
                            errors.(pathway).(model).(metric) = ...
                                NaN(numel(result.frequencyHz), repeats);
                        end
                        errors.(pathway).(model).(metric)(:, repetition) = current.(metric);
                    end
                end
            end
            if condition.isReference && repetition == 1
                example = observed;
                example.label = condition.label;
                example.seed = seed;
            end
        end
        summary.conditionID = conditionIndex;
        summary.label = condition.label;
        summary.frequencyHz = result.frequencyHz;
        for pathway = ["map", "co2"]
            for metric = simulation.metrics
                summary.(pathway).(metric) = summarizeAdvantage( ...
                    errors.(pathway).siso.(metric), errors.(pathway).miso.(metric), ...
                    simulation.bootstrapSamples, simulation.confidenceLevel, ...
                    simulation.randomSeed + 100000);
            end
        end
        summaries{conditionIndex} = summary;
    end
    results.recordings = vertcat(analyses{:});
    results.groups = summarizeTfaRecordings(results.recordings);
    results.simulation.conditions = conditions;
    results.simulation.advantage = vertcat(summaries{:});
    results.simulation.seeds = simulation.randomSeed + 2*(0:repeats - 1);
    results.example = example;
end

function scenario = generatingScenario(condition)
    scenario.targetInputCoherence = condition.inputCoherence;
    scenario.spectralSimilarityControl = condition.spectralSimilarity;
    scenario.petco2ToMapFluctuationSdRatio = condition.co2FluctuationRatio;
    scenario.petco2ToMapBandGainRatio = condition.co2GainRatio;
    scenario.mapPathwayTimeConstantSeconds = condition.mapTimeConstantSeconds;
    scenario.co2PathwayTimeConstantSeconds = condition.co2TimeConstantSeconds;
    scenario.co2DelaySeconds = condition.co2DelaySeconds;
    scenario.inputPhaseLagSeconds = condition.inputLagSeconds;
end
