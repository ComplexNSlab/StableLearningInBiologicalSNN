load("/Users/arshia/Desktop/StableMemories/Matlab version/IzhikevichNetworkWithPlasticity/g_sigma_PhaseSpace/HighResolutionWorkSpaceData.mat", 'i_rates', 'e_rates', 'g', 'sigma');


%%
function myfunc(g0)
    % Excitatory neurons Inhibitory neurons
    Ne=800; Ni=200;
    a=[0.02*ones(Ne,1); 0.1*ones(Ni,1)];
    b=[0.2*ones(Ne,1); 0.2*ones(Ni,1)];
    c=[-65*ones(Ne,1); -65*ones(Ni,1)];
    d=[8*ones(Ne,1); 2*ones(Ni,1)];
    
    dt = 0.5;
    T = 200000; 
    n_t = T/dt;
    
    A_save = zeros(Ne+Ni, n_t);
    
    W=[g0*rand(Ne+Ni,Ne), -2*g0*rand(Ne+Ni,Ni)];
    
    v=-65*ones(Ne+Ni,1); % Initial values of v
    u=b.*v; % Initial values of u
    I_syn = zeros(Ne+Ni,1);
    tau_syn = 5; %ms
    current_jump = 0.2;
    
    A = [0.009*ones(Ne, 1); 0.009*ones(Ni, 1)];
    A_goal = [0.011*ones(Ne, 1); 0.011*ones(Ni, 1)];
    tau_A = 1000;
    ge = [];
    gi = [];
    
    firings=[]; % spike timings
    
    
    f = waitbar(0, 'Please wait ...');
    for i=1:n_t % simulation of 1000 ms
        I_syn = I_syn - I_syn*dt/tau_syn + current_jump*(v >=30);
        A = A - A*dt/tau_A + 1*(v >= 30)/tau_A;
        A_save(:, i) = A;
    
        fired = find(v>=30); % indices of spikes
        firings = [firings; i*dt+0*fired,fired];
        
    
        v(fired)=c(fired);
        u(fired)=u(fired)+d(fired);
        
        I=[sigma*randn(Ne,1);0.4*sigma*randn(Ni,1)]/sqrt(dt); % thalamic input
        I = I + W*I_syn;
       
        v=v+dt*(0.04*v.^2+5*v+140-u+I); 
        u=u+a.*(b.*v-u)*dt; 
        W = W + alpha*(A_goal - A)*transpose(A).*W*dt;
    
        ge = [ge, mean(W(:, 1:800), 'all')];
        gi = [gi, mean(W(:, 801:1000), 'all')];
    
        if mod(100*i*dt/T, 5) == 0
            waitbar(i*dt/T, f, append('Please wait : ', int2str(100*i*dt/T), ' %'));
        end
    end
    close(f)
    delete(f)
end