clear
close
clc

%% Save original folder
baseFolder = pwd;      

%%
% Code was used in to make Fig. 6
% Sample data is only one run for each magnetometer
% Takes each measured magnetic field from the magnetometers and plots them on one graph of field vs time. 
% Each magnetometers standard deviation and mean are saved as b_av_* or std_* depending on which device it is for

%% SENIS 3MTS magnetometer
bz_3mts = [42.797 44.817 47.297 44.621 44.385 44.691 46.858 44.657 42.58 41.181 47.271 47.017 46.706 43.588 46.676 41.887 41.749 48.376 43.45 41.563 43.563 44.988 42.043 43.151 46.726 40.604 40.416 43.094 40.826 43.759 44.946 42.412 41.039 44.198 44.155 39.534 40.121 40.503];

bz_3mts_av = mean(bz_3mts);
std_3mts = std(bz_3mts);

T_SENIS = linspace(0,60,length(bz_3mts));

figure(2)
plot(T_SENIS,bz_3mts,'k')
hold on

%% HGM09s Gaussmeter
HGM09s_data = readmatrix('gaussmeter_data_7.csv');
b_09s = HGM09s_data(:,2)*-1e6/2;
t_09s = HGM09s_data(:,1);

b_av_09s = mean(b_09s);
std_09s = std(b_09s);

plot(t_09s,b_09s,'r')

%% MPM
load('MPM over time 5')
a = normalized_array_magnitude.*1e-04;

bz_mpm = (a+0.0442)./0.00106;

b_av_mpm = mean(bz_mpm);
std_mpm = std(bz_mpm);

plot(elapsed_time_harmonic, bz_mpm,'b')


%% Plot Settings
xlabel('Time (s)')
ylabel('Bz (\muT)')

xticks([0 10 20 30 40 50 60])

xlim([0 60])
ylim([39 51])
legend('SENIS 3MTS', 'HGM09s Gaussmeter', 'MPM', 'Location', 'northeast',fontsize = 15, Box = 0) 

ax = gca;
ax.FontSize = 20 ;

grid on
