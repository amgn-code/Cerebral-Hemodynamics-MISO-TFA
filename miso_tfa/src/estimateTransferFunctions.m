function models = estimateTransferFunctions(spectra)
% estimateTransferFunctions Fit SISO and unregularized two-input MISO.
%
% These are the same spectral equations as the saved baseline. The spectra
% use Sxy = conj(X).*Y. Therefore Sxx*H = Sxy at each frequency.
% The two pathways are MAP->CBFV and CO2->CBFV; no MAP->CO2 TF is fitted.

    mapPower = real(spectra.map.power);
    co2Power = real(spectra.co2.power);
    cbvPower = real(spectra.cbv.power);
    mapCbv = spectra.cross.mapCbv;
    co2Cbv = spectra.cross.co2Cbv;
    sisoMap = mapCbv./mapPower;
    sisoCo2 = co2Cbv./co2Power;
    count = numel(spectra.f);
    misoMap = complex(NaN(count, 1));
    misoCo2 = complex(NaN(count, 1));
    multiple = NaN(count, 1);
    conditionNumber = NaN(count, 1);
    for index = 1:count
        inputMatrix = [mapPower(index), spectra.cross.mapCo2(index); ...
            spectra.cross.co2Map(index), co2Power(index)];
        outputVector = [mapCbv(index); co2Cbv(index)];
        if any(~isfinite(inputMatrix), "all") || any(~isfinite(outputVector)) ...
                || any([mapPower(index), co2Power(index), cbvPower(index)] <= 0)
            continue
        end
        inputMatrix = (inputMatrix + inputMatrix')/2;
        inputScale = diag(sqrt([mapPower(index), co2Power(index)]));
        normalized = inputScale\inputMatrix/inputScale;
        conditionNumber(index) = cond(normalized);
        % Exact/near-exact collinearity cannot identify two separate paths.
        % Keep NaNs and report them; do not silently substitute a ridge fit.
        if rcond(normalized) <= eps
            continue
        end
        coefficients = inputMatrix\outputVector;
        misoMap(index) = coefficients(1);
        misoCo2(index) = coefficients(2);
        residual = cbvPower(index) - 2*real(coefficients'*outputVector) ...
            + real(coefficients'*inputMatrix*coefficients);
        multiple(index) = 1 - max(real(residual), 0)/cbvPower(index);
    end
    diagnostics = calculateMisoCoherenceDiagnostics(spectra);
    models.frequencyHz = spectra.f;
    models.siso.map = pathwayResult(sisoMap, diagnostics.mapPairwiseCoherence);
    models.siso.co2 = pathwayResult(sisoCo2, diagnostics.co2PairwiseCoherence);
    models.miso.map = pathwayResult(misoMap, diagnostics.partialMapCoherence);
    models.miso.co2 = pathwayResult(misoCo2, diagnostics.partialCo2Coherence);
    models.multipleCoherence = boundCoherence(multiple);
    models.inputCoherence = boundCoherence(diagnostics.inputCoherence);
    models.conditionNumber = conditionNumber;
end

function result = pathwayResult(transferFunction, coherence)
    result.transferFunction = transferFunction;
    result.gain = abs(transferFunction);
    result.phaseDegrees = rad2deg(angle(transferFunction));
    result.phaseDegrees(abs(transferFunction) == 0) = NaN;
    result.coherence = boundCoherence(coherence);
end

function bounded = boundCoherence(values)
    bounded = min(1, max(0, real(values)));
    bounded(~isfinite(values)) = NaN;
end
