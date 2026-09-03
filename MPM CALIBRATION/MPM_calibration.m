clear
close
clc

%% Save original folder
baseFolder = pwd;       

%%
% Goes through the sample data folders and extracts harmonic response taken by the MPM
% Extracting u2 and u3 as secondHarm and thirdHarm then finding the ratio of u2/u3
% u2 and u3 are oringinally saved as magnitudes only so the values where the field is negative is done by multiplying by -1
% xAxis_35 comes from MPM_HHC_Calibrate.m as the measured magnetic field values from the Helmholtz Coils
% Since we plot u2/u3 vs B_ext/B_0, the field found from MPM_HHC_Calibrate.m needs to be divided by B_0 (MPM drive field) which is experimentally found
% Using MATLAB "Curve Fitter" X data is fit to XAxis_35 and y data is field_35 using Linear mode. This gives the equations in the "Linear Fit" section
% Two different fits are listed based on the DC range used.

%% Load 
acFolders = {'3.5 mT AC field'};

%% =========================
% 3.5 mT error bar set up
% ==========================
[field_35, min_35, max_35] = getACcurve(baseFolder, acFolders{1}); % Get average signal for each field ratio (B_ext/B_0), minimum signal, and maximum signal

field_35 = [-field_35(1:22); field_35(23:end)];                    % Correct for magnitude of average signal
min_35   = [-min_35(1:22);   min_35(23:end)];                      % Correct for magnitude of minimum signal
max_35   = [-max_35(1:22);   max_35(23:end)];                      % Correct for magnitude of maximum signal

temp = min_35;
min_35 = min(min_35,max_35);
max_35 = max(temp,max_35);

errLow_35  = field_35 - min_35;                                    % Lower error for errorbar plot
errHigh_35 = max_35 - field_35;                                    % Upper error for errorbar plot


%% Experimental X axis (B_ext/B_0)
xAxis_35 = 8.526./(3.5651*1e3)+ [-481 -457 -433 -410 -386 -362 -338 -315 -291 ...
    -267 -244 -220 -196 -172 -148 -125 -101 -77 -54 -30 0 ...
    26 50 73 97 121 144 167 192 216 241 265 289 313 337 363 ...
    387 411 436 460 484]./(3.5651*1e3);

%% Linear Fit

a = (-500:.1:500);                                                 % DC limits 

a_35 = (-500:.1:500)./(3.5*1e3);                                   % B_ext/B_0
% b_35 = (3.923.*a_35)-0.04568;                                    %500 uT Range
b_35 = (3.7978.*a_35)-0.0442;                                      %200 uT Range


%% Plots
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

%% Plot Settings
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%% FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
