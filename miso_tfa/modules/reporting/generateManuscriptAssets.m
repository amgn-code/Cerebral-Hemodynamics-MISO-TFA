function manifest = generateManuscriptAssets(finalFolder, manuscriptFolder)
% generateManuscriptAssets Create manuscript figures and tables from saved results.
%
% This function deliberately reads the frozen final-study exports. It does
% not rerun the simulation or change the scientific results. Figures are
% exported as high-resolution PNG files so that the manuscript has one final
% PDF artifact while the MATLAB source remains the figure provenance.

    project = setup();
    if nargin < 1 || strlength(string(finalFolder)) == 0
        finalFolder = fullfile(project.output, "final");
    end
    if nargin < 2 || strlength(string(manuscriptFolder)) == 0
        manuscriptFolder = project.manuscript;
    end

    finalFolder = string(finalFolder);
    manuscriptFolder = string(manuscriptFolder);
    figureFolder = fullfile(manuscriptFolder, "figures");
    tableFolder = fullfile(manuscriptFolder, "tables");
    ensureFolders([manuscriptFolder figureFolder tableFolder]);

    mapFolder = fullfile(finalFolder, "source_tables");
    assertRequiredFiles(finalFolder, mapFolder);

    primaryMapNames = [ ...
        "input_coherence"; ...
        "co2_pathway_ratio"; ...
        "recording_duration"; ...
        "output_snr"];
    co2MapNames = [ ...
        "co2_recovery_input_coherence"; ...
        "co2_recovery_pathway_ratio"; ...
        "co2_recovery_recording_duration"; ...
        "co2_recovery_output_snr"];
    phaseMapNames = [ ...
        "phase_coherence_0.15"; ...
        "phase_coherence_0.5"; ...
        "phase_coherence_0.95"];
    robustnessMapNames = [ ...
        "map_input_noise"; ...
        "co2_input_noise"; ...
        "co2_alignment"; ...
        "white_output_noise"];

    manifestRows = strings(0, 4);

    outputFile = fullfile(figureFolder, "figure1_study_design.png");
    drawStudyDesignFigure(outputFile);
    manifestRows(end + 1, :) = [ ...
        "figure1_study_design.png" "MATLAB" ...
        "Simulation and NC validation workflow" string(outputFile)];

    outputFile = fullfile(figureFolder, "figure2_simulation_replicates.png");
    drawSimulationReplicateFigure(outputFile);
    manifestRows(end + 1, :) = [ ...
        "figure2_simulation_replicates.png" "MATLAB" ...
        "Condition, replicate, observation, and paired-estimate structure" ...
        string(outputFile)];

    outputFile = fullfile(figureFolder, "figure3_nc_input_spectrum.png");
    drawNcInputSpectrumFigure(finalFolder, outputFile);
    manifestRows(end + 1, :) = [ ...
        "figure3_nc_input_spectrum.png" ...
        "nc_validation/nc_input_power_frequency_table.csv" ...
        "NC spectra and fitted simulation input shape" string(outputFile)];

    outputFile = fullfile(figureFolder, "figure2_map_primary_factors.png");
    drawHeatmapFigure(mapFolder, primaryMapNames, ...
        ["MAP-CO2 coherence" "Relative CO2 pathway strength" ...
        "Recording duration" "CBFV output SNR"], ...
        "MAP pathway recovery: one factor varied at a time", outputFile);
    manifestRows(end + 1, :) = [ ...
        "figure2_map_primary_factors.png" "source_tables/*_frequency_map.csv" ...
        "Primary MAP-pathway heatmaps" string(outputFile)];

    outputFile = fullfile(figureFolder, "figure3_co2_primary_factors.png");
    drawHeatmapFigure(mapFolder, co2MapNames, ...
        ["MAP-CO2 coherence" "Relative CO2 pathway strength" ...
        "Recording duration" "CBFV output SNR"], ...
        "CO2 pathway recovery: one factor varied at a time", outputFile);
    manifestRows(end + 1, :) = [ ...
        "figure3_co2_primary_factors.png" "source_tables/co2_recovery_*" ...
        "Primary CO2-pathway heatmaps" string(outputFile)];

    outputFile = fullfile(figureFolder, "figure4_phase_and_robustness.png");
    drawHeatmapFigure(mapFolder, ...
        robustnessMapNames(1:3), ...
        ["MAP recording noise" "CO2 recording noise" ...
        "CO2 recording alignment"], ...
        "Recording sensitivity at the reference test condition", outputFile);
    manifestRows(end + 1, :) = [ ...
        "figure4_phase_and_robustness.png" "source_tables/*_frequency_map.csv" ...
        "MAP noise, CO2 noise, and alignment sensitivity" string(outputFile)];

    outputFile = fullfile(figureFolder, "figure5_nc_validation.png");
    drawNcValidationFigure(finalFolder, outputFile);
    manifestRows(end + 1, :) = [ ...
        "figure5_nc_validation.png" "final_nc_frequency_advantage.csv" ...
        "NC held-out subject-bootstrap result" string(outputFile)];

    outputFile = fullfile(figureFolder, "figure7_phase_levels.png");
    drawHeatmapFigure(mapFolder, phaseMapNames, ...
        ["Input coherence 0.15" "Input coherence 0.50" ...
        "Input coherence 0.95"], ...
        "Phase sensitivity across input coherence levels", outputFile);
    manifestRows(end + 1, :) = [ ...
        "figure7_phase_levels.png" "source_tables/phase_coherence_*" ...
        "Phase sensitivity across all coherence levels" string(outputFile)];

    writeSimulationDesignTable(tableFolder);
    writePrecisionTable(finalFolder, tableFolder);
    writeResultMacros(finalFolder, tableFolder);

    manifestTable = array2table(manifestRows, ...
        'VariableNames', {'Asset', 'Source', 'Description', 'OutputPath'});
    writetable(manifestTable, fullfile(manuscriptFolder, "asset_manifest.csv"));

    manifest.folder = manuscriptFolder;
    manifest.figureFolder = figureFolder;
    manifest.tableFolder = tableFolder;
    manifest.assetTable = manifestTable;
    manifest.generatedAt = datetime("now", TimeZone="UTC");

end

function ensureFolders(folders)
% ensureFolders Create output folders when they do not exist.

    for folderIndex = 1:numel(folders)
        if ~exist(folders(folderIndex), "dir")
            mkdir(folders(folderIndex));
        end
    end

end

function assertRequiredFiles(finalFolder, mapFolder)
% assertRequiredFiles Fail before creating incomplete manuscript assets.

    requiredFiles = [ ...
        fullfile(finalFolder, "final_nc_frequency_advantage.csv"); ...
        fullfile(finalFolder, "final_precision_summary.csv"); ...
        fullfile(finalFolder, "final_run_manifest.csv"); ...
        fullfile(finalFolder, "nc_validation", ...
            "nc_input_power_frequency_table.csv"); ...
        fullfile(mapFolder, "input_coherence_frequency_map.csv"); ...
        fullfile(mapFolder, "co2_pathway_ratio_frequency_map.csv"); ...
        fullfile(mapFolder, "recording_duration_frequency_map.csv"); ...
        fullfile(mapFolder, "output_snr_frequency_map.csv")];
    missingFiles = requiredFiles(~isfile(requiredFiles));
    if ~isempty(missingFiles)
        error("TFA:MissingManuscriptSource", ...
            "Cannot generate manuscript assets. Missing: %s", ...
            strjoin(missingFiles, ", "));
    end

end

function drawStudyDesignFigure(outputFile)
% drawStudyDesignFigure Draw the simulation and NC validation workflows.

    fig = newFigure([1800 1050]);
    annotation(fig, "textbox", [0.05 0.91 0.90 0.06], ...
        String="How the study creates and evaluates transfer functions", ...
        EdgeColor="none", HorizontalAlignment="center", ...
        FontSize=20, FontWeight="bold");

    annotation(fig, "textbox", [0.03 0.82 0.15 0.04], ...
        String="Known-truth simulation", EdgeColor="none", ...
        FontSize=14, FontWeight="bold");
    mainY = 0.62;
    boxWidth = 0.135;
    boxHeight = 0.14;
    boxX = [0.02 0.18 0.34 0.50 0.66 0.82];
    drawWorkflowBox(fig, [boxX(1) mainY boxWidth boxHeight], ...
        "Generate clean\nMAP and CO2", [0.86 0.93 0.99], 12);
    drawWorkflowBox(fig, [boxX(2) mainY boxWidth boxHeight], ...
        "Apply known MAP\nand CO2 pathways", [0.93 0.90 0.99], 12);
    drawWorkflowBox(fig, [boxX(3) mainY boxWidth boxHeight], ...
        "Add pathway\nresponses: clean CBFV", [0.90 0.96 0.90], 12);
    drawWorkflowBox(fig, [boxX(4) mainY boxWidth boxHeight], ...
        "Recorded MAP,\nCO2, and CBFV", [0.91 0.95 0.95], 12);
    drawWorkflowBox(fig, [boxX(5) mainY boxWidth boxHeight], ...
        "Estimate SISO and\nMISO transfer functions", [0.98 0.94 0.84], 12);
    drawWorkflowBox(fig, [boxX(6) mainY boxWidth boxHeight], ...
        "Compare estimates\nwith known pathways", [0.94 0.90 0.97], 12);
    for arrowIndex = 1:(numel(boxX) - 1)
        annotation(fig, "arrow", ...
            [boxX(arrowIndex) + boxWidth, boxX(arrowIndex + 1)], ...
            [mainY + boxHeight/2, mainY + boxHeight/2]);
    end

    drawWorkflowBox(fig, [0.025 0.43 0.13 0.09], ...
        "MAP-CO2 coherence\nand input timing", [0.92 0.96 1.00], 10);
    annotation(fig, "arrow", [0.09 0.09], [0.52 mainY]);
    drawWorkflowBox(fig, [0.185 0.43 0.13 0.09], ...
        "Pathway gains, time\nconstants, and delay", [0.96 0.93 1.00], 10);
    annotation(fig, "arrow", [0.25 0.25], [0.52 mainY]);
    drawWorkflowBox(fig, [0.405 0.43 0.11 0.09], ...
        "CBFV output\nnoise", [0.95 0.97 0.92], 10);
    drawWorkflowBox(fig, [0.525 0.43 0.11 0.09], ...
        "MAP and CO2\nrecording noise", [0.95 0.97 0.92], 10);
    drawWorkflowBox(fig, [0.645 0.43 0.11 0.09], ...
        "CO2 recording\nalignment error", [0.95 0.97 0.92], 10);
    annotation(fig, "arrow", [0.46 0.54], [0.52 mainY]);
    annotation(fig, "arrow", [0.58 0.57], [0.52 mainY]);
    annotation(fig, "arrow", [0.70 0.60], [0.52 mainY]);

    annotation(fig, "textbox", [0.03 0.31 0.15 0.04], ...
        String="NC validation", EdgeColor="none", ...
        FontSize=14, FontWeight="bold");
    ncY = 0.14;
    ncX = [0.08 0.29 0.50 0.71];
    ncWidth = 0.16;
    drawWorkflowBox(fig, [ncX(1) ncY ncWidth 0.11], ...
        "Recorded NC\nMAP, CO2, and CBFV", [0.86 0.93 0.99], 11);
    drawWorkflowBox(fig, [ncX(2) ncY ncWidth 0.11], ...
        "Fit transfer functions\nusing two blocks", [0.98 0.94 0.84], 11);
    drawWorkflowBox(fig, [ncX(3) ncY ncWidth 0.11], ...
        "Predict CBFV in\nthe held-out block", [0.90 0.96 0.90], 11);
    drawWorkflowBox(fig, [ncX(4) ncY ncWidth 0.11], ...
        "Compare held-out\nprediction errors", [0.94 0.90 0.97], 11);
    for arrowIndex = 1:(numel(ncX) - 1)
        annotation(fig, "arrow", ...
            [ncX(arrowIndex) + ncWidth, ncX(arrowIndex + 1)], ...
            [ncY + 0.055, ncY + 0.055]);
    end
    annotation(fig, "textbox", [0.26 0.04 0.48 0.05], ...
        String="Known truth is available only in the simulation branch.", ...
        EdgeColor="none", HorizontalAlignment="center", FontSize=11);
    exportFigure(fig, outputFile);

end

function drawSimulationReplicateFigure(outputFile)
% drawSimulationReplicateFigure Explain the repeated simulation hierarchy.

    fig = newFigure([1650 900]);
    annotation(fig, "textbox", [0.08 0.89 0.84 0.07], ...
        String="From one tested condition to one heatmap row", ...
        EdgeColor="none", HorizontalAlignment="center", ...
        FontSize=20, FontWeight="bold");

    drawWorkflowBox(fig, [0.04 0.65 0.18 0.15], ...
        "One condition\nfixed coherence, pathway\nstrength, and settings", ...
        [0.86 0.93 0.99], 12);
    drawWorkflowBox(fig, [0.30 0.65 0.18 0.15], ...
        "500 replicates\nindependent random seeds", ...
        [0.93 0.90 0.99], 12);
    drawWorkflowBox(fig, [0.56 0.65 0.18 0.15], ...
        "Each replicate\nclean training and\nvalidation signals", ...
        [0.90 0.96 0.90], 12);
    drawWorkflowBox(fig, [0.82 0.65 0.14 0.15], ...
        "Observation variants\nduration, noise,\nor alignment", ...
        [0.91 0.95 0.95], 11);
    annotation(fig, "arrow", [0.22 0.30], [0.725 0.725]);
    annotation(fig, "arrow", [0.48 0.56], [0.725 0.725]);
    annotation(fig, "arrow", [0.74 0.82], [0.725 0.725]);

    drawWorkflowBox(fig, [0.22 0.34 0.20 0.14], ...
        "SISO estimate\nfrom the observation", [0.98 0.94 0.84], 12);
    drawWorkflowBox(fig, [0.58 0.34 0.20 0.14], ...
        "MISO estimate\nfrom the same observation", [0.98 0.94 0.84], 12);
    annotation(fig, "arrow", [0.87 0.68], [0.65 0.48]);
    annotation(fig, "arrow", [0.87 0.32], [0.65 0.48]);

    drawWorkflowBox(fig, [0.31 0.10 0.38 0.13], ...
        "Paired error at every frequency\ncompare both estimates with the same known pathway\nthen average and bootstrap across replicates", ...
        [0.94 0.90 0.97], 12);
    annotation(fig, "arrow", [0.32 0.44], [0.34 0.23]);
    annotation(fig, "arrow", [0.68 0.56], [0.34 0.23]);
    exportFigure(fig, outputFile);

end

function drawNcInputSpectrumFigure(finalFolder, outputFile)
% drawNcInputSpectrumFigure Show the NC data behind the input spectrum.

    sourceFile = fullfile(finalFolder, "nc_validation", ...
        "nc_input_power_frequency_table.csv");
    source = readtable(sourceFile, VariableNamingRule="preserve");
    fitBandHz = [0.033 0.35];
    fitResult = fitNcInputSpectrum(source, fitBandHz);
    frequencyHz = source.FrequencyHz;
    fittedPower = 1./(1 + ...
        (frequencyHz/fitResult.rolloffFrequencyHz).^fitResult.rolloffExponent);
    fittedDb = fitResult.offsetDb + 10*log10(fittedPower);
    combinedMedian = mean([source.MAPPowerMedianDb, ...
        source.CO2PowerMedianDb], 2, "omitnan");

    fig = newFigure([1450 850]);
    axesHandle = axes(fig, Position=[0.10 0.16 0.84 0.72]);
    plot(axesHandle, frequencyHz, source.MAPPowerMedianDb, ...
        LineWidth=1.6, Color=[0.12 0.35 0.70]);
    hold(axesHandle, "on");
    plot(axesHandle, frequencyHz, source.CO2PowerMedianDb, ...
        LineWidth=1.6, Color=[0.72 0.25 0.18]);
    plot(axesHandle, frequencyHz, combinedMedian, "o", ...
        MarkerSize=4, Color=[0.35 0.35 0.35]);
    plot(axesHandle, frequencyHz, fittedDb, "k--", LineWidth=2.0);
    hold(axesHandle, "off");
    grid(axesHandle, "on");
    box(axesHandle, "on");
    xlim(axesHandle, [0.02 0.35]);
    xlabel(axesHandle, "Frequency (Hz)");
    ylabel(axesHandle, "Power spectral density (dB)");
    title(axesHandle, "NC input spectra used to define the simulation shape", ...
        FontSize=17, FontWeight="bold");
    subtitle(axesHandle, sprintf( ...
        "Fit over 0.033-0.35 Hz: f0 = %.4f Hz, exponent = %.4f, RMSE = %.2f dB", ...
        fitResult.rolloffFrequencyHz, fitResult.rolloffExponent, ...
        fitResult.rootMeanSquaredErrorDb), FontSize=11);
    legend(axesHandle, ["MAP median" "CO2 median" ...
        "Mean of the two median spectra" "Fitted simulation shape"], ...
        Location="northeast");
    set(axesHandle, FontSize=11);
    exportFigure(fig, outputFile);

end

function drawHeatmapFigure(mapFolder, mapNames, panelTitles, figureTitle, outputFile)
% drawHeatmapFigure Draw a comparable frequency-by-factor heatmap panel.

    mapNames = string(mapNames(:));
    panelTitles = string(panelTitles(:));
    maps = cell(numel(mapNames), 1);
    maximumValue = 0;
    for mapIndex = 1:numel(mapNames)
        maps{mapIndex} = readMap(mapFolder, mapNames(mapIndex));
        finiteValues = maps{mapIndex}.Advantage(isfinite(maps{mapIndex}.Advantage));
        if ~isempty(finiteValues)
            maximumValue = max(maximumValue, max(abs(finiteValues)));
        end
    end
    colorLimit = max(0.5, ceil(maximumValue * 10) / 10);

    if isscalar(mapNames)
        rows = 1;
        columns = 1;
    elseif numel(mapNames) <= 2
        rows = 1;
        columns = numel(mapNames);
    elseif numel(mapNames) == 3
        rows = 1;
        columns = 3;
    else
        rows = 2;
        columns = 2;
    end
    if numel(mapNames) == 3
        figureSize = [1750 700];
    else
        figureSize = [1450 950];
    end
    fig = newFigure(figureSize);
    layout = tiledlayout(fig, rows, columns, ...
        TileSpacing="compact", Padding="compact");
    title(layout, figureTitle, FontSize=18, FontWeight="bold");
    for mapIndex = 1:numel(maps)
        axesHandle = nexttile(layout);
        drawMapPanel(axesHandle, maps{mapIndex}, panelTitles(mapIndex), colorLimit);
    end
    colormap(fig, misoAdvantageColormap());
    exportFigure(fig, outputFile);

end

function map = readMap(mapFolder, mapName)
% readMap Read one tidy frequency map and its labels.

    map.frequencyTable = readtable(fullfile( ...
        mapFolder, mapName + "_frequency_map.csv"), ...
        VariableNamingRule="preserve");
    metadataFile = fullfile(mapFolder, mapName + "_metadata.csv");
    if isfile(metadataFile)
        map.metadata = readtable(metadataFile, VariableNamingRule="preserve");
    else
        map.metadata = table();
    end
    map.name = mapName;
    map.GroupKey = getGroupKey(map.frequencyTable);
    map.GroupLabels = getGroupLabels(map.frequencyTable, map.GroupKey);
    map.FrequencyHz = map.frequencyTable.FrequencyHz;
    map.Advantage = map.frequencyTable.Advantage;

end

function drawMapPanel(axesHandle, map, panelTitle, colorLimit)
% drawMapPanel Draw one frequency-by-factor advantage map.

    factorGroups = unique(map.GroupKey, "stable");
    frequencies = unique(map.FrequencyHz, "stable");
    values = NaN(numel(factorGroups), numel(frequencies));
    valid = false(size(values));
    for groupIndex = 1:numel(factorGroups)
        rowMask = map.GroupKey == factorGroups(groupIndex);
        [isMember, locations] = ismember( ...
            map.FrequencyHz(rowMask), frequencies);
        currentValues = map.Advantage(rowMask);
        currentCounts = map.frequencyTable.PairedValidN(rowMask);
        values(groupIndex, locations(isMember)) = currentValues(isMember);
        valid(groupIndex, locations(isMember)) = ...
            currentCounts(isMember) > 0 & isfinite(currentValues(isMember));
    end

    imageHandle = imagesc(axesHandle, frequencies, 1:numel(factorGroups), values);
    imageHandle.AlphaData = valid;
    labels = strings(numel(factorGroups), 1);
    for groupIndex = 1:numel(factorGroups)
        labels(groupIndex) = map.GroupLabels(find( ...
            map.GroupKey == factorGroups(groupIndex), 1));
    end
    set(axesHandle, YDir="normal", YTick=1:numel(factorGroups), ...
        YTickLabel=labels, FontSize=9, Box="on");
    axesHandle.Color = [0.92 0.92 0.92];
    axesHandle.CLim = [-colorLimit colorLimit];
    xlim(axesHandle, [0.02 0.35]);
    xticks(axesHandle, [0.02 0.05 0.10 0.20 0.30 0.35]);
    xlabel(axesHandle, "Frequency (Hz)");
    ylabel(axesHandle, "Tested level");
    title(axesHandle, panelTitle, FontSize=11, FontWeight="bold");
    grid(axesHandle, "on");
    colorbarHandle = colorbar(axesHandle);
    colorbarHandle.Label.String = "MISO advantage";

end

function drawNcValidationFigure(finalFolder, outputFile)
% drawNcValidationFigure Draw the measured NC held-out result.

    nc = readtable(fullfile(finalFolder, "final_nc_frequency_advantage.csv"), ...
        VariableNamingRule="preserve");
    fig = newFigure([1350 650]);
    axesHandle = axes(fig, Position=[0.10 0.16 0.84 0.70]);
    drawBootstrapCurve(axesHandle, nc.FrequencyHz, nc.Advantage, ...
        nc.CILower, nc.CIUpper, [0.12 0.35 0.70], ...
        "Held-out prediction in 23 NC recordings");
    xlabel(axesHandle, "Frequency (Hz)");
    ylabel(axesHandle, "MISO advantage");
    subtitle(axesHandle, ...
        "Line: observed mean; shaded region: pointwise 95% subject-bootstrap interval", ...
        FontSize=10);
    exportFigure(fig, outputFile);

end

function drawBootstrapCurve(axesHandle, frequency, estimate, lower, upper, color, titleText)
% drawBootstrapCurve Draw an estimate and pointwise confidence interval.

    patch(axesHandle, [frequency; flipud(frequency)], ...
        [lower; flipud(upper)], color, EdgeColor="none", FaceAlpha=0.18);
    hold(axesHandle, "on");
    plot(axesHandle, frequency, estimate, Color=color, LineWidth=1.8);
    yline(axesHandle, 0, "k--", LineWidth=0.8);
    hold(axesHandle, "off");
    set(axesHandle, FontSize=10, Box="on");
    xlim(axesHandle, [min(frequency) max(frequency)]);
    grid(axesHandle, "on");
    title(axesHandle, titleText, FontSize=11, FontWeight="bold");

end

function groupKey = getGroupKey(source)
% getGroupKey Create a stable grouping key for numeric and text factors.

    rawGroup = source.FactorGroup;
    if isnumeric(rawGroup)
        groupKey = source.FactorValue;
        missingGroup = isnan(groupKey);
        if any(missingGroup)
            groupKey(missingGroup) = rawGroup(missingGroup);
        end
    else
        groupKey = string(rawGroup);
        missingGroup = ismissing(groupKey) | strlength(groupKey) == 0;
        if any(missingGroup) && ismember("FactorValue", source.Properties.VariableNames)
            groupKey(missingGroup) = string(source.FactorValue(missingGroup));
        end
    end

end

function groupLabels = getGroupLabels(source, ~)
% getGroupLabels Create display labels without blank NaN rows.

    rawGroup = source.FactorGroup;
    if isnumeric(rawGroup)
        groupLabels = strings(height(source), 1);
        factorValues = source.FactorValue;
        for rowIndex = 1:height(source)
            currentValue = factorValues(rowIndex);
            if isinf(currentValue)
                groupLabels(rowIndex) = "No noise";
            elseif isnan(currentValue)
                groupLabels(rowIndex) = "Missing";
            else
                groupLabels(rowIndex) = string(currentValue);
            end
        end
    else
        groupLabels = string(rawGroup);
        missingGroup = ismissing(groupLabels) | strlength(groupLabels) == 0;
        if any(missingGroup) && ismember("FactorValue", source.Properties.VariableNames)
            groupLabels(missingGroup) = string(source.FactorValue(missingGroup));
        end
    end

end

function writeSimulationDesignTable(tableFolder)
% writeSimulationDesignTable Write the protocol table used by LaTeX.

    filePath = fullfile(tableFolder, "simulation_design.tex");
    fileIdentifier = fopen(filePath, "w");
    cleanup = onCleanup(@() fclose(fileIdentifier));
    fprintf(fileIdentifier, "\\begin{tabularx}{\\linewidth}{@{}p{0.17\\linewidth}p{0.17\\linewidth}p{0.29\\linewidth}X@{}}\n");
    fprintf(fileIdentifier, "\\toprule\n");
    fprintf(fileIdentifier, "Varied quantity & Tested levels & Other settings held fixed & Basis for levels \\\\\n");
    fprintf(fileIdentifier, "\\midrule\n");
    fprintf(fileIdentifier, "MAP--CO$_2$ coherence & 0, 0.15, 0.50, 0.95 & 300 s; 10 dB CBFV SNR; pathway ratio 1 & 0.15 is NC-informed; 0 is a control; 0.50 and 0.95 are stress levels \\\\\n");
    fprintf(fileIdentifier, "Relative CO$_2$ pathway strength & 0, 0.25, 1 & 300 s; 10 dB CBFV SNR; coherence 0.50 & Mechanistic absent, weaker, and equal-gain conditions \\\\\n");
    fprintf(fileIdentifier, "Recording duration & 300, 600 s & 10 dB CBFV SNR; coherence 0.50; pathway ratio 1 & 300 s reflects the NC recording length; 600 s tests more data \\\\\n");
    fprintf(fileIdentifier, "CBFV output SNR & no noise, 10, 0 dB & 300 s; coherence 0.50; pathway ratio 1 & Chosen clean, moderate, and severe noise conditions \\\\\n");
    fprintf(fileIdentifier, "MAP--CO$_2$ input lag & -6, 0, 4 s & 300 s; 10 dB CBFV SNR; pathway ratio 1; coherence shown separately & Approximate NC lag quantiles, used as sensitivity levels \\\\\n");
    fprintf(fileIdentifier, "MAP input SNR & no noise, 10, 0 dB & CO$_2$ input clean; 300 s; 10 dB CBFV SNR; coherence 0.50; ratio 1 & Chosen recording-quality levels \\\\\n");
    fprintf(fileIdentifier, "CO$_2$ input SNR & no noise, 10, 0 dB & MAP input clean; same reference settings & Chosen recording-quality levels \\\\\n");
    fprintf(fileIdentifier, "CO$_2$ alignment error & -3, 0, 3 s & Both inputs clean; same reference settings & Acquisition robustness check \\\\\n");
    fprintf(fileIdentifier, "\\bottomrule\n");
    fprintf(fileIdentifier, "\\end{tabularx}\n");

end

function writePrecisionTable(finalFolder, tableFolder)
% writePrecisionTable Convert the precision audit to a LaTeX table.

    source = readtable(fullfile(finalFolder, "final_precision_summary.csv"), ...
        VariableNamingRule="preserve");
    filePath = fullfile(tableFolder, "production_precision.tex");
    fileIdentifier = fopen(filePath, "w");
    cleanup = onCleanup(@() fclose(fileIdentifier));
    fprintf(fileIdentifier, "\\begin{tabular}{lrrrr}\n");
    fprintf(fileIdentifier, "\\toprule\n");
    fprintf(fileIdentifier, "Map & Maximum MC SE & Finite cells & Passing cells & Paired N \\\\\n");
    fprintf(fileIdentifier, "\\midrule\n");
    for rowIndex = 1:height(source)
        mapName = strrep(string(source.MapName(rowIndex)), "_", " ");
        fprintf(fileIdentifier, "%s & %.4f & %d & %d & %d--%d \\\\\n", ...
            mapName, source.MaximumBootstrapSE(rowIndex), ...
            source.FiniteCellCount(rowIndex), source.PassingCellCount(rowIndex), ...
            source.MinimumPairedN(rowIndex), source.MaximumPairedN(rowIndex));
    end
    fprintf(fileIdentifier, "\\bottomrule\n");
    fprintf(fileIdentifier, "\\end{tabular}\n");

end

function writeResultMacros(finalFolder, tableFolder)
% writeResultMacros Write exact values used by the Results prose.

    manifest = readtable(fullfile(finalFolder, "final_run_manifest.csv"), ...
        VariableNamingRule="preserve");
    precision = readtable(fullfile(finalFolder, "final_precision_summary.csv"), ...
        VariableNamingRule="preserve");
    nc = readtable(fullfile(finalFolder, "final_nc_frequency_advantage.csv"), ...
        VariableNamingRule="preserve");

    observationRows = manifest.Parameter == "NumObservations";
    totalObservations = sum(str2double(string(manifest.Value(observationRows))));
    outputBootstrapRows = manifest.Parameter == "OutputBootstrapSamples";
    bootstrapSamples = str2double(string(manifest.Value(find( ...
        outputBootstrapRows, 1))));
    maximumSE = max(precision.MaximumBootstrapSE);
    passingFraction = sum(precision.PassingCellCount) / ...
        sum(precision.FiniteCellCount);
    ncSubjects = max(nc.ValidSubjectN);
    ncMinimum = min(nc.Advantage);
    ncMaximum = max(nc.Advantage);
    ncFrequencyCount = height(nc);
    ncNegativeCount = nnz(nc.Advantage < 0);
    ncBelowZeroCount = nnz(nc.CIUpper < 0);
    ncIncludesZeroCount = nnz(nc.CILower <= 0 & nc.CIUpper >= 0);

    filePath = fullfile(tableFolder, "results_values.tex");
    fileIdentifier = fopen(filePath, "w");
    cleanup = onCleanup(@() fclose(fileIdentifier));
    fprintf(fileIdentifier, "%% Generated by generateManuscriptAssets.m.\n");
    fprintf(fileIdentifier, "\\newcommand{\\SimulationTotalAnalyses}{%d}\n", totalObservations);
    fprintf(fileIdentifier, "\\newcommand{\\SimulationBootstrapSamples}{%d}\n", bootstrapSamples);
    fprintf(fileIdentifier, "\\newcommand{\\MaximumMonteCarloSE}{%.4f}\n", maximumSE);
    fprintf(fileIdentifier, "\\newcommand{\\PrimaryPrecisionPassRate}{%.1f\\%%}\n", 100 * passingFraction);
    fprintf(fileIdentifier, "\\newcommand{\\NCSubjectCount}{%d}\n", ncSubjects);
    fprintf(fileIdentifier, "\\newcommand{\\NCAdvantageMinimum}{%.3f}\n", ncMinimum);
    fprintf(fileIdentifier, "\\newcommand{\\NCAdvantageMaximum}{%.3f}\n", ncMaximum);
    fprintf(fileIdentifier, "\\newcommand{\\NCFrequencyCount}{%d}\n", ncFrequencyCount);
    fprintf(fileIdentifier, "\\newcommand{\\NCNegativeCount}{%d}\n", ncNegativeCount);
    fprintf(fileIdentifier, "\\newcommand{\\NCBelowZeroCount}{%d}\n", ncBelowZeroCount);
    fprintf(fileIdentifier, "\\newcommand{\\NCIncludesZeroCount}{%d}\n", ncIncludesZeroCount);

end

function drawWorkflowBox(fig, position, textValue, color, fontSize)
% drawWorkflowBox Add one readable workflow box.

    if nargin < 5
        fontSize = 13;
    end

    annotation(fig, "textbox", position, ...
        String=strsplit(char(textValue), '\\n'), ...
        HorizontalAlignment="center", VerticalAlignment="middle", ...
        FontSize=fontSize, FontWeight="bold", BackgroundColor=color, ...
        EdgeColor=[0.35 0.35 0.35], LineWidth=1.1, Interpreter="none");

end

function fig = newFigure(position)
% newFigure Create a consistent off-screen figure.

    fig = figure(Color="white", Visible="off", Position=[100 100 position]);

end

function exportFigure(fig, outputFile)
% exportFigure Write a high-resolution raster figure and close it.

    exportgraphics(fig, outputFile, Resolution=300);
    close(fig);

end
