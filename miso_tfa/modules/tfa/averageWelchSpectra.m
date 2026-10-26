function spectra = averageWelchSpectra(blockSpectra)
% averageWelchSpectra Average spectra from independent recording blocks.

    if ~iscell(blockSpectra) || isempty(blockSpectra)
        error("TFA:MissingWelchBlocks", ...
            "blockSpectra must be a nonempty cell array.");
    end

    spectra = blockSpectra{1};
    fieldPaths = [ ...
        "map.power", "co2.power", "cbv.power", ...
        "cross.mapCo2", "cross.mapCbv", "cross.co2Cbv"];
    for fieldPath = fieldPaths
        values = cellfun( ...
            @(item) getNestedField(item, fieldPath), ...
            blockSpectra, UniformOutput=false);
        spectra = setNestedField( ...
            spectra, fieldPath, mean(cat(2, values{:}), 2));
    end
    spectra.cross.co2Map = conj(spectra.cross.mapCo2);

    numBlocks = numel(blockSpectra);
    effective = cellfun( ...
        @(item) item.welchInfo.effectiveAverages, blockSpectra);
    spectra.welchInfo.effectiveAverages = ...
        numBlocks^2/sum(1./effective);
    spectra.welchInfo.numWindows = sum(cellfun( ...
        @(item) item.welchInfo.numWindows, blockSpectra));
    spectra.welchInfo.signalLengthSamples = sum(cellfun( ...
        @(item) item.welchInfo.signalLengthSamples, blockSpectra));
    spectra.welchInfo.signalDurationSeconds = sum(cellfun( ...
        @(item) item.welchInfo.signalDurationSeconds, blockSpectra));

end

function value = getNestedField(structure, fieldPath)
% getNestedField Read a two-level field.

    names = split(fieldPath, ".");
    value = structure.(names(1)).(names(2));

end

function structure = setNestedField(structure, fieldPath, value)
% setNestedField Write a two-level field.

    names = split(fieldPath, ".");
    structure.(names(1)).(names(2)) = value;

end
