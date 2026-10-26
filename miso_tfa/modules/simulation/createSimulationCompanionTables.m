function companions = createSimulationCompanionTables( ...
    simulationResults, dataRows, factorName, groupingMode, pathway)
% createSimulationCompanionTables Build analytic and realised-SNR tables.
%
% The analytic table compares three errors on the same truth-derived
% normalization and one paired finite mask. It is a verification companion,
% not a theoretical prediction of finite-record MISO advantage.

    if nargin < 4 || isempty(groupingMode)
        groupingMode = "exact";
    end
    if nargin < 5 || isempty(pathway)
        pathway = "map";
    end
    pathway = lower(string(pathway));
    if ~ismember(pathway, ["map" "co2"])
        error("TFA:UnknownSimulationPathway", ...
            "pathway must be map or co2.");
    end

    observations = simulationResults.observations(dataRows, :);
    observationColumns = observations.ObservationID;
    factorValues = observations.(factorName);
    groups = createSimulationFactorGroups( ...
        factorValues, factorName, groupingMode, ...
        simulationResults.settings.grouping);
    frequencyHz = simulationResults.frequency.frequencyHz(:);

    populationErrors = simulationResults.frequency.(pathway). ...
        populationSisoTruthError(:, observationColumns);
    sisoErrors = simulationResults.frequency.(pathway). ...
        sisoComplexError(:, observationColumns);
    misoErrors = simulationResults.frequency.(pathway). ...
        misoComplexError(:, observationColumns);
    companions.analyticReference = summarizeAnalyticReference( ...
        frequencyHz, groups, populationErrors, sisoErrors, misoErrors);

    outputSnr = simulationResults.frequency.realizedOutputSnrDb(:, ...
        observationColumns);
    companions.realizedOutputSnr = summarizeMatrix( ...
        frequencyHz, groups, outputSnr, ...
        "RealizedOutputSNRdB");

end

function summaryTable = summarizeAnalyticReference( ...
    frequencyHz, groups, populationErrors, sisoErrors, misoErrors)
% summarizeAnalyticReference Compare analytic and empirical errors.

    paired = isfinite(populationErrors) & ...
        isfinite(sisoErrors) & isfinite(misoErrors);
    populationErrors(~paired) = NaN;
    sisoErrors(~paired) = NaN;
    misoErrors(~paired) = NaN;
    analytic = summarizeMatrix( ...
        frequencyHz, groups, populationErrors, "AnalyticSISOBias");
    empiricalSiso = summarizeMatrix( ...
        frequencyHz, groups, sisoErrors, "EmpiricalSISOError");
    empiricalMiso = summarizeMatrix( ...
        frequencyHz, groups, misoErrors, "EmpiricalMISOError");
    analytic.EmpiricalSISOErrorMean = ...
        empiricalSiso.EmpiricalSISOErrorMean;
    analytic.EmpiricalSISOErrorSD = ...
        empiricalSiso.EmpiricalSISOErrorSD;
    analytic.EmpiricalMISOErrorMean = ...
        empiricalMiso.EmpiricalMISOErrorMean;
    analytic.EmpiricalMISOErrorSD = ...
        empiricalMiso.EmpiricalMISOErrorSD;
    analytic.PairedValidN = analytic.ValidN;
    summaryTable = analytic;

end

function summaryTable = summarizeMatrix( ...
    frequencyHz, groups, values, valueName)
% summarizeMatrix Summarize a frequency-by-observation matrix by factor.

    numGroups = numel(groups.centers);
    numFrequencies = numel(frequencyHz);
    rowCount = numGroups*numFrequencies;
    factorValue = NaN(rowCount, 1);
    factorGroup = strings(rowCount, 1);
    frequency = NaN(rowCount, 1);
    meanValue = NaN(rowCount, 1);
    standardDeviation = NaN(rowCount, 1);
    validN = zeros(rowCount, 1);

    row = 0;
    for groupIndex = 1:numGroups
        columns = groups.index == groupIndex;
        for frequencyIndex = 1:numFrequencies
            row = row + 1;
            current = values(frequencyIndex, columns);
            current = current(isfinite(current));
            factorValue(row) = groups.centers(groupIndex);
            factorGroup(row) = groups.labels(groupIndex);
            frequency(row) = frequencyHz(frequencyIndex);
            validN(row) = numel(current);
            if ~isempty(current)
                meanValue(row) = mean(current);
                standardDeviation(row) = std(current, 0);
            end
        end
    end

    summaryTable = table( ...
        factorValue, factorGroup, frequency, meanValue, ...
        standardDeviation, validN, ...
        'VariableNames', { ...
            'FactorValue', 'FactorGroup', 'FrequencyHz', ...
            char(valueName + "Mean"), char(valueName + "SD"), ...
            'ValidN'});

end
