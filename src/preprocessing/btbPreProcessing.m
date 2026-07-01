function processedSignalData = btbPreProcessing(signalData)


    %% Clear Blank Entries

    arrayNames = ["t", "map", "co2", "cbv", "vmin", "vmax"];

    co2Index = 1;
    co2mean = mean(signalData.co2);
    while signalData.co2(co2Index) < co2mean - 10
        for i = 1:length(arrayNames)
            arrayName = arrayNames(i);
            signalData.(arrayName)(co2Index) = [];
        end
    end

    validRows = isfinite(signalData.t) & ...
            isfinite(signalData.map) & ...
            isfinite(signalData.co2) & ...
            isfinite(signalData.cbv) & ...
            isfinite(signalData.vmin) & ...
            isfinite(signalData.vmax);

    signalData.t = signalData.t(validRows);
    signalData.map = signalData.map(validRows);
    signalData.co2 = signalData.co2(validRows);
    signalData.cbv = signalData.cbv(validRows);
    signalData.vmin = signalData.vmin(validRows);
    signalData.vmax = signalData.vmax(validRows);

    %% Resample to 4 Hz

    fsTarget = 4;
    dtTarget = 1 / fsTarget;
 
    tResampled = (signalData.t(1):dtTarget:signalData.t(end));
 
    mapResampled = interp1(signalData.t, signalData.map,  tResampled, "linear");
    co2Resampled = interp1(signalData.t, signalData.co2, tResampled, "linear");
    cbvResampled = interp1(signalData.t, signalData.cbv, tResampled, "linear");
 
    mapDetrend = detrend(mapResampled,3);
    co2Detrend = detrend(co2Resampled,3);
    cbvDetrend = detrend(cbvResampled,3);

    
    %% Store Result

    processedSignalData.t   = tResampled;
    processedSignalData.map = mapDetrend;
    processedSignalData.co2 = co2Detrend;
    processedSignalData.cbv = cbvDetrend;
    processedSignalData.fs = fsTarget;

end
