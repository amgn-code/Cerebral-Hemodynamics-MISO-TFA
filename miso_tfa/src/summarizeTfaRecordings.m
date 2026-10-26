function groups = summarizeTfaRecordings(recordings)
% summarizeTfaRecordings Summarize participants/replicates within each group.
%
% Gain and coherence use pointwise arithmetic means. Phase uses circular
% means and circular SD. Impulses use arithmetic means. SD describes spread
% between recordings, not uncertainty of the mean. Group TF is stored as a
% complex mean separately; it is not used to redefine mean individual gain.

    labels = unique(string({recordings.group}), "stable");
    groups = cell(numel(labels), 1);
    for groupIndex = 1:numel(labels)
        selected = recordings(string({recordings.group}) == labels(groupIndex));
        group.name = labels(groupIndex);
        group.count = numel(selected);
        group.frequencyHz = selected(1).frequencyHz;
        group.impulseTimeSeconds = selected(1).impulseTimeSeconds;
        group.cbvUnits = selected(1).cbvUnits;
        group.inputUnits = selected(1).inputUnits;
        assert(all(arrayfun(@(r) isequal(r.frequencyHz, group.frequencyHz), selected)), ...
            "TFA:GroupFrequencyGrid", "Recordings in a group must use the same analysis grid.");
        for model = ["siso", "miso"]
            for pathway = ["map", "co2"]
                entries = arrayfun(@(r) r.(model).(pathway), selected);
                group.(model).(pathway).transferFunction = ...
                    mean(cat(2, entries.transferFunction), 2, "omitnan");
                for metric = ["gain", "coherence", "impulse"]
                    group.(model).(pathway).(metric) = ...
                        summarizeValues(cat(2, entries.(metric)), false);
                end
                group.(model).(pathway).phaseDegrees = ...
                    summarizeValues(cat(2, entries.phaseDegrees), true);
            end
        end
        group.inputCoherence = summarizeValues(cat(2, selected.inputCoherence), false);
        group.multipleCoherence = summarizeValues(cat(2, selected.multipleCoherence), false);
        for pathway = ["map", "co2"]
            entries = arrayfun(@(r) r.difference.(pathway), selected);
            group.difference.(pathway).gain = summarizeValues(cat(2, entries.gain), false);
            group.difference.(pathway).phaseDegrees = ...
                summarizeValues(cat(2, entries.phaseDegrees), true);
        end
        group.truth = selected(1).truth;
        groups{groupIndex} = group;
    end
    groups = vertcat(groups{:});
end

function summary = summarizeValues(values, circular)
    values(~isfinite(values)) = NaN;
    summary.validN = sum(isfinite(values), 2);
    if circular
        vectors = exp(1i*deg2rad(values));
        center = mean(vectors, 2, "omitnan");
        summary.mean = rad2deg(angle(center));
        summary.sd = rad2deg(sqrt(-2*log(min(1, abs(center)))));
    else
        summary.mean = mean(values, 2, "omitnan");
        summary.sd = std(values, 0, 2, "omitnan");
    end
    summary.sd(summary.validN < 2) = NaN;
end
