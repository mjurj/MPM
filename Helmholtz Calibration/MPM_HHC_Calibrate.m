clear
close

scatter(I_short,b_short,15,'filled')
hold on

a = 2.419*I-1.267;

plot(I,a,'r')

ylabel('Magnetic Field, B_{ext} (\muT)')
xlabel('Current, I (mA)')

legend('Data','Linear Fit','Location','northwest','box','off')

xticks(-200:100:200);
yticks(-500:250:500);

ax = gca;
ax.FontSize = 20;

grid on
