function summary = summarizeGroupValues(subjectValues)
% summarizeGroupValues Store subject values with row-wise mean and SD.

    summary.values = subjectValues;
    summary.mean = mean(subjectValues, 2, 'omitnan');
    summary.sd = std(subjectValues, 0, 2, 'omitnan');

    numValues = sum(isfinite(subjectValues), 2);
    summary.mean(numValues == 0) = NaN;
    summary.sd(numValues < 2) = NaN;

end
