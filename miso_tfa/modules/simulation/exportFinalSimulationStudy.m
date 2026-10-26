function exportResults = exportFinalSimulationStudy(study, outputFolder)
% exportFinalSimulationStudy Save final settings, results, and source tables.

    outputFolder = string(outputFolder);
    if ~isscalar(outputFolder) || strlength(outputFolder) == 0
        error("TFA:MissingFinalStudyOutputFolder", ...
            "Provide one output folder.");
    end
    if ~exist(outputFolder, "dir")
        mkdir(outputFolder);
    end
    sourceFolder = fullfile(outputFolder, "source_tables");
    if ~exist(sourceFolder, "dir")
        mkdir(sourceFolder);
    end

    maps = collectMaps(study);
    savedFiles = strings(0, 1);
    mapName = strings(numel(maps), 1);
    pathway = strings(numel(maps), 1);
    factor = strings(numel(maps), 1);
    selectedObservationCount = zeros(numel(maps), 1);
    selectedExperiments = strings(numel(maps), 1);
    selectionDescription = strings(numel(maps), 1);
    for mapIndex = 1:numel(maps)
        current = maps{mapIndex};
        mapName(mapIndex) = current.name;
        pathway(mapIndex) = getMapPathway(current);
        factor(mapIndex) = current.variableName;
        [selectedObservationCount(mapIndex), ...
            selectedExperiments(mapIndex), ...
            selectionDescription(mapIndex)] = getMapSelection(current);
        fileStem = fullfile(sourceFolder, current.name);
        frequencyFile = fileStem + "_frequency_map.csv";
        metadataFile = fileStem + "_metadata.csv";
        writetable(current.frequencyTable, frequencyFile);
        metadata = addMapIdentity(current.metadata, current);
        writetable(metadata, metadataFile);
        savedFiles(end + 1,1) = frequencyFile; %#ok<AGROW>
        savedFiles(end + 1,1) = metadataFile; %#ok<AGROW>
        if isfield(current, "companions") && ...
                isfield(current.companions, "analyticReference")
            analyticFile = fileStem + "_analytic_errors.csv";
            snrFile = fileStem + "_realized_output_snr.csv";
            writetable(current.companions.analyticReference, analyticFile);
            writetable(current.companions.realizedOutputSnr, snrFile);
            savedFiles(end + 1,1) = analyticFile; %#ok<AGROW>
            savedFiles(end + 1,1) = snrFile; %#ok<AGROW>
        end
    end

    mapIndexTable = table( ...
        mapName, pathway, factor, selectedObservationCount, ...
        selectedExperiments, selectionDescription, ...
        VariableNames=["MapName" "Pathway" "Factor" ...
        "SelectedObservationCount" "SelectedExperiments" ...
        "SelectionDescription"]);
    mapIndexFile = fullfile(outputFolder, "final_map_index.csv");
    precisionFile = fullfile(outputFolder, "final_precision_summary.csv");
    manifestFile = fullfile(outputFolder, "final_run_manifest.csv");
    writetable(mapIndexTable, mapIndexFile);
    writetable(study.precision.mapTable, precisionFile);
    manifest = createFinalManifest(study);
    writetable(manifest.summary, manifestFile);
    savedFiles(end + 1,1) = string(mapIndexFile);
    savedFiles(end + 1,1) = string(precisionFile);
    savedFiles(end + 1,1) = string(manifestFile);

    studyForSave = removeStudyFigureHandles(study);
    resultFile = fullfile(outputFolder, "final_simulation_study.mat");
    save(resultFile, "studyForSave", "manifest", "-v7.3");
    savedFiles(end + 1,1) = string(resultFile);

    exportResults.outputFolder = outputFolder;
    exportResults.sourceFolder = string(sourceFolder);
    exportResults.mapIndex = mapIndexTable;
    exportResults.savedFiles = savedFiles;
    exportResults.resultFile = string(resultFile);
    exportResults.precisionFile = string(precisionFile);
    exportResults.manifestFile = string(manifestFile);

end

function metadata = addMapIdentity(metadata, map)
% addMapIdentity Attach the row-selection contract to map metadata.

    [selectedCount, selectedExperimentNames, selectionDescription] = ...
        getMapSelection(map);
    metadata.MapName = string(map.name);
    metadata.MapLabel = string(map.label);
    metadata.SelectedObservationCount = selectedCount;
    metadata.SelectedExperiments = selectedExperimentNames;
    metadata.SelectionDescription = selectionDescription;
    metadata = movevars(metadata, ...
        ["MapName" "MapLabel" "SelectedObservationCount" ...
        "SelectedExperiments" "SelectionDescription"], "Before", 1);

end

function [selectedCount, selectedExperiments, description] = ...
    getMapSelection(map)
% getMapSelection Return selection metadata for factor or diagnostic maps.

    selectedCount = NaN;
    selectedExperiments = "Main";
    description = getSelectionDescription(string(map.name));
    if isfield(map, "selectedObservationCount")
        selectedCount = map.selectedObservationCount;
    elseif ismember("GroupN", ...
            string(map.frequencyTable.Properties.VariableNames))
        firstFrequency = map.frequencyTable.FrequencyHz(1);
        firstFrequencyRows = ...
            map.frequencyTable.FrequencyHz == firstFrequency;
        selectedCount = sum( ...
            map.frequencyTable.GroupN(firstFrequencyRows));
    end
    if isfield(map, "selectedExperiments")
        selectedExperiments = strjoin( ...
            string(map.selectedExperiments), "; ");
    end

end

function description = getSelectionDescription(mapName)
% getSelectionDescription Explain conditions held fixed for each map.

    switch mapName
        case {"input_coherence", "co2_recovery_input_coherence"}
            description = ...
                "Duration 300 s; output SNR 10 dB; pathway ratio 1";
        case {"co2_pathway_ratio", "co2_recovery_pathway_ratio"}
            description = ...
                "Duration 300 s; output SNR 10 dB; input coherence 0.50";
        case {"recording_duration", "co2_recovery_recording_duration"}
            description = ...
                "Output SNR 10 dB; input coherence 0.50; pathway ratio 1";
        case {"output_snr", "co2_recovery_output_snr"}
            description = ...
                "Duration 300 s; input coherence 0.50; pathway ratio 1";
        case {"miso_minus_map_pairwise_coherence", ...
                "miso_minus_map_partial_coherence"}
            description = ...
                "Duration 300 s; output SNR 10 dB; coherence 0.50; pathway ratio 1";
        otherwise
            description = "Named experiment reference slice; see final manifest";
    end

end

function manifest = createFinalManifest(study)
% createFinalManifest Combine one reproducibility manifest per experiment.

    experimentNames = ["core" "phase" "inputNoise" ...
        "alignment" "whiteNoise"];
    results = { ...
        study.experiments.core.results; ...
        study.experiments.phase.results; ...
        study.experiments.inputNoise.results; ...
        study.experiments.alignment.results; ...
        study.experiments.whiteNoise.results};
    maps = { ...
        study.experiments.core.outputs.maps; ...
        study.experiments.phase.maps; ...
        study.experiments.inputNoise.maps; ...
        study.experiments.alignment.maps; ...
        study.experiments.whiteNoise.maps};
    summaries = cell(numel(experimentNames), 1);
    experimentManifests = cell(numel(experimentNames), 1);
    for experimentIndex = 1:numel(experimentNames)
        current = createSimulationRunManifest( ...
            results{experimentIndex}, study.outputSettings, ...
            maps{experimentIndex});
        summary = current.summary;
        summary.Experiment = repmat( ...
            experimentNames(experimentIndex), height(summary), 1);
        summary = movevars(summary, "Experiment", "Before", 1);
        summaries{experimentIndex} = summary;
        experimentManifests{experimentIndex} = current;
    end
    manifest.schemaVersion = "final-simulation-manifest-v1";
    manifest.summary = vertcat(summaries{:});
    manifest.experiments = experimentManifests;

end

function maps = collectMaps(study)
% collectMaps Return every source-table map in report order.

    maps = cell(0, 1);
    maps = appendMaps(maps, study.experiments.core.outputs.primaryMaps);
    maps = appendMaps(maps, study.supplementary.co2Maps);
    maps = appendMaps(maps, study.experiments.phase.maps);
    maps = appendMaps(maps, study.experiments.inputNoise.maps);
    maps = appendMaps(maps, study.experiments.alignment.maps);
    maps = appendMaps(maps, study.experiments.whiteNoise.maps);
    maps = appendMaps(maps, study.experiments.core.outputs.diagnosticMaps);

end

function maps = appendMaps(maps, additions)
% appendMaps Append a structure array as cells.

    for index = 1:numel(additions)
        maps{end + 1,1} = additions(index); %#ok<AGROW>
    end

end

function pathway = getMapPathway(map)
% getMapPathway Read the pathway from named or primary map metadata.

    pathway = "map";
    if isfield(map, "pathway") && strlength(map.pathway) > 0
        pathway = string(map.pathway);
    elseif ~isempty(map.metadata) && ...
            ismember("Pathway", string(map.metadata.Properties.VariableNames))
        pathway = string(map.metadata.Pathway(1));
    end

end

function study = removeStudyFigureHandles(study)
% removeStudyFigureHandles Keep the archive numeric and portable.

    study.experiments.core.outputs = stripOutputs( ...
        study.experiments.core.outputs);
    study.supplementary.co2Maps = stripMaps(study.supplementary.co2Maps);
    study.experiments.phase.maps = stripMaps(study.experiments.phase.maps);
    study.experiments.inputNoise.maps = stripMaps( ...
        study.experiments.inputNoise.maps);
    study.experiments.alignment.maps = stripMaps( ...
        study.experiments.alignment.maps);
    study.experiments.whiteNoise.maps = stripMaps( ...
        study.experiments.whiteNoise.maps);

end

function outputs = stripOutputs(outputs)
% stripOutputs Remove all handles from the core output structure.

    outputs.maps = stripMaps(outputs.maps);
    outputs.primaryMaps = stripMaps(outputs.primaryMaps);
    outputs.diagnosticMaps = stripMaps(outputs.diagnosticMaps);

end

function maps = stripMaps(maps)
% stripMaps Remove figure handles from a map array.

    for index = 1:numel(maps)
        maps(index).figureHandle = [];
    end

end
