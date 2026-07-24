function variants = defaultSensitivityVariants()
% defaultSensitivityVariants Define readable empirical sensitivity checks.
%
% NaN means to retain the reference analysis value.

    variants = repmat(createEmptyVariant(), 6, 1);

    variants(1).name = "Reference";

    variants(2).name = "No spectral smoothing";
    variants(2).smoothingEnabled = false;

    variants(3).name = "50 s Welch window";
    variants(3).welchWindowLengthSeconds = 50;

    variants(4).name = "150 s Welch window";
    variants(4).welchWindowLengthSeconds = 150;

    variants(5).name = "Linear detrending";
    variants(5).detrendOrder = 1;

    variants(6).name = "2 Hz sampling";
    variants(6).samplingFrequencyHz = 2;

end

function variant = createEmptyVariant()
% createEmptyVariant Provide every supported sensitivity field.

    variant.name = "";
    variant.samplingFrequencyHz = NaN;
    variant.detrendOrder = NaN;
    variant.welchWindowLengthSeconds = NaN;
    variant.smoothingEnabled = [];
    variant.smoothingKernel = [];

end
