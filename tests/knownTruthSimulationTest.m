classdef knownTruthSimulationTest < matlab.unittest.TestCase
    % knownTruthSimulationTest Verify the known-truth validation framework.

    methods (TestClassSetup)
        function addSourceFolder(testCase)
            projectFolder = fileparts(fileparts(mfilename('fullpath')));
            testCase.applyFixture( ...
                matlab.unittest.fixtures.PathFixture( ...
                    fullfile(projectFolder, "src"), ...
                    IncludingSubfolders=true));
        end
    end

    methods (Test)
        function generatorIsReproducible(testCase)
            settings = defaultKnownTruthSimulationSettings("quick");
            condition = makeTestCondition();

            first = createKnownTruthMisoSignal( ...
                settings, condition, 1234);
            second = createKnownTruthMisoSignal( ...
                settings, condition, 1234);

            testCase.verifyEqual(first.map, second.map);
            testCase.verifyEqual(first.co2, second.co2);
            testCase.verifyEqual(first.cbv, second.cbv);
            testCase.verifyEqual( ...
                first.truth.co2ImpulseResponse, ...
                second.truth.co2ImpulseResponse);
        end

        function favorableConditionRecoversBothPathways(testCase)
            settings = defaultKnownTruthSimulationSettings("quick");
            settings.numReplicates = 1;
            settings.inputCorrelations = 0.8;
            settings.co2InputSds = 0.4;
            settings.co2PathwayScales = 1;
            settings.outputSnrDb = 30;
            settings.durationSeconds = 1200;
            settings.co2DelaysSeconds = 0;
            settings.misspecificationStrengths = 0;
            settings.ridgeLambdas = 0.01;

            results = runKnownTruthSimulationGrid(settings);
            trials = results.trials;
            sisoRows = trials.Estimator == "SISO";
            misoRows = trials.Estimator == "MISO unregularized";

            testCase.verifyEqual(height(trials), 6);
            testCase.verifyLessThan( ...
                mean(trials.NormalizedComplexError(misoRows)), ...
                mean(trials.NormalizedComplexError(sisoRows)));
            testCase.verifyTrue(all(isfinite( ...
                trials.MedianNormalizedConditionNumber(misoRows))));
        end
    end
end

function condition = makeTestCondition()
% makeTestCondition Return one readable generator condition.

    condition.inputCorrelation = 0.5;
    condition.co2InputSd = 0.4;
    condition.co2PathwayScale = 1;
    condition.outputSnrDb = 10;
    condition.durationSeconds = 300;
    condition.co2DelaySeconds = 3;
    condition.misspecificationStrength = 0;

end
