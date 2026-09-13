function catalogFile = writeApproachPaperCaptionCatalog( ...
    manifest, figuresRoot)
% writeApproachPaperCaptionCatalog Save all figure captions as Markdown.

    catalogFile = fullfile(figuresRoot, "figure_captions.md");
    headerLines = [ ...
        "# Approach Paper Figure Captions"
        ""
        "This catalog is generated with the figures. Each caption is also saved in its plot group's Captions folder."
        ""];
    captionLines = strings(4*height(manifest), 1);

    for rowIndex = 1:height(manifest)
        heading = compose( ...
            "## Group %02d — %s", ...
            manifest.GroupNumber(rowIndex), ...
            manifest.Title(rowIndex));
        firstLine = 4*(rowIndex - 1) + 1;
        captionLines(firstLine:firstLine + 3) = [ ...
            heading
            ""
            manifest.Caption(rowIndex)
            ""];
    end
    lines = [headerLines; captionLines];
    writelines(lines, catalogFile);

end
