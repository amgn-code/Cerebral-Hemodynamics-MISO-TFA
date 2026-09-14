classdef calculateMisoCoherenceDiagnosticsTest < matlab.unittest.TestCase
    % calculateMisoCoherenceDiagnosticsTest Verify the two-input identities.

    methods (TestClassSetup)
        function addSourceFolder(testCase)
            projectFolder = fileparts(fileparts(mfilename('fullpath')));
            testCase.applyFixture( ...
                matlab.unittest.fixtures.PathFixture( ...
                    projectFolder, IncludingSubfolders=true));
        end
    end

    methods (Test)
        function proposedGapCanBeZeroWhileMapSisoIsBiased(testCase)
            spectra = createSpectra(1, 1, 3, 0.5, 0.5, 1.5, 1.5);
            diagnostics = calculateMisoCoherenceDiagnostics( ...
                spectra, 1);

            testCase.verifyEqual( ...
                diagnostics.multipleMinusPartialMapCoherence, 0, ...
                AbsTol=1e-12);
            testCase.verifyEqual( ...
                diagnostics.multipleMinusMapCoherence, 0.25, ...
                AbsTol=1e-12);
            testCase.verifyEqual( ...
                diagnostics.mapPairwiseCoherence, 0.75, ...
                AbsTol=1e-12);
        end

        function coherenceGapsSatisfySpectralIdentities(testCase)
            rng(17);

            for repetition = 1:10
                source = randn(3) + 1i*randn(3);
                spectralMatrix = source*source' + eye(3);
                inputMatrix = spectralMatrix(1:2, 1:2);
                inputOutput = spectralMatrix(1:2, 3);
                transferFunction = inputMatrix\inputOutput;
                multipleCoherence = real( ...
                    inputOutput'*transferFunction)/real(spectralMatrix(3, 3));

                spectra = createSpectra( ...
                    spectralMatrix(1, 1), spectralMatrix(2, 2), ...
                    spectralMatrix(3, 3), spectralMatrix(1, 2), ...
                    spectralMatrix(2, 1), spectralMatrix(1, 3), ...
                    spectralMatrix(2, 3));
                diagnostics = calculateMisoCoherenceDiagnostics( ...
                    spectra, multipleCoherence);

                expectedAddedExplanation = ...
                    (1 - diagnostics.mapPairwiseCoherence) .* ...
                    diagnostics.partialCo2Coherence;
                expectedShotaroGap = ...
                    diagnostics.co2PairwiseCoherence .* ...
                    (1 - diagnostics.partialMapCoherence);

                testCase.verifyEqual( ...
                    diagnostics.multipleMinusMapCoherence, ...
                    expectedAddedExplanation, AbsTol=1e-10);
                testCase.verifyEqual( ...
                    diagnostics.multipleMinusPartialMapCoherence, ...
                    expectedShotaroGap, AbsTol=1e-10);
            end
        end
    end
end

function spectra = createSpectra( ...
    mapPower, co2Power, cbvPower, mapCo2, co2Map, mapCbv, co2Cbv)
% createSpectra Create one-frequency spectra for an analytic test.

    spectra.map.power = mapPower;
    spectra.co2.power = co2Power;
    spectra.cbv.power = cbvPower;
    spectra.cross.mapCo2 = mapCo2;
    spectra.cross.co2Map = co2Map;
    spectra.cross.mapCbv = mapCbv;
    spectra.cross.co2Cbv = co2Cbv;

end
