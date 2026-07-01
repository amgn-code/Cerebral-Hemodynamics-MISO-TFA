function saveSISOBandAveragesToExcel(filename, sheetName, sisoResults, subjectInfo)

bandAverages = addSubjectMetadataToBandAverages( ...
    sisoResults.bandAverages, sisoResults.welchInfo, subjectInfo);

writetable(bandAverages, filename, ...
    "Sheet", sheetName, ...
    "Range", "A1");

end
