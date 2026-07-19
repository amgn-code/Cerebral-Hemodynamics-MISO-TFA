function values = createStableCo2(numPoints)
% createStableCo2 Create stable oscillating CO2 values for preprocessing tests.

sampleIndex = 0:(numPoints - 1);
values = 37.34578 + 0.7*sin(2*pi*sampleIndex/12);

end
