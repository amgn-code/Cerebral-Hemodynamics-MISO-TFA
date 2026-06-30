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

    %% Beat Confidence

    numBeats = length(signalData.t);
    numCorruptedBeats = 0;

    for i = 1:numBeats
        if signalData.vmax(i) > 150 || signalData.vmin(i) < 5
            numCorruptedBeats = numCorruptedBeats + 1;
        end
    end

    percentCorruptedBeats = (numCorruptedBeats / numBeats);
   
    if percentCorruptedBeats == 0
        confidenceLevel = 'High Confidence';
    elseif percentCorruptedBeats < 0.03
        confidenceLevel = 'Moderate Confidence';
    elseif percentCorruptedBeats < 0.05
        confidenceLevel = 'Medium Confidence';
    elseif percentCorruptedBeats < 0.1
        confidenceLevel = 'Low Confidence';
    else
        confidenceLevel = 'Consider Excluding';
    end

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
    processedSignalData.confidenceLevel = confidenceLevel;
    processedSignalData.percentCorruptedBeats = percentCorruptedBeats;



end