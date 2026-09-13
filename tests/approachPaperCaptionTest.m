classdef approachPaperCaptionTest < matlab.unittest.TestCase
    % approachPaperCaptionTest Verify captions and caption catalogs.

    methods (TestClassSetup)
        function addProjectFolders(testCase)
            projectRoot = fileparts(fileparts(mfilename("fullpath")));
            testCase.applyFixture( ...
                matlab.unittest.fixtures.PathFixture( ...
                    projectRoot, IncludingSubfolders=true));
        end
    end

    methods (Test)
        function statisticalCaptionCoversRequiredInterpretation(testCase)
            sourceData = createStatisticalSourceData();
            exportSettings = createCaptionExportSettings();
            details = struct( ...
                "referenceContext", ...
                    "Recording duration: 300 s | Welch: 128 s, 50% overlap", ...
                "groupingDescription", ...
                    "The factor axis uses five prespecified fixed intervals", ...
                "adjustmentFamily", ...
                    "all factor-by-frequency cells within each pathway metric", ...
                "displayType", "heatmap", ...
                "includesModelAdvantage", true);

            captionInfo = createApproachPaperFigureCaption( ...
                7, "frequency_advantage", ...
                "Frequency-resolved model advantage", ...
                sourceData, exportSettings, details);
            caption = captionInfo.Caption;

            testCase.verifySubstring(caption, "proof-of-concept");
            testCase.verifySubstring(caption, "not final-paper evidence");
            testCase.verifySubstring(caption, "recording duration: 300 s");
            testCase.verifySubstring(caption, "prespecified fixed intervals");
            testCase.verifySubstring(caption, "native Welch frequency bins");
            testCase.verifySubstring(caption, "arithmetic mean");
            testCase.verifySubstring(caption, "SD");
            testCase.verifySubstring(caption, "valid family count");
            testCase.verifySubstring(caption, "5 valid families");
            testCase.verifySubstring(caption, "remain gray");
            testCase.verifySubstring(caption, "Benjamini-Hochberg");
            testCase.verifySubstring(caption, ...
                "all factor-by-frequency cells within each pathway metric");
            testCase.verifySubstring(caption, ...
                "positive values indicate lower MISO error");
            testCase.verifySubstring(caption, ...
                "negative values indicate lower SISO error");
        end

        function exportCreatesCaptionFileAndManifestFields(testCase)
            outputFolder = createTemporaryFolder(testCase);
            figureHandle = createTestFigure(testCase);
            exportSettings = createCaptionExportSettings();
            exportSettings.saveFigureSourceData = false;
            details = struct( ...
                "displayType", "curve", ...
                "groupingDescription", ...
                    "The factor axis uses exact configured values");

            [manifestRow, savedFiles] = exportApproachPaperPlot( ...
                figureHandle, createStatisticalSourceData(), ...
                outputFolder, 3, "test_plot", "Short test title", ...
                exportSettings, details);

            testCase.verifyTrue(isfile(manifestRow.CaptionFile));
            testCase.verifyTrue(any(savedFiles == manifestRow.CaptionFile));
            testCase.verifyTrue(ismember( ...
                "Caption", string(manifestRow.Properties.VariableNames)));
            testCase.verifyTrue(ismember( ...
                "EvidenceLevel", ...
                string(manifestRow.Properties.VariableNames)));
            testCase.verifyTrue(ismember( ...
                "AdjustmentFamily", ...
                string(manifestRow.Properties.VariableNames)));
            captionText = join(readlines(manifestRow.CaptionFile), " ");
            testCase.verifySubstring(captionText, "Short test title");
            testCase.verifySubstring(captionText, "proof250");
        end

        function catalogContainsEveryManifestCaption(testCase)
            outputFolder = createTemporaryFolder(testCase);
            manifest = table( ...
                [1; 3], ["Concept"; "Results"], ...
                ["First complete caption."; "Second complete caption."], ...
                'VariableNames', {'GroupNumber', 'Title', 'Caption'});

            catalogFile = writeApproachPaperCaptionCatalog( ...
                manifest, outputFolder);
            catalogText = join(readlines(catalogFile), newline);

            testCase.verifyTrue(isfile(catalogFile));
            testCase.verifySubstring(catalogText, ...
                "First complete caption.");
            testCase.verifySubstring(catalogText, ...
                "Second complete caption.");
            testCase.verifySubstring(catalogText, ...
                "Group 03");
        end

        function rendererReturnsCaptionCatalog(testCase)
            outputFolder = createTemporaryFolder(testCase);
            settings = approachPaperSettings("", outputFolder, "quick");
            settings.steps.createFigures = true;
            settings.export.savePdf = false;
            settings.export.savePng = true;
            settings.export.pngResolution = 72;
            settings.export.saveFigureSourceData = false;
            paperResults.settings = settings;
            paperResults.empirical = struct();
            paperResults.simulation = struct();
            paperResults.robustness = struct();

            rendered = renderApproachPaperOutputs( ...
                paperResults, settings);

            testCase.verifyTrue(isfile( ...
                rendered.plotResults.captionCatalogFile));
            testCase.verifyTrue(isfile( ...
                rendered.plotResults.manifestFile));
            testCase.verifyEqual( ...
                height(rendered.plotResults.manifest), 1);
            testCase.verifyNotEmpty( ...
                rendered.plotResults.manifest.Caption(1));
            testCase.verifyTrue(isfile( ...
                rendered.plotResults.manifest.CaptionFile(1)));
        end
    end
end

function sourceData = createStatisticalSourceData()
% createStatisticalSourceData Build one representative heatmap source table.

    sourceData = table( ...
        [0.1; 0.3], ["0-0.2"; "0.2-0.4"], ...
        [0; 0.2], [0.2; 0.4], ...
        [0.05; 0.05], [0.2; -0.1], [0.1; 0.2], ...
        [5; 4], [10; 10], [0.04; 0.10], ...
        [0.01; 0.03], [0.39; 0.29], ...
        [0.02; 0.08], [0.04; 0.12], ...
        'VariableNames', { ...
            'FactorValue', 'FactorGroup', ...
            'FactorLower', 'FactorUpper', 'FrequencyHz', ...
            'Mean', 'SD', 'ValidN', 'GroupN', ...
            'StandardError', 'CILower', 'CIUpper', ...
            'RawP', 'BHAdjustedP'});

end

function exportSettings = createCaptionExportSettings()
% createCaptionExportSettings Configure lightweight caption test exports.

    exportSettings.widthInches = 4;
    exportSettings.heightInches = 3;
    exportSettings.pngResolution = 72;
    exportSettings.savePdf = false;
    exportSettings.savePng = true;
    exportSettings.saveFigureSourceData = false;
    exportSettings.saveCaptionFiles = true;
    exportSettings.saveCaptionCatalog = true;
    exportSettings.advantageColorLimit = 2;
    exportSettings.captionContext.profileName = "proof250";
    exportSettings.captionContext.numFamilies = 250;
    exportSettings.captionContext.minimumValidN = 5;
    exportSettings.captionContext.alpha = 0.05;
    exportSettings.captionContext.multipleTestingMethod = ...
        "Benjamini-Hochberg";
    exportSettings.captionContext.errorFloor = 1e-12;

end

function outputFolder = createTemporaryFolder(testCase)
% createTemporaryFolder Register removal of one test folder.

    outputFolder = string(tempname());
    mkdir(outputFolder);
    testCase.addTeardown(@() rmdir(outputFolder, "s"));

end

function figureHandle = createTestFigure(testCase)
% createTestFigure Create and register one invisible export figure.

    figureHandle = figure("Visible", "off", "Color", "white");
    plot(axes(figureHandle), 1:3, [1 2 1]);
    testCase.addTeardown(@() close(figureHandle));

end
