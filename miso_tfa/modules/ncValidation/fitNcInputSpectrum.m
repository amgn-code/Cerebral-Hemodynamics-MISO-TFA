function fitResult = fitNcInputSpectrum(powerTable, fitBandHz)
% fitNcInputSpectrum Fit one shared monotonic shape to NC MAP and PETCO2.
%
% The fitted shape is P(f)=1/(1+(f/f0)^alpha). An offset is fitted in dB
% because only spectral shape, rather than physical signal units, is used
% by the simulation generator.

    requiredNames = ["FrequencyHz" "MAPPowerMedianDb" "CO2PowerMedianDb"];
    if ~all(ismember(requiredNames, string(powerTable.Properties.VariableNames)))
        error("TFA:InvalidNCInputPowerTable", ...
            "The NC power table is missing a required variable.");
    end
    validateattributes(fitBandHz, {'numeric'}, ...
        {'vector', 'numel', 2, 'increasing', 'nonnegative'});

    frequencyHz = powerTable.FrequencyHz(:);
    observedDb = mean([powerTable.MAPPowerMedianDb(:), ...
        powerTable.CO2PowerMedianDb(:)], 2, "omitnan");
    fitMask = frequencyHz >= fitBandHz(1) & frequencyHz <= fitBandHz(2) & ...
        isfinite(observedDb);
    if nnz(fitMask) < 5
        error("TFA:InsufficientNCInputSpectrumBins", ...
            "At least five finite frequency bins are required for fitting.");
    end

    fitFrequency = frequencyHz(fitMask);
    fitObserved = observedDb(fitMask);
    initial = [log(0.04), log(2), max(fitObserved)];
    objective = @(parameters) mean((fitObserved - ...
        evaluateModelDb(fitFrequency, parameters)).^2);
    options = optimset("Display", "off", "MaxFunEvals", 5000, ...
        "MaxIter", 2000);
    fitted = fminsearch(objective, initial, options);
    fittedDb = evaluateModelDb(fitFrequency, fitted);

    fitResult.model = "1/(1+(f/f0)^alpha)";
    fitResult.fitBandHz = fitBandHz(:).';
    fitResult.rolloffFrequencyHz = exp(fitted(1));
    fitResult.rolloffExponent = exp(fitted(2));
    fitResult.offsetDb = fitted(3);
    fitResult.rootMeanSquaredErrorDb = ...
        sqrt(mean((fitObserved - fittedDb).^2));
    fitResult.frequencyHz = fitFrequency;
    fitResult.observedMedianDb = fitObserved;
    fitResult.fittedDb = fittedDb;

end

function modelDb = evaluateModelDb(frequencyHz, parameters)
% evaluateModelDb Evaluate the constrained model parameterization.

    rolloffFrequencyHz = exp(parameters(1));
    exponent = exp(parameters(2));
    power = 1./(1 + (frequencyHz/rolloffFrequencyHz).^exponent);
    modelDb = parameters(3) + 10*log10(power);

end
