clear
close all
clc

%%
originalFolder = pwd;

%% Single file to process

filename = 'sample_data.mat';

if ~isfile(filename)
    error('File not found: %s', filename);
end

%% Welch PSD settings

segmentFraction = 0.05;
overlapFraction = 0.005;

%% Load data

S = load(filename);

voltage = double(S.raw_daq_voltage(:));
Fs_raw = double(S.live_sample_rate);
f_drive = double(S.live_drive_frequency);

raw_time = (0:length(voltage)-1).' / Fs_raw;

%% Settings for time-resolved harmonic calculation

% Number of drive periods used for each FFT.
%
% This is equivalent to "num_periods" in the Python code.
periods_per_block = 1;

% Number of samples per drive period
samples_per_period = Fs_raw / f_drive;

% Match Python:
%
% num_pts_per_period = sample_rate / frequency
% num_samples = int((num_periods*num_pts_per_period) + 1)
%
samples_per_block = floor( ...
    periods_per_block * samples_per_period + 1);

N_raw = length(voltage);

num_blocks = floor(N_raw / samples_per_block);

%% Check sampling conditions

if samples_per_period < 1
    error('The raw sample rate must be greater than the drive frequency.');
end

% Need to satisfy Nyquist for the third harmonic
if Fs_raw <= 2*(3*f_drive)
    error(['Raw DAQ sample rate is too low to measure the 3rd harmonic. ' ...
           'Need Fs_raw > %.3f Hz.'], ...
           2*(3*f_drive));
end

if num_blocks < 2
    error('Not enough data to calculate the harmonic time series.');
end

%% Display acquisition information

fprintf('\nFile: %s\n', filename)
fprintf('Raw sample rate: %.3f Hz\n', Fs_raw)
fprintf('Drive frequency: %.3f Hz\n', f_drive)

fprintf('Samples per period: %.3f\n', ...
    samples_per_period)

fprintf('Periods per FFT block: %d\n', ...
    periods_per_block)

fprintf('Samples per FFT block: %d\n', ...
    samples_per_block)

fprintf('Number of blocks: %d\n', ...
    num_blocks)

fprintf('Harmonic update rate: %.3f Hz\n', ...
    Fs_raw/samples_per_block)

%% Allocate arrays

harmonic_2 = zeros(num_blocks,1);
harmonic_3 = zeros(num_blocks,1);

ratio = zeros(num_blocks,1);
second_harmonic = zeros(num_blocks,1);

harmonic_time = zeros(num_blocks,1);

%% Calculate second and third harmonics using FFT
%
% This section now follows the same basic method as the Python code:
%
% 1. Read a block of raw DAQ voltage
% 2. Take its FFT
% 3. Calculate the FFT frequency axis
% 4. Find the FFT bin closest to 2*f_drive
% 5. Find the FFT bin closest to 3*f_drive
% 6. Read the FFT magnitude at those bins
% 7. Calculate harmonic_2 / harmonic_3

for k = 1:num_blocks

    %% Determine samples in this block

    first_index = ...
        (k-1)*samples_per_block + 1;

    last_index = ...
        first_index + samples_per_block - 1;

    %% Extract raw DAQ voltage

    block = voltage(first_index:last_index);

    Nblock = length(block);

    %% Take FFT of raw voltage

    X = fft(block);

    %% Frequency axis

    f_fft = ...
        (0:Nblock-1).' * Fs_raw/Nblock;

    %% FFT magnitude

    X_mag = abs(X);

    %% FFT phase

    X_phase = angle(X);

    %% Target harmonic frequencies

    target_2nd = 2*f_drive;
    target_3rd = 3*f_drive;

    %% Find FFT bins closest to harmonics

    [~, idx_2nd] = ...
        min(abs(f_fft - target_2nd));

    [~, idx_3rd] = ...
        min(abs(f_fft - target_3rd));

    %% Get harmonic magnitudes

    harmonic_2(k) = ...
        X_mag(idx_2nd);

    harmonic_3(k) = ...
        X_mag(idx_3rd);

    %% Calculate 2nd / 3rd harmonic ratio

    if harmonic_3(k) > eps

        ratio(k) = ...
            harmonic_2(k) / harmonic_3(k);

    else

        ratio(k) = NaN;

    end

    %% Save second harmonic

    second_harmonic(k) = ...
        harmonic_2(k);

    %% Time at center of FFT block

    center_sample = ...
        ((first_index - 1) + ...
         (last_index - 1))/2;

    harmonic_time(k) = ...
        center_sample / Fs_raw;

end

%% Remove invalid harmonic measurements

valid = ...
    isfinite(ratio) & ...
    isfinite(harmonic_2) & ...
    isfinite(harmonic_3) & ...
    harmonic_3 > eps;

ratio = ratio(valid) .* 1e-4;

second_harmonic = ...
    second_harmonic(valid) .* 1e-4;

t = harmonic_time(valid);

harmonic_2 = harmonic_2(valid);
harmonic_3 = harmonic_3(valid);

%% Apply calibration

B_measured = (ratio + 0.04247) ./ 3.798;
B_measured = B_measured.*3.5651.*1e3;

% Alternative calibration using only the second harmonic:
%
% B_measured = ...
%     (second_harmonic + 3.905e-5) ./ 9.644e-7;

%% Determine sampling parameters of B_measured

if length(t) < 2
    error('At least two valid harmonic measurements are required.');
end

dt = diff(t);

if any(dt <= 0)
    error('The time vector must be strictly increasing.');
end

dt_mean = mean(dt);

%% Check whether samples are approximately uniformly spaced

timeStepTolerance = 1e-6;

if max(abs(dt - dt_mean)) > ...
        timeStepTolerance * dt_mean

    warning(['The time samples are not uniformly spaced. ' ...
             'Welch PSD estimation assumes uniform sampling.']);

end

%% Effective field sampling rate

Fs_B = 1/dt_mean;
% Fs_B = 4000;
N_B = length(B_measured);

measurementTime = ...
    t(end) - t(1);

fprintf('\nField sampling rate: %.3f Hz\n', Fs_B)

fprintf('Field Nyquist frequency: %.3f Hz\n', ...
    Fs_B/2)

fprintf('Measurement duration: %.3f s\n', ...
    measurementTime)

%% Remove DC component before calculating PSD

B_fluct = ...
    B_measured - mean(B_measured);

%% Calculate PSD using Welch's method

segmentTime = ...
    measurementTime * segmentFraction;

segmentLength = ...
    round(segmentTime * Fs_B);

segmentLength = ...
    min(segmentLength, N_B);

segmentLength = ...
    max(segmentLength, 2);

if segmentLength > N_B
    error('The Welch segment length exceeds the data length.');
end

%% Welch overlap

overlapLength = ...
    round(overlapFraction * segmentLength);

% pwelch requires overlap smaller than segment length
overlapLength = ...
    min(overlapLength, segmentLength - 1);

%% FFT length for Welch PSD

nfft = ...
    max(2^nextpow2(segmentLength), ...
        segmentLength);

%% Welch window

welch_window = ...
    hann(segmentLength, 'periodic');
% welch_window = ...
%     hamming(segmentLength, 'periodic');
%% Power spectral density

[PSD_B, f] = pwelch( ...
    B_fluct, ...
    welch_window, ...
    overlapLength, ...
    nfft, ...
    Fs_B, ...
    'onesided');

%% Convert PSD to amplitude spectral density

ASD_B = sqrt(PSD_B);

%% Convert uT/sqrt(Hz) to nT/sqrt(Hz)

ASD_B = ASD_B .* 1e3;

%% Plot measured field versus time
% 
% % figure('Color','w');
% % 
% % plot( ...
% %     t, ...
% %     B_measured, ...
% %     'LineWidth',1);
% % 
% % xlabel('Time (s)');
% % 
% % ylabel('Measured field (\muT)');
% % 
% % set(gcf,'Units','inches')
% % 
% % set(gcf,'Position', ...
% %     [1 1 7 6])
% % 
% % ax = gca;
% % 
% % ax.FontSize = 22;
%% Plot amplitude spectral density

figure('Color','w');

set(gcf,'Units','inches')

set(gcf,'Position', ...
    [1 1 7 6])

%% Main axes

ax_main = axes;

loglog( ...
    ax_main, ...
    f, ...
    ASD_B, ...
    'LineWidth',1)

grid(ax_main,'on')

box(ax_main,'on')

xlabel( ...
    ax_main, ...
    'Frequency (Hz)')

ylabel( ...
    ax_main, ...
    'Spectral Noise Density (nT/Hz^{1/2})')

%% Do not plot above Nyquist frequency

f_plot_max = ...
    min(1.5e3, Fs_B/2);

xlim( ...
    ax_main, ...
    [1e-2, f_plot_max])

ylim( ...
    ax_main, ...
    [1e-3, 1e3])

%% Axis ticks
xticks([1e-2 1e-1 1e0 1e1 1e2 1e3])

yticks([1e-3 1e-2 1e-1 1e0 1e1 1e2 1e3])

ax_main.FontSize = 20;

%% Inset axes
ax_inset = axes( ...
    'Position', ...
    [0.34 0.66 0.28 0.25]);

db = 41.495-mean(B_measured);
B_in = B_measured+db;

bav = mean(B_in);

plot( ...
    ax_inset, ...
    t, ...
    B_in, ...
    'LineWidth',1)

grid(ax_inset,'on')

box(ax_inset,'on')

xlabel( ...
    ax_inset, ...
    'Time (s)')

ylabel( ...
    ax_inset, ...
    'B_{ext} (\muT)')

% %% Display first second

inset_start = t(1);

inset_end = ...
    min(inset_start + 1, t(end));

xlim( ...
    ax_inset, ...
    [inset_start, inset_end])

% Use these limits only if they fit this dataset

ylim(ax_inset,[41.485 41.505])

ax_inset.FontSize = 15;
% grid on
% 


%% Return to original folder

cd(originalFolder)
