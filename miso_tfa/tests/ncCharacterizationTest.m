classdef ncCharacterizationTest < matlab.unittest.TestCase
    % ncCharacterizationTest Verify NC-derived simulation calibration.

    methods (TestClassSetup)
        function addProjectFolders(testCase)
            projectRoot = fileparts(fileparts(mfilename("fullpath")));
            testCase.applyFixture( ...
                matlab.unittest.fixtures.PathFixture( ...
                    projectRoot, IncludingSubfolders=true));
        end
    end

    methods (Test)
        function biasCorrectionRecoversKnownCoherence(testCase)
            previousState = rng;
            cleanup = onCleanup(@() rng(previousState));
            rng(9021, "twister");
            numAverages = 8;
            numRealizations = 20000;
            trueCoherence = 0.50;
            first = complex(randn(numAverages, numRealizations), ...
                randn(numAverages, numRealizations))/sqrt(2);
            independent = complex(randn(numAverages, numRealizations), ...
                randn(numAverages, numRealizations))/sqrt(2);
            second = sqrt(trueCoherence)*first + ...
                sqrt(1 - trueCoherence)*independent;
            crossPower = mean(conj(first).*second, 1);
            measured = abs(crossPower).^2./( ...
                mean(abs(first).^2, 1).*mean(abs(second).^2, 1));
            corrected = correctMagnitudeSquaredCoherenceBias( ...
                measured, numAverages);

            testCase.verifyEqual(mean(corrected), trueCoherence, ...
                AbsTol=0.03);
            clear cleanup
        end

        function monotonicSpectrumFitRecoversParameters(testCase)
            frequencyHz = (0.01:0.01:0.35)';
            rolloffHz = 0.045;
            exponent = 2.4;
            powerDb = 7 + 10*log10( ...
                1./(1 + (frequencyHz/rolloffHz).^exponent));
            powerTable = table(frequencyHz, powerDb, powerDb, ...
                'VariableNames', {'FrequencyHz', 'MAPPowerMedianDb', ...
                'CO2PowerMedianDb'});

            result = fitNcInputSpectrum(powerTable, [0.033 0.35]);

            testCase.verifyEqual(result.rolloffFrequencyHz, ...
                rolloffHz, RelTol=0.01);
            testCase.verifyEqual(result.rolloffExponent, exponent, ...
                RelTol=0.01);
        end
    end
end
