function report = createFinalMisoTfaReport( ...
    study, ncResults, illustrativeScenario, outputFolder)
% createFinalMisoTfaReport Render the final simulation and NC review PDF.

    if nargin < 4 || strlength(string(outputFolder)) == 0
        project = setup();
        outputFolder = fullfile(project.output, "pdf");
    end
    outputFolder = string(outputFolder);
    if ~exist(outputFolder, "dir")
        mkdir(outputFolder);
    end
    pdfFile = fullfile(outputFolder, "FINAL_MISO_TFA_REPORT.pdf");

    appendWorkflowPage(pdfFile, 1);
    appendFactorPage(study, pdfFile, 2);
    appendMapPage(study.experiments.core.outputs.primaryMaps, ...
        "Primary MAP pathway truth-recovery advantage", pdfFile, 3, 2, 2);
    appendMapPage(study.supplementary.co2Maps, ...
        "Supplementary CO2 pathway truth-recovery advantage", ...
        pdfFile, 4, 2, 2);
    appendMapPage(study.experiments.phase.maps, ...
        "E2: MAP pathway advantage by CO2 lag and input coherence", ...
        pdfFile, 5, 2, 2);
    secondaryMaps = [ ...
        study.experiments.inputNoise.maps; ...
        study.experiments.alignment.maps; ...
        study.experiments.whiteNoise.maps];
    appendMapPage(secondaryMaps, ...
        "E3/E4: measurement-noise and alignment robustness", ...
        pdfFile, 6, 2, 2);
    appendAnalyticErrorPage(study, pdfFile, 7);
    appendNcPage(ncResults, illustrativeScenario, pdfFile, 8);
    appendPrecisionPage(study, pdfFile, 9);

    ncFile = fullfile(outputFolder, "final_nc_frequency_advantage.csv");
    illustrativeFile = fullfile(outputFolder, ...
        "illustrative_nc_protocol_scenario.csv");
    writetable(ncResults.frequencyTable, ncFile);
    writetable(illustrativeScenario.frequencyTable, illustrativeFile);

    report.pdfFile = string(pdfFile);
    report.ncSourceFile = string(ncFile);
    report.illustrativeSourceFile = string(illustrativeFile);
    report.pageCount = 9;
    report.interpretation = ...
        "Simulation truth recovery and NC held-out prediction answer different questions.";

end

function appendWorkflowPage(pdfFile, pageNumber)
% appendWorkflowPage Draw the three project workflows and shared core.

    fig = reportFigure();
    axesHandle = axes(fig, Position=[0 0 1 1], Visible="off");
    title(axesHandle, "MISO-TFA: reproducible study workflow", ...
        Visible="on", FontSize=19, FontWeight="bold", Position=[0.5 0.95 0]);
    drawBox(fig, [0.06 0.64 0.25 0.17], ...
        "User recording" + newline + "connectData -> MISO or SISO", ...
        [0.87 0.93 0.98]);
    drawBox(fig, [0.375 0.64 0.25 0.17], ...
        "Known-truth simulation" + newline + ...
        "core + E2/E3/E4", [0.93 0.90 0.98]);
    drawBox(fig, [0.69 0.64 0.25 0.17], ...
        "NC validation" + newline + ...
        "2 training blocks -> 1 held-out block", [0.90 0.96 0.90]);
    drawBox(fig, [0.20 0.34 0.60 0.16], ...
        "Shared numerical core" + newline + ...
        "preprocessing -> segment-detrended Welch spectra -> SISO/MISO", ...
        [0.95 0.95 0.95]);
    annotation(fig, "arrow", [0.19 0.35], [0.64 0.50]);
    annotation(fig, "arrow", [0.50 0.50], [0.64 0.50]);
    annotation(fig, "arrow", [0.81 0.65], [0.64 0.50]);
    annotation(fig, "textbox", [0.10 0.11 0.80 0.14], ...
        String=[ ...
        "The simulation measures recovery of known conditional pathways. " ...
        "The NC analysis measures prediction on unseen recording blocks. " ...
        "Both use the same estimators, but their accuracy targets are different." + newline + ...
        "The linear generator matches the MISO model by construction; results delineate finite-record tradeoffs and do not prove universal superiority."], ...
        EdgeColor="none", HorizontalAlignment="center", FontSize=12);
    exportReportPage(fig, pdfFile, pageNumber, true);

end

function appendFactorPage(study, pdfFile, pageNumber)
% appendFactorPage Present factor levels, roles, and provenance.

    fig = reportFigure();
    axesHandle = axes(fig, Position=[0.05 0.07 0.90 0.86], Visible="off");
    text(axesHandle, 0, 1, "Final factor design", Units="normalized", ...
        VerticalAlignment="top", FontSize=18, FontWeight="bold");
    lines = [ ...
        "PRIMARY FIGURES"; ...
        "MAP-CO2 coherence: 0, 0.15, 0.50, 0.95"; ...
        "  0 is the independent control; 0.15 is NC-informed; 0.50 and 0.95 are stress levels."; ...
        "CO2-to-MAP pathway gain ratio: 0, 0.25, 1"; ...
        "  Mechanistic levels; contribution is reported as share of separate pathway powers."; ...
        "Recording duration: 300, 600 s"; ...
        "CBFV output SNR: Inf, 10, 0 dB using signal-shaped unexplained output variation"; ...
        ""; ...
        "SECONDARY EXPERIMENTS"; ...
        "E2 input timing: CO2 lag -6, 0, 4 s at coherence 0.15, 0.50, 0.95"; ...
        "E3 input measurement SNR: Inf, 10, 0 dB, varied separately for MAP and CO2"; ...
        "E4 CO2 measurement alignment error: -3, 0, 3 s"; ...
        "Output-noise shape contrast: white noise at 10 and 0 dB"; ...
        ""; ...
        "FIXED"; ...
        "Sampling 4 Hz; reporting 0.02-0.35 Hz; Welch 100 s / 50% overlap / Hann / 3-bin smoothing"; ...
        "CO2 pathway delay 3 s; MAP/CO2 time constants 3/5 s; NC-derived monotonic input spectrum"; ...
        ""; ...
        sprintf("Production: R=%d per condition; 2,000 paired bootstrap draws; target MCSE %.2f log10 units", ...
        study.repetitionsPerCondition, study.precision.targetSE); ...
        "All physiological labels are mechanism settings unless direct NC provenance is stated."];
    y = linspace(0.91, 0.05, numel(lines));
    for index = 1:numel(lines)
        isHeading = ismember(lines(index), ...
            ["PRIMARY FIGURES" "SECONDARY EXPERIMENTS" "FIXED"]);
        text(axesHandle, 0.01, y(index), lines(index), Units="normalized", ...
            Interpreter="none", FontName="Helvetica", FontSize=10.5, ...
            FontWeight=string(choose(isHeading, "bold", "normal")));
    end
    exportReportPage(fig, pdfFile, pageNumber, false);

end

function appendMapPage(maps, pageTitle, pdfFile, pageNumber, rows, columns)
% appendMapPage Draw stored advantage source tables.

    fig = reportFigure();
    layout = tiledlayout(fig, rows, columns, ...
        TileSpacing="compact", Padding="compact");
    layout.OuterPosition = [0.035 0.07 0.93 0.86];
    for mapIndex = 1:numel(maps)
        ax = nexttile(layout);
        drawAdvantageMap(ax, maps(mapIndex));
    end
    title(layout, pageTitle, FontSize=16, FontWeight="bold");
    annotation(fig, "textbox", [0.04 0.005 0.92 0.035], ...
        String="Color = log10(mean SISO error / mean MISO error); positive favors MISO. Gray = insufficient paired N.", ...
        EdgeColor="none", HorizontalAlignment="center", FontSize=9);
    exportReportPage(fig, pdfFile, pageNumber, false);

end

function drawAdvantageMap(ax, map)
% drawAdvantageMap Reconstruct one heatmap from its tidy source table.

    source = map.frequencyTable;
    [matrix, frequencies, labels, valid] = tableToMatrix( ...
        source, "Advantage", "PairedValidN");
    imageHandle = imagesc(ax, frequencies, 1:numel(labels), matrix);
    imageHandle.AlphaData = valid;
    ax.Color = [0.92 0.92 0.92];
    set(ax, YDir="normal", YTick=1:numel(labels), YTickLabel=labels);
    xlim(ax, [min(frequencies) max(frequencies)]);
    colorLimit = map.metadata.ColorLimit(1);
    clim(ax, [-colorLimit colorLimit]);
    colormap(ax, misoAdvantageColormap());
    colorbar(ax);
    xlabel(ax, "Frequency (Hz)");
    ylabel(ax, map.label);
    validN = source.PairedValidN(source.PairedValidN > 0);
    titleText = strrep(map.name, "_", " ");
    if ~isempty(validN)
        titleText = titleText + sprintf(" (N=%d-%d)", ...
            min(validN), max(validN));
    end
    title(ax, titleText, Interpreter="none");

end

function appendAnalyticErrorPage(study, pdfFile, pageNumber)
% appendAnalyticErrorPage Compare analytic bias with finite-record errors.

    maps = study.experiments.core.outputs.primaryMaps(1:2);
    fields = ["AnalyticSISOBiasMean" ...
        "EmpiricalSISOErrorMean" "EmpiricalMISOErrorMean"];
    labels = ["Analytic SISO squared bias" ...
        "Empirical SISO mean squared error" ...
        "Empirical MISO mean squared error"];
    fig = reportFigure();
    layout = tiledlayout(fig, 3, 2, ...
        TileSpacing="compact", Padding="compact");
    layout.OuterPosition = [0.035 0.05 0.93 0.88];
    for fieldIndex = 1:3
        for mapIndex = 1:2
            ax = nexttile(layout);
            source = maps(mapIndex).companions.analyticReference;
            [matrix, frequencies, groups, valid] = tableToMatrix( ...
                source, fields(fieldIndex), "PairedValidN");
            imageHandle = imagesc(ax, frequencies, 1:numel(groups), matrix);
            imageHandle.AlphaData = valid;
            set(ax, YDir="normal", YTick=1:numel(groups), ...
                YTickLabel=groups);
            ax.Color = [0.92 0.92 0.92];
            colormap(ax, parula);
            colorbar(ax);
            xlabel(ax, "Frequency (Hz)");
            ylabel(ax, maps(mapIndex).label);
            title(ax, labels(fieldIndex));
        end
    end
    title(layout, ...
        "Analytic verification: shared truth normalization and paired finite mask", ...
        FontSize=15, FontWeight="bold");
    exportReportPage(fig, pdfFile, pageNumber, false);

end

function appendNcPage(ncResults, illustrative, pdfFile, pageNumber)
% appendNcPage Compare measured and illustrative held-out advantages.

    fig = reportFigure();
    layout = tiledlayout(fig, 2, 1, ...
        TileSpacing="compact", Padding="compact");
    layout.OuterPosition = [0.04 0.07 0.92 0.86];
    nc = ncResults.frequencyTable;
    ax = nexttile(layout);
    fill(ax, [nc.FrequencyHz; flipud(nc.FrequencyHz)], ...
        [nc.CILower; flipud(nc.CIUpper)], [0.80 0.87 0.96], ...
        EdgeColor="none", FaceAlpha=0.8);
    hold(ax, "on");
    plot(ax, nc.FrequencyHz, nc.Advantage, ...
        Color=[0.05 0.30 0.65], LineWidth=1.8);
    yline(ax, 0, "k--");
    hold(ax, "off");
    ylabel(ax, "Held-out advantage");
    title(ax, "NC recordings: pointwise 95% subject-bootstrap intervals");
    grid(ax, "on");

    simulated = illustrative.frequencyTable;
    ax = nexttile(layout);
    fill(ax, [simulated.FrequencyHz; flipud(simulated.FrequencyHz)], ...
        [simulated.CILower; flipud(simulated.CIUpper)], ...
        [0.88 0.83 0.94], EdgeColor="none", FaceAlpha=0.8);
    hold(ax, "on");
    plot(ax, simulated.FrequencyHz, simulated.IllustrativeAdvantage, ...
        Color=[0.45 0.12 0.58], LineWidth=1.8);
    yline(ax, 0, "k--");
    hold(ax, "off");
    xlabel(ax, "Frequency (Hz)");
    ylabel(ax, "Held-out advantage");
    title(ax, "Illustrative 10 dB NC-protocol simulation under stated assumptions");
    grid(ax, "on");
    title(layout, ...
        "Held-out prediction: observed NC result and illustrative mechanism scenario", ...
        FontSize=15, FontWeight="bold");
    annotation(fig, "textbox", [0.05 0.005 0.90 0.04], ...
        String="Both prediction curves use the NC grid beginning at 2/90 = 0.0222 Hz; the simulation heatmaps use 2/100 = 0.02 Hz.", ...
        EdgeColor="none", HorizontalAlignment="center", FontSize=9);
    exportReportPage(fig, pdfFile, pageNumber, false);

end

function appendPrecisionPage(study, pdfFile, pageNumber)
% appendPrecisionPage Summarize achieved primary Monte Carlo precision.

    precision = study.precision;
    tableData = precision.mapTable;
    fig = reportFigure();
    layout = tiledlayout(fig, 2, 1, ...
        TileSpacing="compact", Padding="compact");
    layout.OuterPosition = [0.05 0.07 0.90 0.86];
    ax = nexttile(layout);
    displayNames = strrep(tableData.MapName, "_", " ");
    bar(ax, categorical(displayNames), tableData.MaximumBootstrapSE, ...
        FaceColor=[0.24 0.52 0.72]);
    ax.TickLabelInterpreter = "none";
    yline(ax, precision.targetSE, "r--", "Target MCSE");
    ylabel(ax, "Maximum bootstrap SE");
    title(ax, "Worst frequency cell in each primary map");
    grid(ax, "on");

    ax = nexttile(layout);
    axis(ax, "off");
    status = [ ...
        sprintf("Repetitions per core condition: %d", ...
        precision.currentRepetitions); ...
        sprintf("Maximum primary-cell SE: %.4f log10 units", ...
        precision.maximumSE); ...
        sprintf("Fraction of finite primary cells meeting %.2f: %.1f%%", ...
        precision.targetSE, 100*precision.fractionMeetingTarget); ...
        sprintf("Recommended repetition count from attained SE: %d", ...
        precision.recommendedRepetitions); ...
        sprintf("Predeclared append cap: %d", precision.appendLimit); ...
        "SE is simulation Monte Carlo precision. NC bootstrap SE is sampling uncertainty across subjects."];
    text(ax, 0.08, 0.88, status, Units="normalized", ...
        VerticalAlignment="top", FontSize=13, ...
        FontName="Helvetica", Interpreter="none");
    title(layout, "Production precision audit", ...
        FontSize=16, FontWeight="bold");
    exportReportPage(fig, pdfFile, pageNumber, false);

end

function [matrix, frequencies, labels, valid] = ...
    tableToMatrix(source, valueName, countName)
% tableToMatrix Convert a tidy map table to plotting matrices.

    groups = unique(source.FactorGroup, "stable");
    frequencies = unique(source.FrequencyHz, "stable");
    matrix = NaN(numel(groups), numel(frequencies));
    valid = false(size(matrix));
    for groupIndex = 1:numel(groups)
        rows = source.FactorGroup == groups(groupIndex);
        [found, locations] = ismember( ...
            source.FrequencyHz(rows), frequencies);
        values = source.(valueName)(rows);
        counts = source.(countName)(rows);
        matrix(groupIndex, locations(found)) = values(found);
        valid(groupIndex, locations(found)) = counts(found) > 0 & ...
            isfinite(values(found));
    end
    labels = groups;

end

function fig = reportFigure()
% reportFigure Create one consistent landscape report page.

    fig = figure(Color="white", Visible="off", ...
        Position=[100 100 1200 800]);

end

function drawBox(fig, position, label, color)
% drawBox Add one workflow box.

    annotation(fig, "textbox", position, String=label, ...
        HorizontalAlignment="center", VerticalAlignment="middle", ...
        FontSize=12, FontWeight="bold", BackgroundColor=color, ...
        EdgeColor=[0.35 0.35 0.35], LineWidth=1.2);

end

function exportReportPage(fig, pdfFile, pageNumber, isFirst)
% exportReportPage Add footer and write one PDF page.

    annotation(fig, "textbox", [0.88 0.005 0.08 0.025], ...
        String=sprintf("Page %d", pageNumber), EdgeColor="none", ...
        HorizontalAlignment="right", FontSize=8, Color=[0.35 0.35 0.35]);
    if isFirst
        exportgraphics(fig, pdfFile, ContentType="vector");
    else
        exportgraphics(fig, pdfFile, Append=true, ContentType="vector");
    end
    close(fig);

end

function value = choose(condition, first, second)
% choose Return one of two scalar text values.

    if condition
        value = first;
    else
        value = second;
    end

end
