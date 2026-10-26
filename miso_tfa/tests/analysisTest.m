classdef analysisTest < matlab.unittest.TestCase
    % analysisTest Scientific identities, phase, group summaries, and IFFT units.

    methods (TestClassSetup)
        function addProject(testCase)
            folder = fileparts(fileparts(mfilename("fullpath")));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(folder, IncludingSubfolders=true));
            runAnalysis("settings");
        end
    end

    methods (Test)
        function misoRecoversKnownConditionalResponses(testCase)
            [spectra, truth] = analyticSpectra();
            models = estimateTransferFunctions(spectra);
            testCase.verifyEqual(models.miso.map.transferFunction, truth(:, 1), AbsTol=1e-12);
            testCase.verifyEqual(models.miso.co2.transferFunction, truth(:, 2), AbsTol=1e-12);
        end

        function sisoContainsTheOmittedInputContribution(testCase)
            [spectra, truth] = analyticSpectra();
            models = estimateTransferFunctions(spectra);
            expected = truth(:, 1) + truth(:, 2).*spectra.cross.mapCo2./spectra.map.power;
            testCase.verifyEqual(models.siso.map.transferFunction, expected, AbsTol=1e-12);
        end

        function multipleAndPartialCoherencesHaveDistinctMeanings(testCase)
            [spectra, ~] = analyticSpectra();
            models = estimateTransferFunctions(spectra);
            testCase.verifyGreaterThanOrEqual(models.multipleCoherence, models.siso.map.coherence);
            testCase.verifyGreaterThanOrEqual(models.multipleCoherence, models.siso.co2.coherence);
            testCase.verifyNotEqual(models.miso.map.coherence, models.siso.map.coherence);
            testCase.verifyEqual(models.inputCoherence, [0.25; 0.25], AbsTol=1e-12);
        end

        function identicalInputsAreReportedAsUnidentified(testCase)
            [spectra, ~] = analyticSpectra();
            spectra.co2.power = spectra.map.power;
            spectra.cross.mapCo2 = spectra.map.power;
            spectra.cross.co2Map = spectra.map.power;
            models = estimateTransferFunctions(spectra);
            testCase.verifyTrue(all(isnan(models.miso.map.transferFunction)));
            testCase.verifyTrue(all(isnan(models.multipleCoherence)));
            testCase.verifyTrue(all(isfinite(models.siso.map.transferFunction)));
        end

        function phaseErrorUsesTheShortestAngularDistance(testCase)
            truth = [exp(1i*deg2rad(179)); 0];
            estimate = [exp(1i*deg2rad(-179)); 1];
            errors = calculateFrequencyTruthErrors(estimate, truth, 1e-12, 0.05);
            testCase.verifyEqual(rad2deg(errors.phase(1)), 2, AbsTol=1e-12);
            testCase.verifyTrue(isnan(errors.phase(2)));
            testCase.verifyEqual(errors.gain(2), 1, AbsTol=1e-12);
        end

        function complexErrorUsesOneTruthBandNormalization(testCase)
            errors = calculateFrequencyTruthErrors([2; 1], [1; 0.01], 1e-12, 0.05);
            expected = abs([2; 1] - [1; 0.01]).^2/mean([1; 0.01].^2);
            testCase.verifyEqual(errors.complex, expected, AbsTol=1e-12);
        end

        function zeroEstimatedGainHasNoDefinedPhase(testCase)
            errors = calculateFrequencyTruthErrors(0, 1, 1e-12, 0.05);
            testCase.verifyTrue(isnan(errors.phase));
            testCase.verifyEqual(errors.gain, 1, AbsTol=0);
        end

        function impulseHasTheCorrectTimeAndAmplitudeScale(testCase)
            fs = 4;
            n = 400;
            frequency = (0:n/2)'*fs/n;
            delayedResponse = 2*exp(-1i*2*pi*frequency*3);
            impulse = calculateImpulseResponse(delayedResponse, fs, n, [0 fs/2]);
            [height, peak] = max(impulse.response);
            testCase.verifyEqual(impulse.timeSeconds(peak), 3, AbsTol=1e-12);
            testCase.verifyEqual(height, 2*fs, AbsTol=1e-12);
            testCase.verifyEqual(sum(impulse.response)/fs, 2, AbsTol=1e-12);
        end

        function reportingBandImpulseHasNoInventedDC(testCase)
            impulse = calculateImpulseResponse(ones(201, 1), 4, 400, [0.02 0.35]);
            testCase.verifyEqual(sum(impulse.response)/4, 0, AbsTol=1e-12);
            testCase.verifyTrue(isreal(impulse.response));
            testCase.verifyTrue(any(impulse.timeSeconds < 0 & abs(impulse.response) > 1e-4));
        end

        function oddLengthImpulseGridIsSupported(testCase)
            impulse = calculateImpulseResponse(ones(201, 1), 4, 401, [0 2]);
            [height, peak] = max(impulse.response);
            testCase.verifyEqual(impulse.timeSeconds(peak), 0, AbsTol=1e-12);
            testCase.verifyEqual(height, 4, AbsTol=1e-12);
        end

        function groupPhaseIsCircularAndGainIsAnArithmeticMean(testCase)
            [first, second] = groupFixtures();
            first.siso.map.phaseDegrees(:) = 179;
            second.siso.map.phaseDegrees(:) = -179;
            first.siso.map.gain(:) = 1;
            second.siso.map.gain(:) = 9;
            summary = summarizeTfaRecordings([first; second]);
            testCase.verifyEqual(abs(summary.siso.map.phaseDegrees.mean), ...
                180*ones(size(first.frequencyHz)), AbsTol=1e-10);
            testCase.verifyEqual(summary.siso.map.gain.mean, ...
                5*ones(size(first.frequencyHz)), AbsTol=1e-12);
            testCase.verifyEqual(summary.siso.map.gain.sd, ...
                4*sqrt(2)*ones(size(first.frequencyHz)), AbsTol=1e-12);
        end
    end
end

function [spectra, truth] = analyticSpectra()
    spectra.f = [0.05; 0.1];
    spectra.map.power = [4; 4];
    spectra.co2.power = [9; 9];
    spectra.cross.mapCo2 = 3*exp(1i*[0.3; -0.2]);
    spectra.cross.co2Map = conj(spectra.cross.mapCo2);
    truth = [1 + 0.2i, 0.2 - 0.5i; 0.5 + 0.1i, 0.3 - 0.4i];
    spectra.cbv.power = zeros(2, 1);
    spectra.cross.mapCbv = complex(zeros(2, 1));
    spectra.cross.co2Cbv = complex(zeros(2, 1));
    for index = 1:2
        matrix = [4, spectra.cross.mapCo2(index); spectra.cross.co2Map(index), 9];
        coefficients = truth(index, :).';
        crossSpectrum = matrix*coefficients;
        spectra.cross.mapCbv(index) = crossSpectrum(1);
        spectra.cross.co2Cbv(index) = crossSpectrum(2);
        spectra.cbv.power(index) = real(coefficients'*matrix*coefficients) + 0.3;
    end
end

function [first, second] = groupFixtures()
    settings = runAnalysis("settings");
    previous = rng;
    restore = onCleanup(@() rng(previous));
    rng(31);
    recording.map = randn(1600, 1);
    recording.co2 = 0.5*recording.map + randn(1600, 1);
    recording.cbv = filter([1 -0.3], 1, recording.map) + 0.4*recording.co2;
    recording.fs = 4;
    recording.cbvUnits = "simulation units";
    recording.inputUnits = "simulation units";
    first = analyzeTfaRecording(recording, settings.analysis);
    first.group = "Example";
    first.id = "First";
    second = first;
    second.id = "Second";
    clear restore
end
