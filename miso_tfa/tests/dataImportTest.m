classdef dataImportTest < matlab.unittest.TestCase
    % dataImportTest Verify portable file and header handling.

    methods (TestClassSetup)
        function addProjectFolders(testCase)
            projectRoot = fileparts(fileparts(mfilename("fullpath")));
            testCase.applyFixture( ...
                matlab.unittest.fixtures.PathFixture( ...
                    projectRoot, IncludingSubfolders=true));
            setup();
        end
    end

    methods (Test)
        function loadsCsvWithCaseAndPunctuationDifferences(testCase)
            temporaryFolder = string(tempname);
            mkdir(temporaryFolder);
            testCase.addTeardown(@() rmdir(temporaryFolder, "s"));

            sampleCount = 32;
            sampleTable = table( ...
                (0:(sampleCount - 1))', ...
                90*ones(sampleCount, 1), ...
                35*ones(sampleCount, 1), ...
                50*ones(sampleCount, 1), ...
                'VariableNames', { ...
                    'TIME', 'Mean_CH2_Finapress', ...
                    'peak_etco2', 'Vmean'});
            inputFile = fullfile(temporaryFolder, "recording.csv");
            writetable(sampleTable, inputFile);

            connectedData = connectData(inputFile);

            testCase.verifyEqual(connectedData.filePath, string(inputFile));
            testCase.verifyEqual(connectedData.signalData.map, ...
                90*ones(1, sampleCount));
            testCase.verifyEqual(connectedData.signalData.co2, ...
                35*ones(1, sampleCount));
            testCase.verifyEqual(connectedData.signalData.cbv, ...
                50*ones(1, sampleCount));
        end

        function explicitColumnMapOverridesAliases(testCase)
            temporaryFolder = string(tempname);
            mkdir(temporaryFolder);
            testCase.addTeardown(@() rmdir(temporaryFolder, "s"));

            sampleCount = 16;
            sampleTable = table( ...
                (0:(sampleCount - 1))', ...
                90*ones(sampleCount, 1), ...
                35*ones(sampleCount, 1), ...
                50*ones(sampleCount, 1), ...
                'VariableNames', {'seconds_col', 'pressure_col', ...
                'gas_col', 'velocity_col'});
            inputFile = fullfile(temporaryFolder, "recording.csv");
            writetable(sampleTable, inputFile);

            importSettings.columnMap.t = "seconds_col";
            importSettings.columnMap.map = "pressure_col";
            importSettings.columnMap.co2 = "gas_col";
            importSettings.columnMap.cbv = "velocity_col";
            connectedData = connectData(inputFile, importSettings);

            testCase.verifyEqual( ...
                numel(connectedData.signalData.t), sampleCount);
        end
    end
end
