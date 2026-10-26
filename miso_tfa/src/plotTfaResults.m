function figures = plotTfaResults(results, settings)
% plotTfaResults Draw the same pathway, coherence, and difference figures.
%
% Each displayed group or recording gets a pathway figure (gain, phase,
% ordinary/partial coherence, impulse), a system/input coherence figure, and
% optionally a difference figure. Simulation defaults to the reference case.

    figures = struct("name", {}, "handle", {});
    groups = results.groups;
    recordings = results.recordings;
    if ~isempty(results.simulation) && ~isempty(settings.simulationConditionIDs)
        wanted = settings.simulationConditionIDs;
        groupIDs = arrayfun(@(g) recordings(find(string({recordings.group}) == ...
            g.name, 1)).conditionID, groups);
        groups = groups(ismember(groupIDs, wanted));
        recordings = recordings(ismember([recordings.conditionID], wanted));
    end
    if settings.averages
        for index = 1:numel(groups)
            group = groups(index);
            label = group.name + " (n=" + group.count + ")";
            figures = [figures; plotEntry(group, label, "average_" + group.name, settings)]; %#ok<AGROW>
        end
    end
    if settings.individuals
        count = min(numel(recordings), settings.individualLimit);
        for index = 1:count
            recording = recordings(index);
            label = recording.group + " / " + recording.id;
            tag = "individual_" + recording.group + "_" + recording.id;
            figures = [figures; plotEntry(recording, label, tag, settings)]; %#ok<AGROW>
        end
    end
end

function figures = plotEntry(entry, label, tag, settings)
    blue = [0.00 0.35 0.65];
    red = [0.80 0.22 0.12];
    green = [0.15 0.50 0.25];
    frequency = entry.frequencyHz;
    hasTruth = ~isempty(entry.truth);
    figureHandle = figure(Name=label + ": pathways", Color="w", ...
        Visible=settings.visible, Position=[80 80 1250 1050], NumberTitle="off");
    layout = tiledlayout(4, 2, TileSpacing="compact", Padding="compact");
    title(layout, label + " — SISO and MISO", Interpreter="none");
    subtitle(layout, "Output: " + entry.cbvUnits + "; inputs: " + entry.inputUnits + ...
        ". Shading, when enabled: ±1 SD across recordings.", Interpreter="none");
    for column = 1:2
        pathwayNames = ["map", "co2"];
        pathway = pathwayNames(column);
        siso = entry.siso.(pathway);
        miso = entry.miso.(pathway);
        nexttile(column);
        drawCurve(frequency, siso.gain, blue, "SISO", settings, false);
        drawCurve(frequency, miso.gain, red, "MISO", settings, false);
        if hasTruth
            plot(frequency, entry.truth.(pathway).gain, "--", ...
                Color=green, LineWidth=1.6, DisplayName="Known pathway");
        end
        title(upper(pathway) + " → CBFV");
        ylabel("Gain (output/input)");
        finishFrequencyAxis(frequency);
        legend(Location="best");

        nexttile(2 + column);
        drawCurve(frequency, siso.phaseDegrees, blue, "SISO", settings, true);
        drawCurve(frequency, miso.phaseDegrees, red, "MISO", settings, true);
        if hasTruth
            phase = displayPhase(entry.truth.(pathway).phaseDegrees, settings.phaseStyle);
            plot(frequency, phase, "--", Color=green, LineWidth=1.6, DisplayName="Known pathway");
        end
        ylabel("Phase (degrees)");
        finishFrequencyAxis(frequency);

        nexttile(4 + column);
        drawCurve(frequency, siso.coherence, blue, "Ordinary", settings, false);
        drawCurve(frequency, miso.coherence, red, "Partial", settings, false);
        ylabel("Coherence");
        ylim([0 1]);
        finishFrequencyAxis(frequency);
        legend(Location="best");

        nexttile(6 + column);
        drawCurve(entry.impulseTimeSeconds, siso.impulse, blue, "SISO", settings, false);
        drawCurve(entry.impulseTimeSeconds, miso.impulse, red, "MISO", settings, false);
        if hasTruth
            plot(entry.impulseTimeSeconds, entry.truth.(pathway).impulse, "--", ...
                Color=green, LineWidth=1.6, DisplayName="Known pathway, same band");
        end
        xline(0, ":", HandleVisibility="off");
        yline(0, ":", HandleVisibility="off");
        xlim(settings.impulseTimeLimitsSeconds);
        xlabel("Lag (seconds)");
        ylabel("Impulse (gain units/s)");
        title("Band-limited impulse response");
        grid("on");
    end
    set(findall(figureHandle, Type="axes"), FontSize=10);
    figures = struct("name", safeName(tag + "_pathways"), "handle", figureHandle);

    figureHandle = figure(Name=label + ": coherence", Color="w", ...
        Visible=settings.visible, Position=[120 120 950 650], NumberTitle="off");
    layout = tiledlayout(2, 1, TileSpacing="compact", Padding="compact");
    title(layout, label + " — system and input relationships", Interpreter="none");
    nexttile;
    drawCurve(frequency, entry.multipleCoherence, red, "Multiple coherence", settings, false);
    title("MAP and CO₂ together → CBFV: multiple coherence");
    ylabel("Multiple coherence");
    ylim([0 1]);
    finishFrequencyAxis(frequency);
    nexttile;
    drawCurve(frequency, entry.inputCoherence, blue, "Input coherence", settings, false);
    title("MAP–CO₂ input coherence");
    ylabel("Input coherence");
    ylim([0 1]);
    finishFrequencyAxis(frequency);
    figures(end + 1, 1) = struct("name", safeName(tag + "_coherence"), "handle", figureHandle);

    if settings.showDifferences
        figureHandle = figure(Name=label + ": model differences", Color="w", ...
            Visible=settings.visible, Position=[160 160 1100 650], NumberTitle="off");
        layout = tiledlayout(2, 2, TileSpacing="compact", Padding="compact");
        title(layout, label + " — MISO minus SISO", Interpreter="none");
        for column = 1:2
            pathwayNames = ["map", "co2"];
            pathway = pathwayNames(column);
            nexttile(column);
            drawCurve(frequency, entry.difference.(pathway).gain, blue, "Difference", settings, false);
            yline(0, ":", HandleVisibility="off");
            title(upper(pathway) + " → CBFV");
            ylabel("Gain difference");
            finishFrequencyAxis(frequency);
            nexttile(2 + column);
            % Differences are shortest angular differences even when the
            % transfer-function phase is displayed unwrapped.
            phaseSettings = settings;
            phaseSettings.phaseStyle = "wrapped";
            drawCurve(frequency, entry.difference.(pathway).phaseDegrees, ...
                blue, "Difference", phaseSettings, true);
            yline(0, ":", HandleVisibility="off");
            ylabel("Circular phase difference (degrees)");
            finishFrequencyAxis(frequency);
        end
        figures(end + 1, 1) = struct("name", safeName(tag + "_differences"), "handle", figureHandle);
    end
end

function drawCurve(x, values, color, label, settings, phase)
    spread = [];
    if isstruct(values)
        center = values.mean;
        spread = values.sd;
    else
        center = values;
    end
    if phase
        center = displayPhase(center, settings.phaseStyle);
    end
    hold("on");
    if settings.showStandardDeviation && ~isempty(spread)
        valid = isfinite(x) & isfinite(center) & isfinite(spread);
        if any(valid)
            % Keep separate polygons across phase wraps or missing values.
            edges = diff([false; valid; false]);
            starts = find(edges == 1);
            stops = find(edges == -1) - 1;
            for index = 1:numel(starts)
                selected = starts(index):stops(index);
                fill([x(selected); flipud(x(selected))], ...
                    [center(selected) - spread(selected); flipud(center(selected) + spread(selected))], ...
                    color, FaceAlpha=0.13, EdgeColor="none", HandleVisibility="off");
            end
        end
    end
    plot(x, center, Color=color, LineWidth=1.4, DisplayName=label);
end

function phase = displayPhase(phase, style)
    if style == "unwrapped"
        phase = rad2deg(unwrap(deg2rad(phase)));
    else
        % Do not draw a line through a wrapped phase discontinuity.
        jumps = [false; abs(diff(phase)) > 180];
        phase(jumps) = NaN;
    end
end

function finishFrequencyAxis(frequency)
    xlim([frequency(1), frequency(end)]);
    xlabel("Frequency (Hz)");
    grid("on");
end

function name = safeName(name)
    name = regexprep(name, "[^A-Za-z0-9_-]", "_");
end
