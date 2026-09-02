clear
close
%%
% Code to plot the linear fit for the B field of Helmholtz Coils used during experimentation of the MPM
% I_short and b_short are the current and magnetic field produced by the Helmholtz Coils from the range of -200 mA (AG) to +200 mA (CG) in incriments of 10 mA. 
% the eqation is aquried using MATLABs "Curve Fitter" tool with I as the x data, B as the y data, and method set to "Linear"
%%

scatter(I_short,b_short,15,'filled')    % Plot B and I as a scatter plot
hold on

a = 2.419*I-1.267;                      % Equation found using "Curve Fitter"

plot(I,a,'r')                           % Plot the Linear fit equation 

ylabel('Magnetic Field, B_{ext} (\muT)')
xlabel('Current, I (mA)')

legend('Data','Linear Fit','Location','northwest','box','off')

xticks(-200:100:200);
yticks(-500:250:500);

ax = gca;
ax.FontSize = 20;

grid on
