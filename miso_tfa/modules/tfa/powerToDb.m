function valuesDb = powerToDb(values)
% powerToDb Convert positive power values to decibels.

    values = real(values);
    values(values <= 0) = NaN;
    valuesDb = 10*log10(values);

end
