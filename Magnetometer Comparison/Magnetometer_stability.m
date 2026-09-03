clear all
close all
folder = (cd);

%% SENIS 3MTS magnetometer
Bz = [42.797 44.817 47.297 44.621 44.385 44.691 46.858 44.657 42.58 41.181 47.271 47.017 46.706 43.588 46.676 41.887 41.749 48.376 43.45 41.563 43.563 44.988 42.043 43.151 46.726 40.604 40.416 43.094 40.826 43.759 44.946 42.412 41.039 44.198 44.155 39.534 40.121 40.503];

cd("D:\OneDrive - oakland.edu\Group MPI\Matthew\Magnetometer\3MTS");

data_2 = readmatrix('0002_stability.xls');
data_3 = readmatrix('0003_stability.xls');
data_4 = readmatrix('0004_stability.xls');
data_5 = readmatrix('0005_stability.xls');

bz_3mts = [data_2(4:end-5,7),data_3(4:end,7),data_4(4:end,7),data_5(4:end-11,7)];

bz_3mts_av = mean(bz_3mts');
mu_3mts = mean(bz_3mts_av+6.7261)
sigma_3mts = std(bz_3mts_av)

T_SENSI = 1:1:57;

figure(2)
plot(T_SENSI,bz_3mts_av+6.7261,'k')
hold on
% plot(T_SENSI,sig_SENSI_plot+Bz_av,'r')
% plot(T_SENSI,-1.*sig_SENSI_plot+Bz_av,'r')
cd(folder);

cd("D:\Users\MPIlab\OneDrive - oakland.edu\Group MPI\Matthew\Magnetometer\HMG09s")

files = dir('gaussmeter_data_*.csv');

max_rows = 0;

for k = 1:length(files)
    data = readmatrix(files(k).name);
    max_rows = max(max_rows,size(data,1));
end

t_mg = NaN(max_rows,length(files));
bz_mg = NaN(max_rows,length(files));

for k = 1:length(files)

    data = readmatrix(files(k).name);

    % Round to 3 significant figures
    % data = round(data,3,'significant');

    N = size(data,1);

    t_mg(1:N,k) = data(:,1);
    bz_mg(1:N,k) = data(:,2);

end

t_mg = t_mg';
bz_mg = bz_mg';

t_mg_av = mean(t_mg);
bz_mg_av = mean(bz_mg).*-1e06/2;
bz_mg_tot_av = mean(bz_mg_av(:,1:end-1))
sigma_mg = std(bz_mg_av(:,1:end-1))
% SEM = sigma_mg./sqrt(length(bz_mg_av))

plot(t_mg_av,bz_mg_av,'r')

cd(folder)

%% MPM
load('MPM over time 5')

a = normalized_array_magnitude.*1e-04;
% a = normalized_array_magnitude(:,100:end-100).*1e-04;
% elapsed_time_harmonic = elapsed_time_harmonic(:,100:end-100);
bz_mpm = (a+.0397)./0.0009;

mu_mpm = mean(bz_mpm)
sigma_mpm = std(bz_mpm)

plot(elapsed_time_harmonic, bz_mpm,'b')


%%
xlabel('Time (s)')
ylabel('Bz (\muT)')

xticks([0 10 20 30 40 50 60])

xlim([0 60])
ylim([39 51])
legend('SENIS 3MTS', 'HGM09s Gaussmeter', 'MPM', 'Location', 'northeast',fontsize = 15, Box = 0) 

ax = gca;
ax.FontSize = 20 ;

grid on
