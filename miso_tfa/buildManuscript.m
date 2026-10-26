function build = buildManuscript()
% buildManuscript Generate the manuscript assets and compile one canonical PDF.
%
% Run from the miso_tfa folder after calling setup:
%     build = buildManuscript;
%
% The function reads the frozen final-study exports, regenerates the figures
% and tables, and compiles the LaTeX draft into output/pdf. It does not rerun
% the simulation.

    project = setup();
    manuscriptFolder = project.manuscript;
    outputFolder = fullfile(project.output, "pdf");
    pdfBaseName = "MISO_TFA_simulation_study_manuscript";
    if ~exist(outputFolder, "dir")
        mkdir(outputFolder);
    end

    generateManuscriptAssets( ...
        fullfile(project.output, "final"), manuscriptFolder);

    latexCommand = "latexmk -pdf -interaction=nonstopmode " + ...
        "-jobname=" + pdfBaseName + " " + ...
        "-halt-on-error -outdir=" + quoteForShell(outputFolder) + " " + ...
        quoteForShell(fullfile(manuscriptFolder, "main.tex"));

    previousFolder = pwd;
    cleanupObject = onCleanup(@() cd(previousFolder));
    cd(manuscriptFolder);
    [status, commandOutput] = system(char(latexCommand));
    if status ~= 0
        error("TFA:ManuscriptBuildFailed", ...
            "LaTeX compilation failed:\n%s", commandOutput);
    end

    build.manuscriptFolder = manuscriptFolder;
    build.pdf = fullfile(outputFolder, pdfBaseName + ".pdf");
    build.commandOutput = commandOutput;
    build.generatedAt = datetime("now", TimeZone="local");
end

function quotedPath = quoteForShell(path)
% quoteForShell Quote a path for the local shell without changing it.

    path = replace(string(path), "'", "'\\''");
    quotedPath = "'" + path + "'";
end
