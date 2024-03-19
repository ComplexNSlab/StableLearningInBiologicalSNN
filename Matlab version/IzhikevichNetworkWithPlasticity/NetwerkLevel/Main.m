% time step, total time, total steps
dt = 0.1; % ms
T = 1000; % ms
n_t = T/dt;

% Facilitation parameters
U = 0.25; % utilization of synaptic efficacy 
u = U; % instantaneous U 
tau_fac = 50; % ms 
u_save = zeros(1, n_t);

% Depression parameters
tau_rec = 5; % ms
R = 1; % instantaneous availabe synaptic efficacy
R_save = zeros(1, n_t);

% Generating a Poisson spike train with average firing rate (r)
r = 0.008; % KHz

% random Poisson spike train 
lambda = r * dt;
spike_train = poissrnd(lambda, 1, n_t); 

% uniform spike train 
% spike_train = zeros(1, n_t);
% spike_train(n_t/10:1/r/dt:n_t) = 1;

for i = 1:n_t
    u_save(i) = u;
    R_save(i) = R;
    R = R*(1-spike_train(i)*u) - (R-1)*dt/tau_rec;
    u = u -(u-U)*dt/tau_fac + spike_train(i)*U*(1-u);
end

u_st = U/(1- (1-U)*exp(-1/(r*tau_fac)));
R_st = (1-exp(-1/(r*tau_rec)))/(1-(1-u_st)*exp(-1/(r*tau_rec)));

ax1 = subplot(3, 1, 1);
plot(dt*(1:n_t) - dt, R_save)
hold on
plot(dt*(1:n_t) - dt, R_st*ones(1, n_t), 'r')
hold off
xlim([0, T])
ylim([0, 1])
ylabel('R (t)')


ax2 = subplot(3, 1, 2);
plot(dt*(1:n_t) - dt, u_save)
hold on 
plot(dt*(1:n_t) - dt, ones(1, n_t)*u_st, 'r')
hold off
xlim([0, T])
ylim([0, 1])
ylabel('u(t)')

ax3 = subplot(3, 1, 3);
plot(dt*(1:n_t) - dt, spike_train)
xlim([0, T])
ylim([0, 1])
xlabel('t (ms)')
ylabel('spike train')

linkaxes([ax1 ax2 ax3],'xy');