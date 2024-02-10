T = 1; % s

dt = 0.1; % ms
T = T*1000; % ms
n_t = T/dt;
time_array = (dt:dt:T)/1000;

a = 0.02; b = 0.2;
c = -65; d  = 8;
    
v = -65;
u = b*v;

% I = 7*(0.5*(1+sign(time_array - 0.5))).*exp(-(time_array-0.5)/0.005);

v_save = zeros(1, n_t);
u_save = zeros(1, n_t);
spike_train = zeros(1, n_t);

for i = 1:n_t
    v = v + (0.04*v^2 + 5*v + 140 - u + 40*randn()/sqrt(dt))*dt;
    u = u + a*(b*v-u)*dt;
    
    if v >= 30
        v_save(1, i) = 30;
        u_save(1, i) = u + d;
        spike_train(1, i) = 1/dt;
        v = c;
        u = u+d;
    else
        v_save(1, i) = v;
        u_save(1, i) = u;
    end
end



plot(time_array, v_save)
ylim([-80 40])