function resultsTable = adjustPValuesByFamily( ...
    resultsTable, alpha)
% adjustPValuesByFamily Apply BH adjustment within named test families.
%
% The table must contain RawP and MultiplicityFamily. Keeping the family
% name in the saved table makes the multiplicity decision visible to the
% reader and reproducible later.

    if isempty(resultsTable)
        return
    end

    familyNames = unique( ...
        string(resultsTable.MultiplicityFamily), "stable");

    for familyIndex = 1:numel(familyNames)
        familyMask = string(resultsTable.MultiplicityFamily) == ...
            familyNames(familyIndex);
        resultsTable.BHAdjustedP(familyMask) = ...
            adjustPValuesBenjaminiHochberg( ...
                resultsTable.RawP(familyMask));
    end

    resultsTable.IsSignificant = ...
        resultsTable.BHAdjustedP < alpha;

end
