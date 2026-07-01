function saveMISOBandAveragesToExcel(filename, sheetName, tfaResults, subjectInfo)

bandAverages = addSubjectMetadataToBandAverages( ...
    tfaResults.bandAverages, tfaResults.welchInfo, subjectInfo);

writetable(bandAverages, filename, ...
    "Sheet", sheetName, ...
    "Range", "A1");

end
