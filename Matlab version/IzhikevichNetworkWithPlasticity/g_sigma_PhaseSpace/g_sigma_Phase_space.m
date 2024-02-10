%% The code that runs for a long time to get a high resolution phase diagram

g = 0:0.01:1;
sigma = 0:0.05:15;

e_rates = zeros(length(g), length(sigma));
i_rates = zeros(length(g), length(sigma));

f = waitbar(0, 'Please wait ...');
for i = 1:length(g)
    for j = 1:length(sigma)
       [e_rate, i_rate] = NetworkRates(g(i), sigma(j));
       e_rates(i, j) = e_rate;
       i_rates(i, j) = i_rate;

       done = ((i-1)*length(sigma)+(j-1))/(length(g)*length(sigma));
       waitbar(done, f, append('Please wait : ', int2str(100*done), ' %'));
    end
end
close(f)
delete(f)

%% visualization of the phase diagram
g = 0:0.01:1;
sigma = 0:0.05:15;
figure('Name', 'Excitatory firing rates');
im = image([g(1) g(end)], [sigma(1) sigma(end)], transpose(e_rates));
im.CDataMapping = 'scaled';
c = colorbar();
c.Label.String = 'Hz';
xlabel('g');
ylabel('sigma');
title('Excitatory firing rates');
set(gca,'YDir','normal')

colormap default

figure('Name', 'Inhibitory firing rates');
im = image([g(1) g(end)], [sigma(1) sigma(end)], transpose(i_rates));
im.CDataMapping = 'scaled';
c = colorbar();
c.Label.String = 'Hz';
xlabel('g');
ylabel('sigma');
title('Inhibitory firing rates');
set(gca,'YDir','normal')

%% % Excitatory neurons Inhibitory neurons
g = 0; sigma = 40;

Ne=800; Ni=200;
a=[0.02*ones(Ne,1); 0.1*ones(Ni,1)];
b=[0.2*ones(Ne,1); 0.2*ones(Ni,1)];
c=[-65*ones(Ne,1); -65*ones(Ni,1)];
d=[8*ones(Ne,1); 2*ones(Ni,1)];
W=[g*rand(Ne+Ni,Ne), -2*g*rand(Ne+Ni,Ni)];

v=-65*ones(Ne+Ni,1); % Initial values of v
u=b.*v; % Initial values of u
I_syn = zeros(Ne+Ni,1);
tau_syn = 5; %ms
current_jump = 0.2;

firings=[]; % spike timings
dt = 0.1;
T = 2000; 

for t=0:dt:T % simulation of 1000 ms
    I_syn = I_syn - I_syn*dt/tau_syn + current_jump*(v >=30);

    fired = find(v>=30); % indices of spikes
    firings = [firings; t+0*fired,fired];

    v(fired)=c(fired);
    u(fired)=u(fired)+d(fired);
    
    I=[sigma*randn(Ne,1);0.4*sigma*randn(Ni,1)]/sqrt(dt); % thalamic input
    I = I + W*I_syn;
    
    v=v+dt*(0.04*v.^2+5*v+140-u+I); 
    u=u+a.*(b.*v-u)*dt; 
end

plot(firings(:,1), firings(:,2), '.');