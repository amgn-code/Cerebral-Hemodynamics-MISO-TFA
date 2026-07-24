function frequencyResults = calculateFrequencyWiseStatistics( ...
    groupResults, analysisSettings)
% calculateFrequencyWiseStatistics Compare subjects at each frequency bin.
%
% These tests are exploratory. Each subject contributes one value at each
% frequency. Benjamini-Hochberg adjustment is applied across the frequency
% bins belonging to one comparison curve.

    settings = analysisSettings.statistics;
    frequencySettings = settings.frequencyWise;
    groupNames = upper(string(settings.groupsToCompare(:)));
    pathways = ["MAP"; "CO2"];

    if ~isfield(settings, "withinGroupModelComparison")
        settings.withinGroupModelComparison.enabled = true;
    end
    if ~isfield(settings, "betweenGroupComparison")
        settings.betweenGroupComparison.enabled = ...
            numel(groupNames) == 2;
    end

    groupComparisons = table();
    modelComparisons = table();

    %% Select the Enabled Metrics

    groupMetrics = strings(0, 1);
    if frequencySettings.groupComparison.gain
        groupMetrics(end + 1,1) = "Gain";
    end
    if frequencySettings.groupComparison.coherence
        groupMetrics(end + 1,1) = "Coherence";
    end
    if frequencySettings.groupComparison.phase
        groupMetrics(end + 1,1) = "Phase";
    end

    modelMetrics = strings(0, 1);
    if frequencySettings.modelComparison.gain
        modelMetrics(end + 1,1) = "Gain";
    end
    if frequencySettings.modelComparison.phase
        modelMetrics(end + 1,1) = "Phase";
    end

    %% Compare the Two Groups at Every Frequency

    bothMisoGroupsAvailable = false;
    if settings.betweenGroupComparison.enabled && ...
            numel(groupNames) == 2
        firstGroupName = groupNames(1);
        secondGroupName = groupNames(2);
        firstGroupField = char(firstGroupName);
        secondGroupField = char(secondGroupName);
        bothMisoGroupsAvailable = ...
            isfield(groupResults, firstGroupField) && ...
            isfield(groupResults, secondGroupField) && ...
            isfield(groupResults.(firstGroupField), "miso") && ...
            isfield(groupResults.(secondGroupField), "miso");
    end

    if bothMisoGroupsAvailable
        firstMiso = groupResults.(firstGroupField).miso;
        secondMiso = groupResults.(secondGroupField).miso;

        if ~isequal(firstMiso.f(:), secondMiso.f(:))
            error( ...
                'TFA:InconsistentFrequencyBins', ...
                'The two groups must use the same frequency bins.');
        end

        frequencyHz = firstMiso.f(:);
        frequencyMask = frequencyHz >= ...
            analysisSettings.frequencyRangeHz(1) & ...
            frequencyHz <= analysisSettings.frequencyRangeHz(2);
        selectedFrequencyIndices = find(frequencyMask);

        for metricIndex = 1:numel(groupMetrics)
            metric = groupMetrics(metricIndex);

            for pathwayIndex = 1:numel(pathways)
                pathway = pathways(pathwayIndex);

                if pathway == "MAP" && metric == "Gain"
                    firstValues = firstMiso.map.gain.values;
                    secondValues = secondMiso.map.gain.values;
                elseif pathway == "CO2" && metric == "Gain"
                    firstValues = firstMiso.co2.gain.values;
                    secondValues = secondMiso.co2.gain.values;
                elseif pathway == "MAP" && metric == "Coherence"
                    firstValues = ...
                        firstMiso.map.coherence.partial.values;
                    secondValues = ...
                        secondMiso.map.coherence.partial.values;
                elseif pathway == "CO2" && metric == "Coherence"
                    firstValues = ...
                        firstMiso.co2.coherence.partial.values;
                    secondValues = ...
                        secondMiso.co2.coherence.partial.values;
                elseif pathway == "MAP"
                    firstValues = firstMiso.map.phase.wrapped.values;
                    secondValues = secondMiso.map.phase.wrapped.values;
                else
                    firstValues = firstMiso.co2.phase.wrapped.values;
                    secondValues = secondMiso.co2.phase.wrapped.values;
                end

                for selectedIndex = 1:numel(selectedFrequencyIndices)
                    frequencyIndex = ...
                        selectedFrequencyIndices(selectedIndex);
                    if metric == "Phase" && ...
                            frequencyHz(frequencyIndex) <= 0
                        continue
                    end
                    firstFrequencyValues = ...
                        firstValues(frequencyIndex,:)';
                    secondFrequencyValues = ...
                        secondValues(frequencyIndex,:)';

                    if metric == "Phase"
                        comparison = compareCircularValues( ...
                            firstFrequencyValues, ...
                            secondFrequencyValues, "independent", ...
                            settings.numPhasePermutations);
                        nFirst = comparison.nFirst;
                        nSecond = comparison.nSecond;
                        firstMean = comparison.meanFirst;
                        secondMean = comparison.meanSecond;
                        difference = comparison.difference;
                        rawP = comparison.pValue;
                        ciLower = NaN;
                        ciUpper = NaN;
                        effectSize = NaN;
                        testName = "Independent circular permutation";

                        finiteFirstValues = firstFrequencyValues( ...
                            isfinite(firstFrequencyValues));
                        finiteSecondValues = secondFrequencyValues( ...
                            isfinite(secondFrequencyValues));
                        firstSd = NaN;
                        secondSd = NaN;
                        if numel(finiteFirstValues) >= 2
                            firstSd = circularStdPhase( ...
                                finiteFirstValues);
                        end
                        if numel(finiteSecondValues) >= 2
                            secondSd = circularStdPhase( ...
                                finiteSecondValues);
                        end
                        notes = "Wrapped phase; circular difference";
                    else
                        comparison = ...
                            compareIndependentArithmeticValues( ...
                                firstFrequencyValues, ...
                                secondFrequencyValues, settings.alpha);
                        nFirst = comparison.nFirst;
                        nSecond = comparison.nSecond;
                        firstMean = comparison.meanFirst;
                        secondMean = comparison.meanSecond;
                        difference = comparison.difference;
                        rawP = comparison.pValue;
                        ciLower = comparison.ciLower;
                        ciUpper = comparison.ciUpper;
                        effectSize = comparison.effectSize;
                        testName = "Welch two-sample t-test";
                        firstSd = std( ...
                            firstFrequencyValues, 0, 'omitnan');
                        secondSd = std( ...
                            secondFrequencyValues, 0, 'omitnan');
                        notes = "Exploratory frequency-wise comparison";
                    end

                    multiplicityFamily = ...
                        "FREQUENCY_BETWEEN_MISO_" + pathway + "_" + ...
                        metric + "_EXPLORATORY";
                    newRow = table( ...
                        frequencyHz(frequencyIndex), "MISO", ...
                        pathway, metric, firstGroupName, ...
                        secondGroupName, nFirst, nSecond, firstMean, ...
                        secondMean, firstSd, secondSd, difference, ...
                        ciLower, ciUpper, effectSize, testName, ...
                        multiplicityFamily, rawP, NaN, false, notes, ...
                        'VariableNames', { ...
                            'FrequencyHz', 'Model', 'Pathway', ...
                            'Metric', 'FirstGroup', 'SecondGroup', ...
                            'NFirst', 'NSecond', 'FirstMean', ...
                            'SecondMean', 'FirstSD', 'SecondSD', ...
                            'FirstMinusSecond', 'CILower', 'CIUpper', ...
                            'EffectSize', 'Test', ...
                            'MultiplicityFamily', 'RawP', ...
                            'BHAdjustedP', 'IsSignificant', 'Notes'});
                    groupComparisons = [groupComparisons; newRow];
                end
            end
        end
    end

    %% Compare MISO and SISO at Every Frequency

    for groupIndex = 1:numel(groupNames)
        if ~settings.withinGroupModelComparison.enabled
            continue
        end

        groupName = groupNames(groupIndex);
        groupField = char(groupName);

        bothModelsAvailable = isfield(groupResults, groupField) && ...
            isfield(groupResults.(groupField), "miso") && ...
            isfield(groupResults.(groupField), "siso");
        if ~bothModelsAvailable
            continue
        end

        miso = groupResults.(groupField).miso;
        siso = groupResults.(groupField).siso;
        if ~isequal(miso.f(:), siso.f(:))
            error( ...
                'TFA:InconsistentFrequencyBins', ...
                'MISO and SISO must use the same frequency bins.');
        end

        [commonSubjectIds, misoIndices, sisoIndices] = intersect( ...
            miso.subjectIds, siso.subjectIds, "stable");
        frequencyHz = miso.f(:);
        frequencyMask = frequencyHz >= ...
            analysisSettings.frequencyRangeHz(1) & ...
            frequencyHz <= analysisSettings.frequencyRangeHz(2);
        selectedFrequencyIndices = find(frequencyMask);

        for metricIndex = 1:numel(modelMetrics)
            metric = modelMetrics(metricIndex);

            for pathwayIndex = 1:numel(pathways)
                pathway = pathways(pathwayIndex);

                if pathway == "MAP" && metric == "Gain"
                    misoValues = miso.map.gain.values(:,misoIndices);
                    sisoValues = siso.map.gain.values(:,sisoIndices);
                    misoCoherenceValues = ...
                        miso.map.coherence.partial.values(:,misoIndices);
                    sisoCoherenceValues = ...
                        siso.map.coherence.pairwise.values(:,sisoIndices);
                elseif pathway == "CO2" && metric == "Gain"
                    misoValues = miso.co2.gain.values(:,misoIndices);
                    sisoValues = siso.co2.gain.values(:,sisoIndices);
                    misoCoherenceValues = ...
                        miso.co2.coherence.partial.values(:,misoIndices);
                    sisoCoherenceValues = ...
                        siso.co2.coherence.pairwise.values(:,sisoIndices);
                elseif pathway == "MAP"
                    misoValues = ...
                        miso.map.phase.wrapped.values(:,misoIndices);
                    sisoValues = ...
                        siso.map.phase.wrapped.values(:,sisoIndices);
                    misoCoherenceValues = ...
                        miso.map.coherence.partial.values(:,misoIndices);
                    sisoCoherenceValues = ...
                        siso.map.coherence.pairwise.values(:,sisoIndices);
                else
                    misoValues = ...
                        miso.co2.phase.wrapped.values(:,misoIndices);
                    sisoValues = ...
                        siso.co2.phase.wrapped.values(:,sisoIndices);
                    misoCoherenceValues = ...
                        miso.co2.coherence.partial.values(:,misoIndices);
                    sisoCoherenceValues = ...
                        siso.co2.coherence.pairwise.values(:,sisoIndices);
                end

                for selectedIndex = 1:numel(selectedFrequencyIndices)
                    frequencyIndex = ...
                        selectedFrequencyIndices(selectedIndex);
                    if metric == "Phase" && ...
                            frequencyHz(frequencyIndex) <= 0
                        continue
                    end
                    misoFrequencyValues = ...
                        misoValues(frequencyIndex,:)';
                    sisoFrequencyValues = ...
                        sisoValues(frequencyIndex,:)';
                    misoCoherenceMean = mean( ...
                        misoCoherenceValues(frequencyIndex,:), ...
                        "omitnan");
                    sisoCoherenceMean = mean( ...
                        sisoCoherenceValues(frequencyIndex,:), ...
                        "omitnan");
                    differenceDegrees = NaN;
                    principalDelayDifferenceSeconds = NaN;
                    delayModuloSeconds = NaN;

                    if metric == "Phase"
                        comparison = compareCircularValues( ...
                            misoFrequencyValues, sisoFrequencyValues, ...
                            "paired", settings.numPhasePermutations);
                        n = comparison.nFirst;
                        misoMean = comparison.meanFirst;
                        sisoMean = comparison.meanSecond;
                        difference = comparison.difference;
                        rawP = comparison.pValue;
                        ciLower = NaN;
                        ciUpper = NaN;
                        effectSize = NaN;
                        testName = "Paired circular permutation";

                        finiteMisoValues = misoFrequencyValues( ...
                            isfinite(misoFrequencyValues));
                        finiteSisoValues = sisoFrequencyValues( ...
                            isfinite(sisoFrequencyValues));
                        misoSd = NaN;
                        sisoSd = NaN;
                        if numel(finiteMisoValues) >= 2
                            misoSd = circularStdPhase(finiteMisoValues);
                        end
                        if numel(finiteSisoValues) >= 2
                            sisoSd = circularStdPhase(finiteSisoValues);
                        end
                        differenceDegrees = rad2deg(difference);
                        currentFrequencyHz = ...
                            frequencyHz(frequencyIndex);
                        if currentFrequencyHz > 0
                            principalDelayDifferenceSeconds = ...
                                -difference/(2*pi*currentFrequencyHz);
                            delayModuloSeconds = 1/currentFrequencyHz;
                        end
                        notes = ...
                            "Wrapped phase; principal delay difference is " + ...
                            "-phase difference/(2*pi*f) and is modulo 1/f";
                    else
                        comparison = comparePairedArithmeticValues( ...
                            misoFrequencyValues, sisoFrequencyValues, ...
                            settings.alpha);
                        n = comparison.n;
                        misoMean = comparison.meanFirst;
                        sisoMean = comparison.meanSecond;
                        difference = comparison.difference;
                        rawP = comparison.pValue;
                        ciLower = comparison.ciLower;
                        ciUpper = comparison.ciUpper;
                        effectSize = comparison.effectSize;
                        testName = "Paired t-test";
                        misoSd = std( ...
                            misoFrequencyValues, 0, 'omitnan');
                        sisoSd = std( ...
                            sisoFrequencyValues, 0, 'omitnan');
                        notes = "Exploratory frequency-wise comparison";
                    end

                    multiplicityFamily = ...
                        "FREQUENCY_" + groupName + "_" + pathway + ...
                        "_" + metric + "_EXPLORATORY";
                    newRow = table( ...
                        frequencyHz(frequencyIndex), groupName, ...
                        pathway, metric, n, numel(commonSubjectIds), ...
                        misoMean, sisoMean, misoSd, sisoSd, ...
                        difference, ciLower, ciUpper, effectSize, ...
                        differenceDegrees, ...
                        principalDelayDifferenceSeconds, ...
                        delayModuloSeconds, ...
                        misoCoherenceMean, sisoCoherenceMean, ...
                        testName, multiplicityFamily, rawP, NaN, ...
                        false, notes, ...
                        'VariableNames', { ...
                            'FrequencyHz', 'Group', 'Pathway', ...
                            'Metric', 'N', 'NumMatchedSubjectIDs', ...
                            'MISOMean', 'SISOMean', 'MISOSD', ...
                            'SISOSD', 'MISOminusSISO', 'CILower', ...
                            'CIUpper', 'EffectSize', ...
                            'MISOminusSISODegrees', ...
                            'PrincipalDelayDifferenceSeconds', ...
                            'DelayModuloSeconds', ...
                            'MISOCoherenceMean', ...
                            'SISOCoherenceMean', 'Test', ...
                            'MultiplicityFamily', 'RawP', ...
                            'BHAdjustedP', 'IsSignificant', 'Notes'});
                    modelComparisons = [modelComparisons; newRow];
                end
            end
        end
    end

    %% Adjust P Values Across the Bins in Each Comparison Curve

    if ~isempty(groupComparisons)
        for metricIndex = 1:numel(groupMetrics)
            for pathwayIndex = 1:numel(pathways)
                rowMask = groupComparisons.Metric == ...
                    groupMetrics(metricIndex) & ...
                    groupComparisons.Pathway == pathways(pathwayIndex);
                groupComparisons.BHAdjustedP(rowMask) = ...
                    adjustPValuesBenjaminiHochberg( ...
                        groupComparisons.RawP(rowMask));
            end
        end
        groupComparisons.IsSignificant = ...
            groupComparisons.BHAdjustedP < settings.alpha;
    end

    if ~isempty(modelComparisons)
        for groupIndex = 1:numel(groupNames)
            for metricIndex = 1:numel(modelMetrics)
                for pathwayIndex = 1:numel(pathways)
                    rowMask = modelComparisons.Group == ...
                        groupNames(groupIndex) & ...
                        modelComparisons.Metric == ...
                        modelMetrics(metricIndex) & ...
                        modelComparisons.Pathway == pathways(pathwayIndex);
                    modelComparisons.BHAdjustedP(rowMask) = ...
                        adjustPValuesBenjaminiHochberg( ...
                            modelComparisons.RawP(rowMask));
                end
            end
        end
        modelComparisons.IsSignificant = ...
            modelComparisons.BHAdjustedP < settings.alpha;
    end

    frequencyResults.groupComparisons = groupComparisons;
    frequencyResults.modelComparisons = modelComparisons;

end
