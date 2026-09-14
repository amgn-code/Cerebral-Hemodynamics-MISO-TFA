classdef exportSimpleSimulationFrequencyMapSetTest < matlab.unittest.TestCase
    % exportSimpleSimulationFrequencyMapSetTest Verify the simple export.

    methods (TestClassSetup)
        function addProjectFolders(testCase)
            projectRoot = fileparts(fileparts(mfilename("fullpath")));
            testCase.applyFixture( ...
                matlab.unittest.fixtures.PathFixture( ...
                    projectRoot, IncludingSubfolders=true));
        end
    end

    methods (Test)
        function exportsThreePrimaryMapsAndReadableSourceData(testCase)
            outputFolder = tempname();
            mkdir(outputFolder);
            testCase.addTeardown(@() rmdir(outputFolder, "s"));

            exportSettings.widthInches = 4;
            exportSettings.heightInches = 3;
            exportSettings.pngResolution = 72;
            exportSettings.savePdf = false;
            exportSettings.savePng = true;
            exportSettings.saveFigureSourceData = true;
            exportSettings.saveCaptionFiles = true;
            exportSettings.advantageColorLimit = 1.5;

            simulationResults = createSmallExportResults();
            exportResults = exportSimpleSimulationFrequencyMapSet( ...
                simulationResults, outputFolder, exportSettings);

            testCase.verifyEqual(height(exportResults.manifest), 5);
            testCase.verifyEqual(numel(exportResults.savedFiles), 25);
            testCase.verifyTrue(all(isfile(exportResults.savedFiles)));

            workbooks = exportResults.savedFiles( ...
                endsWith(exportResults.savedFiles, ".xlsx"));
            testCase.verifyEqual(numel(workbooks), 5);
            sheets = string(sheetnames(workbooks(1)));
            testCase.verifyTrue(any(contains(sheets, "frequencyMap_grid")));
            grid = readcell( ...
                workbooks(1), "Sheet", sheets(contains( ...
                    sheets, "frequencyMap_grid")));
            testCase.verifyTrue(any(contains(string(grid(:)), "±")));
        end
    end
end

function simulationResults = createSmallExportResults()
% createSmallExportResults Create compact results for the exporter test.

    numObservations = 18;
    coherence = [ ...
        repelem([0; 0.5; 0.95], 3); ...
        repmat(0.5, 9, 1)];
    ratio = [ ...
        repmat([0; 0.25; 1], 3, 1); ...
        repmat(0.25, 9, 1)];
    outputSnr = [ ...
        repmat(10, 9, 1); ...
        repmat([Inf; 10; 0], 3, 1)];
    observations = table( ...
        (1:numObservations)', ...
        repmat(300, numObservations, 1), ...
        outputSnr, ...
        coherence, ...
        ratio, ...
        true(numObservations, 1), ...
        'VariableNames', { ...
            'ObservationID', 'DurationSeconds', 'OutputSNRdB', ...
            'TargetInputCoherence', ...
            'AssignedPETCO2ToMAPBandGainRatio', ...
            'IsMainExperiment'});

    simulationResults.observations = observations;
    simulationResults.frequency.frequencyHz = [0.02; 0.03];
    simulationResults.frequency.map.sisoComplexError = ...
        repmat([1; 2], 1, numObservations);
    simulationResults.frequency.map.misoComplexError = ...
        repmat([0.5; 1], 1, numObservations);
    simulationResults.frequency.multipleMinusMapCoherence = ...
        repmat([0.2; 0.4], 1, numObservations);
    simulationResults.frequency.multipleMinusPartialMapCoherence = ...
        repmat([0.3; 0.5], 1, numObservations);
    simulationResults.settings.frequencyRangeHz = [0.02 0.03];
    simulationResults.settings.grouping.minimumValidN = 1;
    simulationResults.settings.observations.referenceDurationSeconds = 300;
    simulationResults.settings.observations.referenceOutputSnrDb = 10;
    simulationResults.numFamilies = 9;

end
