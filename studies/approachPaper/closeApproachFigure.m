function closeApproachFigure(figureHandle)
% closeApproachFigure Close one figure and release graphics resources.

    if isgraphics(figureHandle)
        close(figureHandle);
    end
    drawnow

end
