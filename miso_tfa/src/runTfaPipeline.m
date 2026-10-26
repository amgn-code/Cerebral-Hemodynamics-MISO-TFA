function results = runTfaPipeline(settings)
% runTfaPipeline Load or simulate recordings, analyze, summarize, plot, save.
%
% All user choices come from runAnalysis.m. There are no backend presets.

    validateTfaSettings(settings);
    if settings.mode == "data"
        recordings = readTfaRecordings(settings.data);
        analyses = cell(numel(recordings), 1);
        for index = 1:numel(recordings)
            prepared = preprocessTfaSignals(recordings(index).signals, ...
                settings.analysis.fsTarget, settings.analysis.preprocessing);
            if settings.analysis.frequencyRangeHz(2) > ...
                    prepared.quality.nativeNyquistFrequencyHz
                error("TFA:NativeNyquist", ...
                    "Reduce frequencyRangeHz: %s was sampled too slowly.", ...
                    recordings(index).id);
            end
            analyses{index} = analyzeTfaRecording(prepared, settings.analysis);
            analyses{index}.id = recordings(index).id;
            analyses{index}.group = recordings(index).group;
            analyses{index}.sourceFile = recordings(index).file;
        end
        results.recordings = vertcat(analyses{:});
        results.groups = summarizeTfaRecordings(results.recordings);
        results.simulation = [];
        results.example = [];
    else
        results = simulateTfaStudy(settings);
    end
    results.settings = settings;
    results.createdAt = datetime("now", TimeZone="UTC");
    results.figures = struct("name", {}, "handle", {});
    if settings.plots.createFigures
        results.figures = plotTfaResults(results, settings.plots);
        if settings.mode == "simulation"
            extra = plotSimulationResults(results, settings);
            results.figures = [results.figures; extra];
        end
    end
    saveTfaResults(results, settings.output);
end
