function signalData = loadExcelTFAData(filename)
% loadExcelTFAData
%
% Loads BP/MAP, CO2, and CBF/CBFV data from an Excel sheet, resamples
% the signals to 4 Hz, and returns the same struct format used by
% createShoMisoSignal().
%
% Expected Excel columns:
%   Time   BP   CO2   CBF
%
% Acceptable alternative column names:
%   Time: time, t, seconds, sec
%   BP:   bp, map, abp
%   CO2:  co2, petco2, etco2
%   CBF:  cbf, cbv, cbfv
%
% Output:
%   signalData.bp
%   signalData.co2
%   signalData.cbf
%   signalData.fs
%   signalData.t
 
    %% Read Excel file as a table
    dataTable = readtable(filename, 'Sheet', 'Sheet1');

    timeCol = "Time";
    bpCol  = "MAP";
    cbfCol = "Vmean";
    co2Col = "ETCO2";

    %% Extract signals
    t   = dataTable{:, timeCol};
    bp  = dataTable{:, bpCol};
    co2 = dataTable{:, co2Col};
    cbf = dataTable{:, cbfCol};
 
    %% Force column vectors
    t   = t(:);
    bp  = bp(:);
    co2 = co2(:);
    cbf = cbf(:);
 
    %% Remove rows with missing values
    validRows = ~isnan(t) & ~isnan(bp) & ~isnan(co2) & ~isnan(cbf);
 
    t   = t(validRows);
    bp  = bp(validRows);
    co2 = co2(validRows);
    cbf = cbf(validRows);
 
    %% Sort by time
    [t, sortIdx] = sort(t);
    bp  = bp(sortIdx);
    co2 = co2(sortIdx);
    cbf = cbf(sortIdx);
 
    %% Remove duplicate time points
    [t, uniqueIdx] = unique(t, "stable");
    bp  = bp(uniqueIdx);
    co2 = co2(uniqueIdx);
    cbf = cbf(uniqueIdx);
 
    %% Resample to 4 Hz
    fsTarget = 4;
    dtTarget = 1 / fsTarget;
 
    tResampled = (t(1):dtTarget:t(end))';
 
    bpResampled  = interp1(t, bp,  tResampled, "linear");
    co2Resampled = interp1(t, co2, tResampled, "linear");
    cbfResampled = interp1(t, cbf, tResampled, "linear");
 
    bpResampled = detrend(bpResampled,3);
    co2Resampled = detrend(co2Resampled,3);
    cbfResampled = detrend(cbfResampled,3);
 
    %% Package output in same format as simulated signal generators
    signalData = struct();
 
    signalData.bp  = bpResampled;
    signalData.co2 = co2Resampled;
    signalData.cbf = cbfResampled;
    signalData.fs  = fsTarget;
    signalData.t   = tResampled;
 
end
 
 