function groupModelResults = createGroupModelResults( ...
    subjectResults, groupName, modelName, phaseSettings)
% createGroupModelResults Collect one group's subject arrays and summaries.

    includedSubjects = cell(numel(subjectResults), 1);
    numIncludedSubjects = 0;

    for k = 1:numel(subjectResults)
        if isempty(subjectResults{k}) || ...
                ~subjectResults{k}.runStatus.analysisSucceeded || ...
                upper(string(subjectResults{k}.subjectInfo.group)) ~= ...
                upper(groupName)
            continue
        end

        if modelName == "miso"
            modelResults = subjectResults{k}.tfaResults;
        else
            modelResults = subjectResults{k}.sisoResults;
        end

        if isempty(modelResults)
            continue
        end

        numIncludedSubjects = numIncludedSubjects + 1;
        includedSubjects{numIncludedSubjects} = subjectResults{k};
    end

    includedSubjects = includedSubjects(1:numIncludedSubjects);

    if isempty(includedSubjects)
        groupModelResults = [];
        return
    end

    firstSubject = includedSubjects{1};

    if modelName == "miso"
        firstResults = firstSubject.tfaResults;
    else
        firstResults = firstSubject.sisoResults;
    end

    f = firstResults.f(:);
    numFrequencies = numel(f);
    subjectIds = strings(numIncludedSubjects, 1);

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
        mapUnexplainedFraction = NaN(numFrequencies, numIncludedSubjects);
        co2UnexplainedFraction = NaN(numFrequencies, numIncludedSubjects);
        mapResidualPowerDb = NaN(numFrequencies, numIncludedSubjects);
        co2ResidualPowerDb = NaN(numFrequencies, numIncludedSubjects);
    end

    for subjectIndex = 1:numIncludedSubjects
        subjectResult = includedSubjects{subjectIndex};
        subjectIds(subjectIndex) = string( ...
            subjectResult.subjectInfo.subjectID);

        if modelName == "miso"
            results = subjectResult.tfaResults;
        else
            results = subjectResult.sisoResults;
        end

        mapPowerDb(:,subjectIndex) = powerToDb(results.map.power(:));
        co2PowerDb(:,subjectIndex) = powerToDb(results.co2.power(:));
        cbvPowerDb(:,subjectIndex) = powerToDb(results.cbv.power(:));
        mapGain(:,subjectIndex) = results.map.gain(:);
        mapPhaseWrapped(:,subjectIndex) = results.map.phase.wrapped(:);
        mapPhaseUnwrapped(:,subjectIndex) = results.map.phase.unwrapped(:);
        co2Gain(:,subjectIndex) = results.co2.gain(:);
        co2PhaseWrapped(:,subjectIndex) = results.co2.phase.wrapped(:);
        co2PhaseUnwrapped(:,subjectIndex) = results.co2.phase.unwrapped(:);
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

    groupModelResults.f = f;
    groupModelResults.subjectIds = subjectIds;
    groupModelResults.phaseUnwrapMethod = string(phaseSettings.unwrapMethod);

    mapPower = summarizeGroupValues(mapPowerDb);
    co2Power = summarizeGroupValues(co2PowerDb);
    cbvPower = summarizeGroupValues(cbvPowerDb);
    groupModelResults.map.power.valuesDb = mapPower.values;
    groupModelResults.map.power.meanDb = mapPower.mean;
    groupModelResults.map.power.sdDb = mapPower.sd;
    groupModelResults.co2.power.valuesDb = co2Power.values;
    groupModelResults.co2.power.meanDb = co2Power.mean;
    groupModelResults.co2.power.sdDb = co2Power.sd;
    groupModelResults.cbv.power.valuesDb = cbvPower.values;
    groupModelResults.cbv.power.meanDb = cbvPower.mean;
    groupModelResults.cbv.power.sdDb = cbvPower.sd;

    groupModelResults.map.gain = summarizeGroupValues(mapGain);
    groupModelResults.co2.gain = summarizeGroupValues(co2Gain);
    groupModelResults.inputRelationship.coherence = ...
        summarizeGroupValues(inputCoherence);

    mapCoherenceSummary = summarizeGroupValues(mapCoherence);
    co2CoherenceSummary = summarizeGroupValues(co2Coherence);
    inputCoherenceMean = ...
        groupModelResults.inputRelationship.coherence.mean;

    groupModelResults.map.phase = summarizeGroupPhase( ...
        mapPhaseWrapped, mapPhaseUnwrapped, f, ...
        mapCoherenceSummary.mean, phaseSettings);
    groupModelResults.co2.phase = summarizeGroupPhase( ...
        co2PhaseWrapped, co2PhaseUnwrapped, f, ...
        co2CoherenceSummary.mean, phaseSettings);
    groupModelResults.inputRelationship.phase = summarizeGroupPhase( ...
        inputPhaseWrapped, inputPhaseUnwrapped, f, ...
        inputCoherenceMean, phaseSettings);

    if modelName == "miso"
        groupModelResults.map.coherence.partial = mapCoherenceSummary;
        groupModelResults.co2.coherence.partial = co2CoherenceSummary;
        groupModelResults.system.multipleCoherence = ...
            summarizeGroupValues(multipleCoherence);
        groupModelResults.system.unexplainedFraction = ...
            summarizeGroupValues(unexplainedFraction);
        groupModelResults.system.residualPower = ...
            summarizeGroupValues(residualPowerDb);
        groupModelResults.diagnostics.conditionNumber = ...
            summarizeGroupValues(conditionNumber);
    else
        groupModelResults.map.coherence.pairwise = mapCoherenceSummary;
        groupModelResults.co2.coherence.pairwise = co2CoherenceSummary;
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
