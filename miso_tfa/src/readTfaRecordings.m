function recordings = readTfaRecordings(settings)
% readTfaRecordings Read user files and attach participant and group labels.
%
% One file is one recording. With groupBySubfolder, the parent folder names
% the group. A file's basename supplies its participant/recording identifier.

    paths = string(settings.paths(:));
    files = strings(0, 1);
    for index = 1:numel(paths)
        if isfolder(paths(index))
            for pattern = settings.filePatterns
                if settings.recursive
                    found = dir(fullfile(paths(index), "**", pattern));
                else
                    found = dir(fullfile(paths(index), pattern));
                end
                files = [files; string(fullfile({found.folder}, {found.name})).']; %#ok<AGROW>
            end
        elseif isfile(paths(index))
            files(end + 1, 1) = paths(index); %#ok<AGROW>
        else
            error("TFA:MissingDataPath", "Recording path does not exist: %s", paths(index));
        end
    end
    files = unique(files, "stable");
    [~, names] = arrayfun(@fileparts, files, UniformOutput=false);
    files(startsWith(string(names), "~$")) = [];
    assert(~isempty(files), "TFA:NoRecordings", "No files match data.paths and data.filePatterns.");
    recordings = repmat(struct("id", "", "group", "", "file", "", "signals", []), numel(files), 1);
    for index = 1:numel(files)
        [folder, name] = fileparts(files(index));
        group = settings.groupLabel;
        if settings.groupBySubfolder
            [~, group] = fileparts(folder);
        end
        signals = loadSubjectData(files(index), settings);
        signals.t = signals.t*settings.timeScaleToSeconds;
        signals.map = signals.map*settings.signalScale.map;
        signals.co2 = signals.co2*settings.signalScale.co2;
        signals.cbv = signals.cbv*settings.signalScale.cbv;
        recordings(index) = struct("id", string(name), "group", string(group), ...
            "file", files(index), "signals", signals);
    end
end
