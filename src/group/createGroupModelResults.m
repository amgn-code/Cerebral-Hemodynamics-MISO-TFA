function groupModelResults = createGroupModelResults( ...
    subjectResults, groupName, modelName, phaseSettings)
% createGroupModelResults Collect one group's subject arrays and summaries.

    groupName = upper(string(groupName));
    modelName = lower(string(modelName));

    if modelName ~= "miso" && modelName ~= "siso"
        error( ...
            'TFA:UnknownModelName', ...
            'modelName must be "miso" or "siso".');
    end

    %% Select Successful Subjects

    selectedModelResults = cell(numel(subjectResults), 1);
    subjectIds = strings(numel(subjectResults), 1);
    numIncludedSubjects = 0;

    for subjectIndex = 1:numel(subjectResults)
        currentSubject = subjectResults{subjectIndex};

        if isempty(currentSubject)
            continue
        end

        if ~currentSubject.runStatus.analysisSucceeded
            continue
        end

        subjectGroup = upper(string(currentSubject.subjectInfo.group));
        if subjectGroup ~= groupName
            continue
        end

        if modelName == "miso"
            currentModelResults = currentSubject.misoResults;
        else
            currentModelResults = currentSubject.sisoResults;
        end

        if isempty(currentModelResults)
            continue
        end

        numIncludedSubjects = numIncludedSubjects + 1;
        selectedModelResults{numIncludedSubjects} = currentModelResults;
        subjectIds(numIncludedSubjects) = ...
            string(currentSubject.subjectInfo.subjectID);
    end

    if numIncludedSubjects == 0
        groupModelResults = [];
        return
    end

    selectedModelResults = ...
        selectedModelResults(1:numIncludedSubjects);
    subjectIds = subjectIds(1:numIncludedSubjects);

    %% Allocate Subject Arrays

    firstSubjectResults = selectedModelResults{1};
    frequencyHz = firstSubjectResults.f(:);
    numFrequencies = numel(frequencyHz);

    mapPowerDb = NaN(numFrequencies, numIncludedSubjects);
    co2PowerDb = NaN(numFrequencies, numIncludedSubjects);
    cbvPowerDb = NaN(numFrequencies, numIncludedSubjects);
    mapGain = NaN(numFrequencies, numIncludedSubjects);
    mapPhaseWrapped = NaN(numFrequencies, numIncludedSubjects);
    mapPhaseUnwrapped = NaN(numFrequencies, numIncludedSubjects);
    co2Gain = NaN(numFrequencies, numIncludedSubjects);
    co2PhaseWrapped = NaN(numFrequencies, numIncludedSubjects);
    co2PhaseUnwrapped = NaN(numFrequencies, numIncludedSubjects);
    mapCoherence = NaN(numFrequencies, numIncludedSubjects);
    co2Coherence = NaN(numFrequencies, numIncludedSubjects);
    inputCoherence = NaN(numFrequencies, numIncludedSubjects);
    inputPhaseWrapped = NaN(numFrequencies, numIncludedSubjects);
    inputPhaseUnwrapped = NaN(numFrequencies, numIncludedSubjects);

    if modelName == "miso"
        multipleCoherence = NaN(numFrequencies, numIncludedSubjects);
        unexplainedFraction = NaN(numFrequencies, numIncludedSubjects);
        residualPowerDb = NaN(numFrequencies, numIncludedSubjects);
        conditionNumber = NaN(numFrequencies, numIncludedSubjects);
    else
        mapUnexplainedFraction = NaN( ...
            numFrequencies, numIncludedSubjects);
        co2UnexplainedFraction = NaN( ...
            numFrequencies, numIncludedSubjects);
        mapResidualPowerDb = NaN(numFrequencies, numIncludedSubjects);
        co2ResidualPowerDb = NaN(numFrequencies, numIncludedSubjects);
    end

    %% Collect Each Subject's Results

    for subjectIndex = 1:numIncludedSubjects
        results = selectedModelResults{subjectIndex};

        if ~isequal(results.f(:), frequencyHz)
            error( ...
                'TFA:InconsistentFrequencyBins', ...
                ['Subjects in one group must use the same frequency ' ...
                 'bins before group statistics are calculated.']);
        end

        mapPowerDb(:,subjectIndex) = powerToDb(results.map.power(:));
        co2PowerDb(:,subjectIndex) = powerToDb(results.co2.power(:));
        cbvPowerDb(:,subjectIndex) = powerToDb(results.cbv.power(:));
        mapGain(:,subjectIndex) = results.map.gain(:);
        mapPhaseWrapped(:,subjectIndex) = ...
            results.map.phase.wrapped(:);
        mapPhaseUnwrapped(:,subjectIndex) = ...
            results.map.phase.unwrapped(:);
        co2Gain(:,subjectIndex) = results.co2.gain(:);
        co2PhaseWrapped(:,subjectIndex) = ...
            results.co2.phase.wrapped(:);
        co2PhaseUnwrapped(:,subjectIndex) = ...
            results.co2.phase.unwrapped(:);
        inputCoherence(:,subjectIndex) = ...
            results.inputRelationship.coherence(:);
        inputPhaseWrapped(:,subjectIndex) = ...
            results.inputRelationship.phase.wrapped(:);
        inputPhaseUnwrapped(:,subjectIndex) = ...
            results.inputRelationship.phase.unwrapped(:);

        if modelName == "miso"
            mapCoherence(:,subjectIndex) = ...
                results.map.coherence.partial(:);
            co2Coherence(:,subjectIndex) = ...
                results.co2.coherence.partial(:);
            multipleCoherence(:,subjectIndex) = ...
                results.system.multipleCoherence(:);
            unexplainedFraction(:,subjectIndex) = ...
                results.system.unexplainedFraction(:);
            residualPowerDb(:,subjectIndex) = ...
                powerToDb(results.system.residualPower(:));
            conditionNumber(:,subjectIndex) = ...
                results.diagnostics.conditionNumber(:);
        else
            mapCoherence(:,subjectIndex) = ...
                results.map.coherence.pairwise(:);
            co2Coherence(:,subjectIndex) = ...
                results.co2.coherence.pairwise(:);
            mapUnexplainedFraction(:,subjectIndex) = ...
                results.map.unexplainedFraction(:);
            co2UnexplainedFraction(:,subjectIndex) = ...
                results.co2.unexplainedFraction(:);
            mapResidualPowerDb(:,subjectIndex) = ...
                powerToDb(results.map.residualPower(:));
            co2ResidualPowerDb(:,subjectIndex) = ...
                powerToDb(results.co2.residualPower(:));
        end
    end

    %% Summarize Quantities Shared by Both Models

    groupModelResults.f = frequencyHz;
    groupModelResults.subjectIds = subjectIds;
    groupModelResults.phaseUnwrapMethod = ...
        string(phaseSettings.unwrapMethod);

    mapPowerSummary = summarizeGroupValues(mapPowerDb);
    co2PowerSummary = summarizeGroupValues(co2PowerDb);
    cbvPowerSummary = summarizeGroupValues(cbvPowerDb);

    groupModelResults.map.power.valuesDb = mapPowerSummary.values;
    groupModelResults.map.power.meanDb = mapPowerSummary.mean;
    groupModelResults.map.power.sdDb = mapPowerSummary.sd;

    groupModelResults.co2.power.valuesDb = co2PowerSummary.values;
    groupModelResults.co2.power.meanDb = co2PowerSummary.mean;
    groupModelResults.co2.power.sdDb = co2PowerSummary.sd;

    groupModelResults.cbv.power.valuesDb = cbvPowerSummary.values;
    groupModelResults.cbv.power.meanDb = cbvPowerSummary.mean;
    groupModelResults.cbv.power.sdDb = cbvPowerSummary.sd;

    groupModelResults.map.gain = summarizeGroupValues(mapGain);
    groupModelResults.co2.gain = summarizeGroupValues(co2Gain);

    inputCoherenceSummary = summarizeGroupValues(inputCoherence);
    groupModelResults.inputRelationship.coherence = ...
        inputCoherenceSummary;

    mapCoherenceSummary = summarizeGroupValues(mapCoherence);
    co2CoherenceSummary = summarizeGroupValues(co2Coherence);

    groupModelResults.map.phase = summarizeGroupPhase( ...
        mapPhaseWrapped, mapPhaseUnwrapped, frequencyHz, ...
        mapCoherenceSummary.mean, phaseSettings);
    groupModelResults.co2.phase = summarizeGroupPhase( ...
        co2PhaseWrapped, co2PhaseUnwrapped, frequencyHz, ...
        co2CoherenceSummary.mean, phaseSettings);
    groupModelResults.inputRelationship.phase = summarizeGroupPhase( ...
        inputPhaseWrapped, inputPhaseUnwrapped, frequencyHz, ...
        inputCoherenceSummary.mean, phaseSettings);

    %% Summarize Model-Specific Quantities

    if modelName == "miso"
        groupModelResults.map.coherence.partial = ...
            mapCoherenceSummary;
        groupModelResults.co2.coherence.partial = ...
            co2CoherenceSummary;
        groupModelResults.system.multipleCoherence = ...
            summarizeGroupValues(multipleCoherence);
        groupModelResults.system.unexplainedFraction = ...
            summarizeGroupValues(unexplainedFraction);
        groupModelResults.system.residualPower = ...
            summarizeGroupValues(residualPowerDb);
        groupModelResults.diagnostics.conditionNumber = ...
            summarizeGroupValues(conditionNumber);
    else
        groupModelResults.map.coherence.pairwise = ...
            mapCoherenceSummary;
        groupModelResults.co2.coherence.pairwise = ...
            co2CoherenceSummary;
        groupModelResults.map.unexplainedFraction = ...
            summarizeGroupValues(mapUnexplainedFraction);
        groupModelResults.co2.unexplainedFraction = ...
            summarizeGroupValues(co2UnexplainedFraction);
        groupModelResults.map.residualPower = ...
            summarizeGroupValues(mapResidualPowerDb);
        groupModelResults.co2.residualPower = ...
            summarizeGroupValues(co2ResidualPowerDb);
    end

end
