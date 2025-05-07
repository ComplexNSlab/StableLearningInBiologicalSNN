% Define the confusion matrix data
confMat = [50,  2,  5,  3;
            4, 55,  6,  5;
            3,  4, 60,  3;
            2,  3,  4, 58];

% Define simplified class labels
classLabels = {'A', 'B', 'C', 'D'};

% Create confusion chart
figure;
cm = confusionchart(confMat, classLabels, ...
    'Title', 'Confusion Matrix', ...
    'RowSummary', 'off', ...
    'ColumnSummary', 'off', ...
    'DiagonalColor', [0.3 0.5 0.8], ...
    'GridVisible','on', ...
    'OffDiagonalColor', [0.8 0.85 0.9], ...
    'PositionConstraint','outerposition');  

% Style it
cm.FontName = 'Arial';
cm.FontSize = 14;
cm.Normalization = 'absolute';

% Apply custom colormap (blue-white gradient)
% cmap = [linspace(1, 0.2, 100)', linspace(1, 0.6, 100)', ones(100,1)];
% colormap(cmap);

% Export clean, cropped figure for LaTeX
exportgraphics(gcf, fullfile(pwd, 'Figures', 'Abstract_Confusion_Matrix.pdf'), ...
    'ContentType', 'vector', ...
    'BackgroundColor', 'none', ...
    'Resolution', 300);
