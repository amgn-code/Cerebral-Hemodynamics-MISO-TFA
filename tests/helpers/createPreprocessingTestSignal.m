function signalData = createPreprocessingTestSignal(co2)
% createPreprocessingTestSignal Create aligned signals for preprocessing tests.

numPoints = numel(co2);
signalData.t = 0:(numPoints - 1);
signalData.map = 90 + zeros(1, numPoints);
signalData.co2 = co2;
signalData.cbv = 50 + zeros(1, numPoints);

end
