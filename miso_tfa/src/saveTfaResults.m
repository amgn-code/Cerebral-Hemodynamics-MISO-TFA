function saveTfaResults(results, settings)
% saveTfaResults Save one numerical MAT file, readable CSVs, and chosen PNGs.
%
% results.settings inside results.mat is the authoritative rerun configuration.
% Figure handles are excluded. CSV phase values are degrees. Accuracy tables
% include paired counts and Monte Carlo uncertainty, not extra error figures.

    if ~settings.saveMat && ~settings.saveCsv && ~settings.saveFigures
        return
    end
    folder = string(settings.folder);
    assert(strlength(folder) > 0, "TFA:OutputFolder", "Set output.folder before saving.");
    if ~isfolder(folder)
        mkdir(folder);
    end
    figures = results.figures;
    results = rmfield(results, "figures");
    if settings.saveMat
        save(fullfile(folder, "results.mat"), "results", "-v7.3");
    end
    if settings.saveCsv
        recordingTables = cell(numel(results.recordings), 1);
        for index = 1:numel(results.recordings)
            recordingTables{index} = recordingTable(results.recordings(index));
        end
        writetable(vertcat(recordingTables{:}), fullfile(folder, "recordings.csv"));
        groupTables = cell(numel(results.groups), 1);
        for index = 1:numel(results.groups)
            groupTables{index} = groupTable(results.groups(index));
        end
        writetable(vertcat(groupTables{:}), fullfile(folder, "group_summaries.csv"));
        writetable(impulseTable(results), fullfile(folder, "impulses.csv"));
        if ~isempty(results.simulation)
            writetable(results.simulation.conditions, fullfile(folder, "conditions.csv"));
            writetable(advantageTable(results), fullfile(folder, "advantage.csv"));
        end
    end
    if settings.saveFigures
        for index = 1:numel(figures)
            exportgraphics(figures(index).handle, ...
                fullfile(folder, figures(index).name + ".png"), Resolution=180);
        end
    end
    fprintf("Saved results to %s\n", folder);
end

function output = recordingTable(recording)
    n = numel(recording.frequencyHz);
    output = table(repmat(recording.id, n, 1), repmat(recording.group, n, 1), ...
        repmat(recording.conditionID, n, 1), repmat(recording.repetition, n, 1), ...
        recording.frequencyHz, repmat(recording.cbvUnits, n, 1), ...
        VariableNames=["Recording", "Group", "ConditionID", "Repetition", "FrequencyHz", "CBFVUnits"]);
    for pathway = ["map", "co2"]
        prefix = upper(pathway);
        for model = ["siso", "miso"]
            values = recording.(model).(pathway);
            output.(prefix + upper(model) + "Gain") = values.gain;
            output.(prefix + upper(model) + "PhaseDegrees") = values.phaseDegrees;
        end
        output.(prefix + "OrdinaryCoherence") = recording.siso.(pathway).coherence;
        output.(prefix + "PartialCoherence") = recording.miso.(pathway).coherence;
        output.(prefix + "GainDifference") = recording.difference.(pathway).gain;
        output.(prefix + "PhaseDifferenceDegrees") = recording.difference.(pathway).phaseDegrees;
        if ~isempty(recording.truth)
            output.(prefix + "TruthGain") = recording.truth.(pathway).gain;
            output.(prefix + "TruthPhaseDegrees") = recording.truth.(pathway).phaseDegrees;
        end
    end
    output.InputCoherence = recording.inputCoherence;
    output.MultipleCoherence = recording.multipleCoherence;
    output.NormalizedConditionNumber = recording.conditionNumber;
end

function output = groupTable(group)
    n = numel(group.frequencyHz);
    output = table(repmat(group.name, n, 1), repmat(group.count, n, 1), ...
        group.frequencyHz, repmat(group.cbvUnits, n, 1), ...
        VariableNames=["Group", "RecordingCount", "FrequencyHz", "CBFVUnits"]);
    for pathway = ["map", "co2"]
        for model = ["siso", "miso"]
            for metric = ["gain", "phaseDegrees", "coherence"]
                prefix = upper(pathway) + upper(model) + metric;
                summary = group.(model).(pathway).(metric);
                output.(prefix + "Mean") = summary.mean;
                output.(prefix + "SD") = summary.sd;
                output.(prefix + "ValidN") = summary.validN;
            end
        end
        for metric = ["gain", "phaseDegrees"]
            summary = group.difference.(pathway).(metric);
            output.(upper(pathway) + metric + "DifferenceMean") = summary.mean;
            output.(upper(pathway) + metric + "DifferenceSD") = summary.sd;
        end
    end
    output.InputCoherenceMean = group.inputCoherence.mean;
    output.InputCoherenceSD = group.inputCoherence.sd;
    output.MultipleCoherenceMean = group.multipleCoherence.mean;
    output.MultipleCoherenceSD = group.multipleCoherence.sd;
end

function output = impulseTable(results)
    count = numel(results.recordings) + numel(results.groups);
    tables = cell(count, 1);
    for index = 1:count
        average = index > numel(results.recordings);
        if average
            entry = results.groups(index - numel(results.recordings));
            label = entry.name;
            source = "group";
        else
            entry = results.recordings(index);
            label = entry.id;
            source = "recording";
        end
        n = numel(entry.impulseTimeSeconds);
        if average
            groupLabel = entry.name;
        else
            groupLabel = entry.group;
        end
        part = table(repmat(source, n, 1), repmat(label, n, 1), ...
            repmat(groupLabel, n, 1), entry.impulseTimeSeconds, ...
            VariableNames=["Source", "ID", "Group", "LagSeconds"]);
        for pathway = ["map", "co2"]
            for model = ["siso", "miso"]
                prefix = upper(pathway) + upper(model);
                values = entry.(model).(pathway).impulse;
                if average
                    part.(prefix + "Response") = values.mean;
                    part.(prefix + "SD") = values.sd;
                else
                    part.(prefix + "Response") = values;
                    part.(prefix + "SD") = NaN(n, 1);
                end
            end
        end
        tables{index} = part;
    end
    output = vertcat(tables{:});
end

function output = advantageTable(results)
    summaries = results.simulation.advantage;
    tables = cell(numel(summaries), 1);
    for index = 1:numel(summaries)
        summary = summaries(index);
        part = repmat(results.simulation.conditions(index, :), numel(summary.frequencyHz), 1);
        part.FrequencyHz = summary.frequencyHz;
        for pathway = ["map", "co2"]
            for metric = results.settings.simulation.metrics
                values = summary.(pathway).(metric);
                prefix = upper(pathway) + metric;
                part.(prefix + "Advantage") = values.advantage;
                part.(prefix + "ValidPairs") = values.validPairs;
                part.(prefix + "SISOInvalid") = values.sisoInvalid;
                part.(prefix + "MISOInvalid") = values.misoInvalid;
                part.(prefix + "MonteCarloSE") = values.monteCarloSE;
                part.(prefix + "CILower") = values.ciLower;
                part.(prefix + "CIUpper") = values.ciUpper;
                part.(prefix + "BootstrapFiniteFraction") = values.bootstrapFiniteFraction;
            end
        end
        tables{index} = part;
    end
    output = vertcat(tables{:});
end
