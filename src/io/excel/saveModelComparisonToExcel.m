function saveModelComparisonToExcel(filename, sheetName, misoResults, sisoResults, subjectInfo)

misoBandAverages = misoResults.bandAverages;
sisoBandAverages = sisoResults.bandAverages;

if height(misoBandAverages) ~= height(sisoBandAverages)
    error('MISO and SISO band-average tables do not have the same number of rows.');
end

if any(string(misoBandAverages.Band) ~= string(sisoBandAverages.Band))
    error('MISO and SISO band names do not match.');
end

numBands = height(misoBandAverages);

misoHeader = {
    "Band", ...
    "SubjectID", ...
    "Group", ...
    "Session", ...
    "SourceFile", ...
    "Model", ...
    "MAP_Gain_Mean", ...
    "MAP_Phase_CircularMean_rad", ...
    "CO2_Gain_Mean", ...
    "CO2_Phase_CircularMean_rad", ...
    "Multiple_Coh_Mean", ...
    "MAP_Partial_Coh_Mean", ...
    "CO2_Partial_Coh_Mean", ...
    "Percent_Passed_Multiple_Coh", ...
    "Percent_Passed_MAP_Partial_Coh", ...
    "Percent_Passed_CO2_Partial_Coh"
};

misoRows = cell(numBands, numel(misoHeader));

for b = 1:numBands
    misoRows{b,1} = string(misoBandAverages.Band(b));
    misoRows{b,2} = string(subjectInfo.subjectID);
    misoRows{b,3} = string(subjectInfo.group);
    misoRows{b,4} = string(subjectInfo.session);
    misoRows{b,5} = string(subjectInfo.sourceFile);
    misoRows{b,6} = "MISO";
    misoRows{b,7} = misoBandAverages.MAP_Gain_Mean(b);
    misoRows{b,8} = misoBandAverages.MAP_Phase_CircularMean_rad(b);
    misoRows{b,9} = misoBandAverages.CO2_Gain_Mean(b);
    misoRows{b,10} = misoBandAverages.CO2_Phase_CircularMean_rad(b);
    misoRows{b,11} = misoBandAverages.Multiple_Coh_Mean(b);
    misoRows{b,12} = misoBandAverages.Partial_Coh_MAP_Mean(b);
    misoRows{b,13} = misoBandAverages.Partial_Coh_CO2_Mean(b);
    misoRows{b,14} = misoBandAverages.Percent_Passed_Multiple_Coh(b);
    misoRows{b,15} = misoBandAverages.Percent_Passed_Partial_MAP_Coh(b);
    misoRows{b,16} = misoBandAverages.Percent_Passed_Partial_CO2_Coh(b);
end

sisoHeader = {
    "Band", ...
    "SubjectID", ...
    "Group", ...
    "Session", ...
    "SourceFile", ...
    "Model", ...
    "MAP_Gain_Mean", ...
    "MAP_Phase_CircularMean_rad", ...
    "CO2_Gain_Mean", ...
    "CO2_Phase_CircularMean_rad", ...
    "Multiple_Coh_Mean", ...
    "MAP_CBV_Coh_Mean", ...
    "CO2_CBV_Coh_Mean", ...
    "Percent_Passed_Multiple_Coh", ...
    "Percent_Passed_MAP_CBV_Coh", ...
    "Percent_Passed_CO2_CBV_Coh"
};

sisoRows = cell(numBands, numel(sisoHeader));

for b = 1:numBands
    sisoRows{b,1} = string(sisoBandAverages.Band(b));
    sisoRows{b,2} = string(subjectInfo.subjectID);
    sisoRows{b,3} = string(subjectInfo.group);
    sisoRows{b,4} = string(subjectInfo.session);
    sisoRows{b,5} = string(subjectInfo.sourceFile);
    sisoRows{b,6} = "SISO";
    sisoRows{b,7} = sisoBandAverages.MAP_Gain_Mean(b);
    sisoRows{b,8} = sisoBandAverages.MAP_Phase_CircularMean_rad(b);
    sisoRows{b,9} = sisoBandAverages.CO2_Gain_Mean(b);
    sisoRows{b,10} = sisoBandAverages.CO2_Phase_CircularMean_rad(b);
    sisoRows{b,11} = "-";
    sisoRows{b,12} = sisoBandAverages.MAP_CBV_Coh_Mean(b);
    sisoRows{b,13} = sisoBandAverages.CO2_CBV_Coh_Mean(b);
    sisoRows{b,14} = "-";
    sisoRows{b,15} = sisoBandAverages.Percent_Passed_MAP_CBV_Coh(b);
    sisoRows{b,16} = sisoBandAverages.Percent_Passed_CO2_CBV_Coh(b);
end

blankRow = cell(1, numel(misoHeader));

comparisonCell = [
    misoHeader;
    misoRows;
    blankRow;
    sisoHeader;
    sisoRows
];

writecell(comparisonCell, filename, ...
    "Sheet", sheetName, ...
    "Range", "A1");

end
