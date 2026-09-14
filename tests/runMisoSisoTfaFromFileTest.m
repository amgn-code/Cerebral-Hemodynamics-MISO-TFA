classdef runMisoSisoTfaFromFileTest < matlab.unittest.TestCase
    % runMisoSisoTfaFromFileTest Tests the user-facing file entry point.

    methods (TestClassSetup)
        function addSourceFolder(testCase)
            projectFolder = fileparts(fileparts(mfilename('fullpath')));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                projectFolder, IncludingSubfolders=true));
        end
    end

    methods (Test)
        function missingFileIsReportedClearly(testCase)
            testCase.verifyError( ...
                @() runMisoSisoTfaFromFile( ...
                    fullfile(tempdir, "missing_miso_tfa_file.xlsx")), ...
                "TFA:MissingInputFile");
        end

        function fileEntryPointReturnsBothModelsAndDiagnostics(testCase)
            temporaryFolder = tempname();
            mkdir(temporaryFolder);
            testCase.addTeardown(@() rmdir(temporaryFolder, "s"));

            signalData = createSyntheticSignal(4);
            inputTable = table( ...
                signalData.t(:), signalData.map(:), ...
                signalData.co2(:), signalData.cbv(:), ...
                'VariableNames', {'Time', 'MAP', 'CO2', 'CBV'});
            inputFile = fullfile(temporaryFolder, "user_recording.xlsx");
            writetable(inputTable, inputFile, "Sheet", "Sheet1");

            analysisSettings = defaultTfaAnalysisSettings("NC");
            analysisSettings.pwelch.windowLengthSeconds = 32;
            analysisSettings.pwelch.minimumWindows = 3;

            results = runMisoSisoTfaFromFile( ...
                inputFile, analysisSettings);

            testCase.verifyTrue(results.runStatus.analysisSucceeded);
            testCase.verifyEqual(results.userInputFile, string(inputFile));
            testCase.verifyEqual(results.subjectInfo.group, "UserData");
            testCase.verifyTrue(isfield(results, "rawSignalData"));
            testCase.verifyTrue(isfield(results, "analysisInput"));
            testCase.verifyTrue(isfield(results, "misoResults"));
            testCase.verifyTrue(isfield(results, "sisoResults"));
            testCase.verifyTrue(isfield( ...
                results.misoResults, "diagnostics"));
            testCase.verifyTrue(isfield( ...
                results.misoResults.diagnostics, ...
                "multipleMinusMapCoherence"));
            testCase.verifyEqual(results.outputFolder, "");
            testCase.verifyFalse(results.runStatus.subjectFiguresSaved);
        end
    end
end
