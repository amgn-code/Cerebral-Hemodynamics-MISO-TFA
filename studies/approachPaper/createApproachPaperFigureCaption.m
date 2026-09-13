function captionInfo = createApproachPaperFigureCaption( ...
    groupNumber, plotName, plotTitle, sourceData, ...
    exportSettings, details)
% createApproachPaperFigureCaption Build a complete reusable caption.
%
% Caption text is assembled from explicit plot details and from the fields
% retained in the source-data tables. This keeps statistical descriptions
% next to the figure without crowding the graphical title.

    if nargin < 6
        details = struct();
    end

    sourceSummary = inspectSourceData(sourceData);
    context = getCaptionContext(exportSettings);
    evidenceLevel = describeEvidenceLevel( ...
        groupNumber, plotName, context);
    referenceContext = getDetail(details, "referenceContext", "");
    groupingDescription = getDetail( ...
        details, "groupingDescription", ...
        inferGroupingDescription(sourceSummary));
    adjustmentFamily = getDetail( ...
        details, "adjustmentFamily", ...
        inferAdjustmentFamily(sourceSummary));
    inferenceDescription = getDetail( ...
        details, "inferenceDescription", "");
    displayType = lower(getDetail(details, "displayType", "summary"));
    includesModelAdvantage = getLogicalDetail( ...
        details, "includesModelAdvantage", ...
        sourceSummary.hasModelAdvantage || ...
        contains(lower(string(plotTitle)), "model advantage"));

    captionParts = stripTerminalPunctuation(string(plotTitle)) + ".";
    captionParts = appendPart(captionParts, evidenceLevel);
    captionParts = appendPart( ...
        captionParts, formatReferenceContext(referenceContext));
    captionParts = appendPart(captionParts, groupingDescription);

    if sourceSummary.hasFrequency
        captionParts = appendPart(captionParts, ...
            ['Frequency axes use the native Welch frequency bins; ' ...
             'frequency is not rebinned to match the family groups.']);
    end
    captionParts = appendPart( ...
        captionParts, describeSummaries(sourceSummary, displayType));
    captionParts = appendPart( ...
        captionParts, describeInsufficientN( ...
            sourceSummary, displayType, context));
    if strlength(inferenceDescription) > 0
        captionParts = appendPart( ...
            captionParts, inferenceDescription);
    else
        captionParts = appendPart( ...
            captionParts, describeInference( ...
                sourceSummary, adjustmentFamily, context));
    end
    if includesModelAdvantage
        captionParts = appendPart( ...
            captionParts, describeModelAdvantage(context));
    end

    captionInfo = struct();
    captionInfo.Title = string(plotTitle);
    captionInfo.Caption = join(captionParts, " ");
    captionInfo.EvidenceLevel = evidenceLevel;
    captionInfo.ReferenceContext = string(referenceContext);
    captionInfo.GroupingDescription = string(groupingDescription);
    captionInfo.AdjustmentFamily = string(adjustmentFamily);

end

function context = getCaptionContext(exportSettings)
% getCaptionContext Resolve run-level caption metadata.

    context = struct();
    if isfield(exportSettings, "captionContext")
        context = exportSettings.captionContext;
    end
    context = setDefault(context, "profileName", "");
    context = setDefault(context, "numFamilies", NaN);
    context = setDefault(context, "minimumValidN", NaN);
    context = setDefault(context, "alpha", 0.05);
    context = setDefault( ...
        context, "multipleTestingMethod", "Benjamini-Hochberg");
    context = setDefault(context, "errorFloor", NaN);

end

function context = setDefault(context, fieldName, defaultValue)
% setDefault Add a missing context field.

    if ~isfield(context, fieldName)
        context.(fieldName) = defaultValue;
    end

end

function value = getDetail(details, fieldName, defaultValue)
% getDetail Read one optional string-valued caption detail.

    if isfield(details, fieldName)
        value = string(details.(fieldName));
    else
        value = string(defaultValue);
    end

end

function value = getLogicalDetail( ...
    details, fieldName, defaultValue)
% getLogicalDetail Read one optional logical caption detail.

    if isfield(details, fieldName)
        value = logical(details.(fieldName));
    else
        value = logical(defaultValue);
    end

end

function parts = appendPart(parts, newPart)
% appendPart Add nonempty, punctuated text to a caption.

    newPart = strip(string(newPart));
    if strlength(newPart) == 0
        return
    end
    newPart = stripTerminalPunctuation(newPart) + ".";
    parts(end + 1,1) = newPart;

end

function text = stripTerminalPunctuation(text)
% stripTerminalPunctuation Avoid doubled periods in assembled captions.

    text = strip(string(text));
    text = regexprep(text, "[.!?]+$", "");

end

function evidence = describeEvidenceLevel( ...
    groupNumber, plotName, context)
% describeEvidenceLevel Distinguish proof, method, and empirical figures.

    plotName = string(plotName);
    if contains(plotName, "concept")
        evidence = ...
            "This is a conceptual method diagram and does not present numerical evidence";
        return
    end
    if groupNumber == 23
        evidence = "This figure presents the empirical NC analysis";
        return
    end
    if groupNumber == 24
        evidence = "This figure presents empirical NC robustness analyses";
        return
    end
    if groupNumber > 22
        evidence = "";
        return
    end

    profileName = lower(string(context.profileName));
    familyText = formatFamilyCount(context.numFamilies);
    switch profileName
        case "proof250"
            evidence = ...
                "This figure uses the proof250 presentation proof-of-concept simulation" + ...
                familyText + " and is not final-paper evidence";
        case {"quick", "designsmoke"}
            evidence = ...
                "This figure uses a workflow-development simulation" + ...
                familyText + " and is not intended for scientific inference";
        case "paper1000"
            evidence = ...
                "This figure uses the paper1000 simulation" + ...
                familyText;
        otherwise
            evidence = "This figure presents simulated known-truth results" + ...
                familyText;
    end

end

function familyText = formatFamilyCount(numFamilies)
% formatFamilyCount Add the actual independent-family count when known.

    if isfinite(numFamilies)
        familyText = compose( ...
            " (N = %d independent families)", round(numFamilies));
    else
        familyText = "";
    end

end

function referenceText = formatReferenceContext(referenceContext)
% formatReferenceContext Move compact title context into prose.

    referenceText = strip(string(referenceContext));
    if strlength(referenceText) == 0
        return
    end
    referenceText = replace(referenceText, " | ", "; ");
    referenceText = "Analysis context: " + ...
        lowerFirstCharacter(referenceText);

end

function text = lowerFirstCharacter(text)
% lowerFirstCharacter Join title-style context into a sentence.

    text = string(text);
    if strlength(text) > 0
        first = extractBetween(text, 1, 1);
        text = lower(first) + extractAfter(text, 1);
    end

end

function description = inferGroupingDescription(sourceSummary)
% inferGroupingDescription Describe exact levels or fixed intervals.

    if sourceSummary.hasBinnedGroups && sourceSummary.hasExactGroups
        description = ...
            ['Axes combine exact configured values and prespecified ' ...
             'fixed intervals for continuous realized characteristics'];
    elseif sourceSummary.hasBinnedGroups
        description = ...
            ['Grouped axes use prespecified fixed intervals for ' ...
             'continuous realized characteristics'];
    elseif sourceSummary.hasExactGroups
        description = "Grouped axes use exact configured values";
    else
        description = "";
    end

end

function adjustmentFamily = inferAdjustmentFamily(sourceSummary)
% inferAdjustmentFamily Supply a conservative default family description.

    if sourceSummary.hasBHAdjustedP
        adjustmentFamily = ...
            "all hypotheses displayed for each outcome in this figure";
    else
        adjustmentFamily = "";
    end

end

function description = describeSummaries(sourceSummary, displayType)
% describeSummaries State how plotted values and saved statistics relate.

    if ~sourceSummary.hasMean
        description = "";
        return
    end

    if displayType == "heatmap"
        opening = "Heatmap color represents the arithmetic mean across families";
    elseif displayType == "curve"
        opening = "Points and curves represent arithmetic means across families";
    else
        opening = "Displayed summaries use arithmetic means across families";
    end

    reportedFields = strings(0, 1);
    if sourceSummary.hasSD
        reportedFields(end + 1,1) = "SD";
    end
    if sourceSummary.hasValidN
        reportedFields(end + 1,1) = "valid family count";
    end
    if sourceSummary.hasGroupN
        reportedFields(end + 1,1) = "total assigned family count";
    end
    if sourceSummary.hasStandardError
        reportedFields(end + 1,1) = "standard error";
    end
    if sourceSummary.hasConfidenceInterval
        reportedFields(end + 1,1) = "95% confidence interval";
    end

    if isempty(reportedFields)
        description = opening;
    else
        description = opening + ...
            "; the associated source-data files report " + ...
            join(reportedFields, ", ") + " for every available group or cell";
    end

end

function description = describeInsufficientN( ...
    sourceSummary, displayType, context)
% describeInsufficientN State the proof display rule.

    if ~sourceSummary.hasValidN || ...
            ~isfinite(context.minimumValidN)
        description = "";
        return
    end

    thresholdText = compose( ...
        "The prespecified display threshold is %d valid families", ...
        round(context.minimumValidN));
    if displayType == "heatmap"
        description = thresholdText + ...
            "; cells below this threshold remain gray and receive no mean color";
    else
        description = thresholdText + ...
            "; groups below this threshold are insufficient for inferential interpretation";
    end

end

function description = describeInference( ...
    sourceSummary, adjustmentFamily, context)
% describeInference Explain markers and their multiplicity family.

    if ~sourceSummary.hasBHAdjustedP
        description = "";
        return
    end

    description = compose( ...
        ['Black dots or rings mark adjusted P < %.3g after %s ' ...
         'false-discovery-rate correction across %s; raw and adjusted ' ...
         'P values are reported in the source data'], ...
        context.alpha, context.multipleTestingMethod, ...
        adjustmentFamily);

end

function description = describeModelAdvantage(context)
% describeModelAdvantage Define direction and numerical stabilization.

    if isfinite(context.errorFloor)
        floorText = compose(" (epsilon = %.3g)", context.errorFloor);
    else
        floorText = "";
    end
    description = ...
        "Model advantage is log10((SISO error + epsilon)/(MISO error + epsilon))" + ...
        floorText + ...
        "; positive values indicate lower MISO error, zero indicates equal error, and negative values indicate lower SISO error";

end

function summary = inspectSourceData(sourceData)
% inspectSourceData Detect caption-relevant fields recursively.

    summary = emptySourceSummary();
    summary = inspectValue(sourceData, summary);

end

function summary = emptySourceSummary()
% emptySourceSummary Initialize all source-data flags.

    summary = struct( ...
        "hasMean", false, ...
        "hasSD", false, ...
        "hasValidN", false, ...
        "hasGroupN", false, ...
        "hasStandardError", false, ...
        "hasConfidenceInterval", false, ...
        "hasBHAdjustedP", false, ...
        "hasFrequency", false, ...
        "hasModelAdvantage", false, ...
        "hasExactGroups", false, ...
        "hasBinnedGroups", false);

end

function summary = inspectValue(value, summary)
% inspectValue Recursively inspect tables and structures.

    if istable(value)
        summary = inspectTable(value, summary);
        return
    end
    if isstruct(value)
        fieldNames = fieldnames(value);
        for fieldIndex = 1:numel(fieldNames)
            summary = inspectValue( ...
                value.(fieldNames{fieldIndex}), summary);
        end
    end

end

function summary = inspectTable(sourceTable, summary)
% inspectTable Detect statistical columns and grouping boundaries.

    names = string(sourceTable.Properties.VariableNames);
    summary.hasMean = summary.hasMean || ...
        any(names == "Mean" | endsWith(names, "Mean") | ...
            contains(names, "MeanAdvantage"));
    summary.hasSD = summary.hasSD || ...
        any(names == "SD" | endsWith(names, "SD"));
    summary.hasValidN = summary.hasValidN || ...
        any(names == "ValidN" | endsWith(names, "ValidN"));
    summary.hasGroupN = summary.hasGroupN || any(names == "GroupN");
    summary.hasStandardError = summary.hasStandardError || ...
        any(names == "StandardError" | endsWith(names, "StandardError"));
    summary.hasConfidenceInterval = ...
        summary.hasConfidenceInterval || ...
        (any(names == "CILower" | endsWith(names, "CILower")) && ...
         any(names == "CIUpper" | endsWith(names, "CIUpper")));
    summary.hasBHAdjustedP = summary.hasBHAdjustedP || ...
        any(names == "BHAdjustedP" | endsWith(names, "BHAdjustedP"));
    summary.hasFrequency = summary.hasFrequency || ...
        any(names == "FrequencyHz");
    summary.hasModelAdvantage = summary.hasModelAdvantage || ...
        any(contains(names, "Advantage", "IgnoreCase", true));

    if all(ismember(["FactorLower", "FactorUpper"], names))
        lowerValues = sourceTable.FactorLower;
        upperValues = sourceTable.FactorUpper;
        finitePairs = isfinite(lowerValues) & isfinite(upperValues);
        summary.hasExactGroups = summary.hasExactGroups || ...
            any(finitePairs & lowerValues == upperValues);
        summary.hasBinnedGroups = summary.hasBinnedGroups || ...
            any(finitePairs & lowerValues ~= upperValues);
    end

end
