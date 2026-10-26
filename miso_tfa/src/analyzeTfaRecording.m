function result = analyzeTfaRecording(recording, settings, truth)
% analyzeTfaRecording Apply the same estimators to real or simulated inputs.
%
% recording contains analysis-ready map, co2, cbv, fs, and cbvUnits.
% Optional truth contains generating impulse weights in matching output units.

    if nargin < 3
        truth = [];
    end
    [~, window] = getWelchWindowSettings(settings.pwelch, recording.fs, numel(recording.map));
    assert(window.isReadyForTFA, "TFA:InsufficientWelchWindows", ...
        "The recording needs at least %d Welch windows. Increase duration or reduce window length.", ...
        settings.pwelch.minimumWindows);
    % These analysis transformations are identical for both input routes.
    for signal = ["map", "co2", "cbv"]
        values = recording.(signal)(:);
        if settings.preprocessing.detrendEnabled
            values = detrend(values, settings.preprocessing.detrendOrder);
        end
        if settings.preprocessing.meanRemovalEnabled
            values = values - mean(values);
        end
        recording.(signal) = values;
    end
    spectra = estimateWelchSpectra(recording.map, recording.co2, recording.cbv, ...
        recording.fs, settings.pwelch);
    full = estimateTransferFunctions(spectra);
    selected = full.frequencyHz >= settings.frequencyRangeHz(1) ...
        & full.frequencyHz <= settings.frequencyRangeHz(2);
    result.id = "";
    result.group = "";
    result.sourceFile = "";
    result.conditionID = 0;
    result.repetition = 0;
    result.frequencyHz = full.frequencyHz(selected);
    result.cbvUnits = recording.cbvUnits;
    result.inputUnits = "mmHg";
    if isfield(recording, "inputUnits")
        result.inputUnits = recording.inputUnits;
    end
    result.welch = spectra.welchInfo;
    result.preprocessing = struct();
    for field = ["physiology", "quality", "co2Startup", "co2Alignment"]
        if isfield(recording, field)
            result.preprocessing.(field) = recording.(field);
        end
    end
    result.inputCoherence = full.inputCoherence(selected);
    result.multipleCoherence = full.multipleCoherence(selected);
    result.conditionNumber = full.conditionNumber(selected);
    result.inputPower.map = real(spectra.map.power(selected));
    result.inputPower.co2 = real(spectra.co2.power(selected));
    for modelName = ["siso", "miso"]
        for pathway = ["map", "co2"]
            source = full.(modelName).(pathway);
            result.(modelName).(pathway).transferFunction = source.transferFunction(selected);
            result.(modelName).(pathway).gain = source.gain(selected);
            result.(modelName).(pathway).phaseDegrees = source.phaseDegrees(selected);
            result.(modelName).(pathway).coherence = source.coherence(selected);
            impulse = calculateImpulseResponse(source.transferFunction, recording.fs, ...
                window.fftLengthSamples, settings.frequencyRangeHz);
            result.impulseTimeSeconds = impulse.timeSeconds;
            result.(modelName).(pathway).impulse = impulse.response;
        end
    end
    for pathway = ["map", "co2"]
        siso = result.siso.(pathway);
        miso = result.miso.(pathway);
        result.difference.(pathway).gain = miso.gain - siso.gain;
        result.difference.(pathway).phaseDegrees = ...
            rad2deg(angle(miso.transferFunction.*conj(siso.transferFunction)));
        undefined = miso.gain == 0 | siso.gain == 0;
        result.difference.(pathway).phaseDegrees(undefined) = NaN;
    end
    result.truth = [];
    if ~isempty(truth)
        for pathway = ["map", "co2"]
            kernel = truth.(pathway + "ImpulseResponse");
            response = freqz(kernel, 1, full.frequencyHz, recording.fs);
            result.truth.(pathway).transferFunction = response(selected);
            result.truth.(pathway).gain = abs(response(selected));
            result.truth.(pathway).phaseDegrees = rad2deg(angle(response(selected)));
            result.truth.(pathway).phaseDegrees(abs(response(selected)) == 0) = NaN;
            impulse = calculateImpulseResponse(response, recording.fs, ...
                window.fftLengthSamples, settings.frequencyRangeHz);
            result.truth.(pathway).impulse = impulse.response;
        end
    end
end
