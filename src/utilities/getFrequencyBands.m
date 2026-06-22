function bands = getFrequencyBands(f)

    bands.vvlf.idx = f >= 0.005 & f < 0.024;
    bands.vlf.idx  = f >= 0.024 & f < 0.07;
    bands.lf.idx   = f >= 0.07  & f < 0.20;
    bands.hf.idx   = f >= 0.20  & f <= 0.50;

    bands.vvlf.f = f(bands.vvlf.idx);
    bands.vlf.f  = f(bands.vlf.idx);
    bands.lf.f   = f(bands.lf.idx);
    bands.hf.f   = f(bands.hf.idx);

end
