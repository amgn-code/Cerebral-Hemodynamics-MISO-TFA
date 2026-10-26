function figures = plotSimulationResults(results, settings)
% plotSimulationResults Show gain/phase advantage and explain the simulation.
%
% A factor plot is a reference slice: all other conditions equal baseline.
% A factorial run also retains all combinations in the saved numerical data.
% No absolute-error figures are generated.

    figures = struct("name", {}, "handle", {});
    conditions = results.simulation.conditions;
    summaries = results.simulation.advantage;
    baseline = settings.simulation.baseline;
    for factor = settings.simulation.vary
        other = setdiff(string(fieldnames(baseline)), factor, "stable");
        mask = true(height(conditions), 1);
        for name = other.'
            mask = mask & conditions.(name) == baseline.(name);
        end
        selected = find(mask);
        [levels, order] = sort(conditions.(factor)(selected));
        selected = selected(order);
        for metric = settings.simulation.metrics
            figureHandle = figure(Name=metric + " advantage: " + factor, ...
                Color="w", Visible=settings.plots.visible, ...
                Position=[100 100 1200 620], NumberTitle="off");
            layout = tiledlayout(1, 2, TileSpacing="compact", Padding="compact");
            title(layout, upper(extractBefore(metric + " ", " ")) + ...
                " advantage — " + factorLabel(factor) + " (other settings fixed)", Interpreter="none");
            frequency = summaries(1).frequencyHz;
            mapValues = collectAdvantages(summaries, selected, "map", metric);
            co2Values = collectAdvantages(summaries, selected, "co2", metric);
            finite = [mapValues(isfinite(mapValues)); co2Values(isfinite(co2Values))];
            limit = settings.plots.advantageColorLimit;
            if ~isfinite(limit)
                if isempty(finite)
                    limit = 1;
                else
                    limit = max(0.1, max(abs(finite)));
                end
            end
            for pathwayIndex = 1:2
                pathways = ["map", "co2"];
                pathway = pathways(pathwayIndex);
                values = collectAdvantages(summaries, selected, pathway, metric);
                values(values == Inf) = limit;
                values(values == -Inf) = -limit;
                nexttile;
                handle = imagesc(frequency, 1:numel(levels), values);
                handle.AlphaData = ~isnan(values);
                set(gca, YDir="normal", Color=[0.92 0.92 0.92], ...
                    YTick=1:numel(levels), YTickLabel=string(levels));
                colormap(gca, advantageColors());
                clim([-limit limit]);
                bar = colorbar;
                bar.Label.String = "log10(mean SISO error / mean MISO error)";
                xlabel("Frequency (Hz)");
                ylabel(factorLabel(factor), Interpreter="none");
                title(upper(pathway) + " → CBFV");
            end
            subtitle(layout, "Positive: MISO closer to truth. Grey: undefined/no paired estimates. Rows are tested levels.");
            figures(end + 1, 1) = struct("name", "advantage_" + metric + "_" + factor, ...
                "handle", figureHandle); %#ok<AGROW>
        end
    end
    if settings.plots.explainSimulation
        figures(end + 1, 1) = explainSimulation(results, settings);
    end
end

function values = collectAdvantages(summaries, indices, pathway, metric)
    values = NaN(numel(indices), numel(summaries(1).frequencyHz));
    for row = 1:numel(indices)
        values(row, :) = summaries(indices(row)).(pathway).(metric).advantage.';
    end
end

function figureEntry = explainSimulation(results, settings)
    example = results.example;
    visible = example.t <= settings.plots.exampleDurationSeconds;
    handle = figure(Name="How the reference simulation is generated", ...
        Color="w", Visible=settings.plots.visible, Position=[80 80 1300 850], NumberTitle="off");
    layout = tiledlayout(2, 2, TileSpacing="compact", Padding="compact");
    title(layout, "Reference simulation: inputs → known pathways → CBFV");
    nexttile;
    plot(example.t(visible), example.cleanMap(visible), ...
        example.t(visible), example.cleanCo2(visible), LineWidth=1);
    xlabel("Time (seconds)");
    ylabel("Input fluctuations (simulation units)");
    title("1. Related inputs with separately controlled SD");
    legend("MAP", "CO₂", Location="best");
    grid("on");
    nexttile;
    plot(example.t(visible), example.mapContribution(visible), ...
        example.t(visible), example.co2Contribution(visible), ...
        example.t(visible), example.cleanCbv(visible), ...
        example.t(visible), example.cbv(visible), LineWidth=1);
    xlabel("Time (seconds)");
    ylabel(example.cbvUnits);
    title("2. CBFV = MAP contribution + CO₂ contribution + noise");
    legend("MAP contribution", "CO₂ contribution", "Clean sum", "Observed", Location="best");
    grid("on");
    nexttile;
    spectra = estimateWelchSpectra(example.cleanMap, example.cleanCo2, ...
        example.cleanCbv, example.fs, settings.analysis.pwelch);
    chosen = spectra.f >= settings.analysis.frequencyRangeHz(1) ...
        & spectra.f <= settings.analysis.frequencyRangeHz(2);
    frequency = spectra.f(chosen);
    mapPower = real(spectra.map.power(chosen));
    co2Power = real(spectra.co2.power(chosen));
    scenario.targetInputCoherence = settings.simulation.baseline.inputCoherence;
    scenario.spectralSimilarityControl = settings.simulation.baseline.spectralSimilarity;
    designed = createKnownTruthInputSpectra(frequency, scenario, settings.simulation);
    semilogy(frequency, mapPower/trapz(frequency, mapPower), ...
        frequency, co2Power/trapz(frequency, co2Power), ...
        frequency, designed.mapPower/trapz(frequency, designed.mapPower), "--", ...
        frequency, designed.co2Power/trapz(frequency, designed.co2Power), ":", LineWidth=1.4);
    xlabel("Frequency (Hz)");
    ylabel("Power / integrated band power");
    title("3. Input power shape: intended versus one finite recording");
    legend("Generated MAP", "Generated CO₂", "Target MAP", "Target CO₂", Location="best");
    grid("on");
    nexttile;
    mapKernel = example.truth.mapImpulseResponse;
    co2Kernel = example.truth.co2ImpulseResponse;
    plot((0:numel(mapKernel) - 1)/example.fs, mapKernel*example.fs, ...
        (0:numel(co2Kernel) - 1)/example.fs, co2Kernel*example.fs, LineWidth=1.5);
    xlabel("Lag (seconds)");
    ylabel("Generating impulse response / second");
    title("4. Known pathway rules before reporting-band restriction");
    legend("MAP pathway", "CO₂ pathway", Location="best");
    grid("on");
    figureEntry = struct("name", "simulation_explanation", "handle", handle);
end

function label = factorLabel(factor)
    switch factor
        case "inputCoherence"
            label = "Assigned MAP–CO₂ coherence";
        case "co2FluctuationRatio"
            label = "CO₂ SD / MAP SD";
        case "co2GainRatio"
            label = "CO₂ / MAP band RMS pathway gain";
        case "durationSeconds"
            label = "Recording duration (seconds)";
        case "outputSnrDb"
            label = "CBFV output SNR (dB; Inf = noise-free)";
        case "mapInputSnrDb"
            label = "MAP measurement SNR (dB; Inf = noise-free)";
        case "co2InputSnrDb"
            label = "CO₂ measurement SNR (dB; Inf = noise-free)";
        case "mapTimeConstantSeconds"
            label = "MAP pathway time constant (seconds)";
        case "co2TimeConstantSeconds"
            label = "CO₂ pathway time constant (seconds)";
        case "co2DelaySeconds"
            label = "True CO₂ pathway delay (seconds)";
        case "inputLagSeconds"
            label = "CO₂ input lag relative to MAP (seconds)";
        case "alignmentErrorSeconds"
            label = "CO₂ measurement advance (seconds)";
        case "spectralSimilarity"
            label = "Assigned input spectral similarity";
        otherwise
            label = factor;
    end
end

function colors = advantageColors()
    % Blue favors SISO; red favors MISO; equal errors are white.
    negative = [0.15 0.35 0.65];
    positive = [0.75 0.15 0.10];
    half = linspace(0, 1, 128).';
    colors = [negative + half.*(1 - negative); ...
        ones(128, 3) + half.*(positive - 1)];
end
