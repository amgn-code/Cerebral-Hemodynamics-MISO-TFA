function summaryTable = summarizeGainModelComparisonByBand( ...
    comparison, analysisSettings)
% summarizeGainModelComparisonByBand Create MAP and CO2 band summaries.

    pathways = ["MAP"; "CO2"];
    bandNames = string(analysisSettings.frequencyBandNames(:));
    numRows = numel(pathways)*numel(bandNames);

    pathwayColumn = strings(numRows, 1);
    bandColumn = strings(numRows, 1);
    misoGain = NaN(numRows, 1);
    sisoGain = NaN(numRows, 1);
    rowIndex = 0;

    for pathwayIndex = 1:numel(pathways)
        pathway = pathways(pathwayIndex);
        pathwayField = lower(char(pathway));

        misoBandValues = calculateSubjectBandValues( ...
            comparison.miso.f, ...
            comparison.miso.(pathwayField).gain(:), ...
            analysisSettings, "arithmetic").values;
        sisoBandValues = calculateSubjectBandValues( ...
            comparison.siso.f, ...
            comparison.siso.(pathwayField).gain(:), ...
            analysisSettings, "arithmetic").values;

        for bandIndex = 1:numel(bandNames)
            rowIndex = rowIndex + 1;
            pathwayColumn(rowIndex) = pathway;
            bandColumn(rowIndex) = bandNames(bandIndex);
            misoGain(rowIndex) = misoBandValues(bandIndex);
            sisoGain(rowIndex) = sisoBandValues(bandIndex);
        end
    end

    summaryTable = table( ...
        pathwayColumn, bandColumn, misoGain, sisoGain, ...
        misoGain - sisoGain, ...
        'VariableNames', { ...
            'Pathway', 'Band', 'MISOGain', 'SISOGain', ...
            'MISOminusSISO'});

end
