clear
close
clc

%% Save original folder
baseFolder = pwd;       

%% Load 
acFolders = {'3.5 mT AC field', ...
             '4 mT AC field', ...
             '4.5 mT AC field'};

%% =========================
% 3.5 mT
% ==========================
[field_35, min_35, max_35] = getACcurve(baseFolder, acFolders{1});

field_35 = [-field_35(1:22); field_35(23:end)];
min_35   = [-min_35(1:22);   min_35(23:end)];
max_35   = [-max_35(1:22);   max_35(23:end)];

temp = min_35;
min_35 = min(min_35,max_35);
max_35 = max(temp,max_35);

errLow_35  = field_35 - min_35;
errHigh_35 = max_35 - field_35;

%% =========================
% 4.0 mT
% ==========================
[field_40, min_40, max_40] = getACcurve(baseFolder, acFolders{2});


field_40 = [field_40(1:22).*-1; field_40(23:end)];
min_40   = [min_40(1:22).*-1;   min_40(23:end)];
max_40   = [max_40(1:22).*-1;   max_40(23:end)];

temp = min_40;
min_40 = min(min_40,max_40);
max_40 = max(temp,max_40);

errLow_40  = field_40 - min_40;
errHigh_40 = max_40 - field_40;


%% =========================
% 4.5 mT
% ==========================
[field_45, min_45, max_45] = getACcurve(baseFolder, acFolders{3});

field_45 = field_45;
min_45   = min_45;
max_45   = max_45;

field_45 = [field_45(1:22).*-1; field_45(23:end)];
min_45   = [min_45(1:22).*-1;   min_45(23:end)];
max_45   = [max_45(1:22).*-1;   max_45(23:end)];

temp = min_45;
min_45 = min(min_45,max_45);
max_45 = max(temp,max_45);

errLow_45  = field_45 - min_45;
errHigh_45 = max_45 - field_45;


%% X axis
xAxis_35 = 8.526./(3.5651*1e3)+ [-481 -457 -433 -410 -386 -362 -338 -315 -291 ...
    -267 -244 -220 -196 -172 -148 -125 -101 -77 -54 -30 0 ...
    26 50 73 97 121 144 167 192 216 241 265 289 313 337 363 ...
    387 411 436 460 484]./(3.5651*1e3);

a = (-500:.1:500);

a_35 = (-500:.1:500)./(3.5*1e3);
% b_35 = (3.923.*a_35)-0.04568;    %500 uT Range 3.5 mT AC
b_35 = (3.7978.*a_35)-0.0442;  %200 uT Range 3.5 mT AC


%% Plot
figure

errorbar(xAxis_35, field_35, errLow_35, errHigh_35, ...
    'o', ...
    'Color','b', ...
    'MarkerFaceColor','b', ...
    'MarkerSize',2, ...
    'LineStyle','none', ...
    'CapSize',0)

hold on
plot(a_35,b_35,'k')

xlabel('Applied Field Ratio, B_{ext}/B_0')
ylabel('Harmonic Ratio, u_2/u_3')

legend('Data','Linear Fit','Box','off','Location','northwest')
grid on

yticks(linspace(-.5,.5,5));
ylim([-0.6 0.51])

xticks(linspace(-.15,.15,5));
xlim([-.15 .15])

ax = gca;
ax.FontSize = 20;

ax = gca;

set(gcf,'Units','inches')
set(gcf,'Position',[1 1 7 6])   % 6 inches wide, 4 inches tall

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%% FUNCTIONS BELOW %%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [curve, minCurve, maxCurve] = getACcurve(baseFolder, acFolder)

    dcFolders = 10:10:200;

    AGvals = NaN(20,1);
    CGvals = NaN(20,1);

    AGmins = NaN(20,1);
    CGmins = NaN(20,1);

    AGmaxs = NaN(20,1);
    CGmaxs = NaN(20,1);

    for i = 1:length(dcFolders)

        d = dcFolders(i);

        [AGvals(i), AGmins(i), AGmaxs(i)] = averageFolder( ...
            fullfile(baseFolder, acFolder, 'AG', num2str(d)));

        [CGvals(i), CGmins(i), CGmaxs(i)] = averageFolder( ...
            fullfile(baseFolder, acFolder, 'CG', num2str(d)));

    end

    [zeroVal, zeroMin, zeroMax] = averageFolder( ...
        fullfile(baseFolder, acFolder, '0 DC'));

    curve    = [flipud(AGvals); zeroVal; CGvals];
    minCurve = [flipud(AGmins); zeroMin; CGmins];
    maxCurve = [flipud(AGmaxs); zeroMax; CGmaxs];

end

function [avgVal, minVal, maxVal] = averageFolder(folderPath)

    matFiles = dir(fullfile(folderPath,'*.mat'));

    names = {matFiles.name};
    keep = ismember(names,compose('%d.mat',1:10));
    matFiles = matFiles(keep);

    ratioVals = NaN(length(matFiles),1);

    for k = 1:length(matFiles)

        filePath = fullfile(matFiles(k).folder,matFiles(k).name);
        data = load(filePath);

        secondHarm = data.sample_frequency_array_magnitude(4001);
        thirdHarm  = data.sample_frequency_array_magnitude(6001);

        ratioVals(k) = secondHarm ./ thirdHarm;

    end
    avgVal = mean(ratioVals,'omitnan');
    minVal = min(ratioVals,[],'omitnan');
    maxVal = max(ratioVals,[],'omitnan');

end
