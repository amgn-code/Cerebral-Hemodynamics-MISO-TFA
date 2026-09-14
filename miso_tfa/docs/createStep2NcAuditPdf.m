function outputFile = createStep2NcAuditPdf(results, outputFolder)
% createStep2NcAuditPdf Create the visual Step 2 NC audit report.

    if nargin < 1 || isempty(results) || ...
            ~isfield(results, "inputCharacterization")
        error("TFA:MissingNcAuditResults", ...
            "Provide results returned by ncBootstrap.");
    end
    if nargin < 2 || isempty(outputFolder)
        outputFolder = fullfile(fileparts(fileparts(mfilename("fullpath"))), ...
            "output", "pdf");
    end
    outputFolder = string(outputFolder);
    if ~exist(outputFolder, "dir")
        mkdir(outputFolder);
    end

    characterization = results.inputCharacterization;
    figureHandle = figure( ...
        "Visible", "off", "Color", "white", ...
        "Position", [100 100 1400 900]);
    tiled = tiledlayout(figureHandle, 2, 2, ...
        "TileSpacing", "compact", "Padding", "compact");
    title(tiled, "Step 2 NC input audit - 23 usable NC recordings", ...
        "FontSize", 16, "FontWeight", "bold");

    coherenceTable = characterization.coherence.frequencyTable;
    nexttile;
    fill([coherenceTable.FrequencyHz; flipud(coherenceTable.FrequencyHz)], ...
        [coherenceTable.MeanCoherence - coherenceTable.SDCoherence; ...
        flipud(coherenceTable.MeanCoherence + coherenceTable.SDCoherence)], ...
        [0.82 0.88 0.96], "EdgeColor", "none");
    hold on;
    plot(coherenceTable.FrequencyHz, coherenceTable.MeanCoherence, ...
        "b-", "LineWidth", 1.5);
    yline(mean(coherenceTable.MeanCARNetThreshold, "omitnan"), ...
        "k--", "CARNET threshold");
    xlim([0.02 0.35]);
    ylim([0 1]);
    xlabel("Frequency (Hz)");
    ylabel("Ordinary MAP-PETCO2 coherence");
    title("Coherence by frequency");
    grid on;

    subjectTable = characterization.subjectTable;
    nexttile;
    histogram(subjectTable.BandMeanCoherence, 8, ...
        "FaceColor", [0.2 0.45 0.75]);
    hold on;
    coherenceQuantiles = characterization.coherence.subjectQuantiles;
    xline(coherenceQuantiles(1), "--", "10th");
    xline(coherenceQuantiles(2), "-", "50th");
    xline(coherenceQuantiles(3), "--", "90th");
    xlim([0 1]);
    xlabel("Subject band-mean coherence");
    ylabel("Subjects");
    title("NC coherence distribution");
    grid on;

    nexttile;
    validLag = subjectTable.PhaseLagSeconds( ...
        isfinite(subjectTable.PhaseLagSeconds));
    histogram(validLag, 8, "FaceColor", [0.75 0.42 0.25]);
    hold on;
    phaseQuantiles = characterization.phase.subjectLagQuantilesSeconds;
    xline(phaseQuantiles(1), "--", "10th");
    xline(phaseQuantiles(2), "-", "50th");
    xline(phaseQuantiles(3), "--", "90th");
    xlabel("Fitted PETCO2 lag relative to MAP (s)");
    ylabel("Subjects");
    title(sprintf("Phase-lag distribution (median fit R2 %.2f)", ...
        characterization.phase.medianLagFitR2));
    grid on;

    nexttile;
    powerTable = characterization.power.frequencyTable;
    plot(powerTable.FrequencyHz, powerTable.MAPPowerMedianDb, ...
        "b-", "LineWidth", 1.5);
    hold on;
    plot(powerTable.FrequencyHz, powerTable.CO2PowerMedianDb, ...
        "r-", "LineWidth", 1.5);
    xlim([0.02 0.35]);
    xlabel("Frequency (Hz)");
    ylabel("Median power (dB)");
    title("Measured NC input spectra");
    legend("MAP", "PETCO2", "Location", "best");
    grid on;

    outputFile = fullfile(outputFolder, "STEP2_NC_INPUT_AUDIT.pdf");
    exportgraphics(figureHandle, outputFile, "ContentType", "vector");
    close(figureHandle);

end
