function [e_rate, i_rate] = NetworkRates(g, sigma)
    %% This function run the Izhikevich network for a geiven (g, sigma) and returns the average firing rate of the network per neuron and persecond (Hz)

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
        
        I = [sigma*randn(Ne,1); 0.4*sigma*randn(Ni,1)]/sqrt(dt); % thalamic input
        I = I + W * I_syn;
        
        v=v+dt*(0.04*v.^2+5*v+140-u+I); 
        u=u+a.*(b.*v-u)*dt; 
    end
    
    
    e_rate = sum(firings(:, 2) <= Ne)/(T/1000)/Ne; % Hz
    i_rate = sum(firings(:, 2) > Ne)/(T/1000)/Ni; % Hz
end
