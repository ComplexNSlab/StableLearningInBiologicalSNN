function [firings, ge, gi] = Rates(alpha, sigma)
    % Excitatory neurons Inhibitory neurons
    Ne=800; Ni=200;
    a=[0.02*ones(Ne,1); 0.1*ones(Ni,1)];
    b=[0.2*ones(Ne,1); 0.2*ones(Ni,1)];
    c=[-65*ones(Ne,1); -65*ones(Ni,1)];
    d=[8*ones(Ne,1); 2*ones(Ni,1)];

    g = 0.5;
    W=[g*rand(Ne+Ni,Ne), -2*g*rand(Ne+Ni,Ni)];
    
    v=-65*ones(Ne+Ni,1); % Initial values of v
    u=b.*v; % Initial values of u
    I_syn = zeros(Ne+Ni,1);
    tau_syn = 5; %ms
    current_jump = 0.2;
    
    A = [0.006*ones(1, Ne), 0.012*ones(1, Ni)];
    tau_A = 2000;
    A_goal = [0.001*ones(1, Ne), 0.002*ones(1, Ni)];
    ge = [];
    gi = [];
    firings=[]; % spike timings
    dt = 0.5;
    T = 1000; 
    
    f = waitbar(0, 'Please wait ...');
    for t=0:dt:T % simulation of 1000 ms
        I_syn = I_syn - I_syn*dt/tau_syn + current_jump*(v >=30);
        A = A - A*dt/tau_A + 1*(v >= 30)/tau_A;

        fired = find(v>=30); % indices of spikes
        firings = [firings; t+0*fired,fired];
        

        v(fired)=c(fired);
        u(fired)=u(fired)+d(fired);
        
        I=[sigma*randn(Ne,1);0.4*sigma*randn(Ni,1)]/sqrt(dt); % thalamic input
        I = I + W*I_syn;
       
        v=v+dt*(0.04*v.^2+5*v+140-u+I); 
        u=u+a.*(b.*v-u)*dt; 
        W = W + alpha*(A_goal - A)*transpose(A).*W*dt;

        if mod(100*t/T, 10) == 0
            ge = [ge, mean(W(:, 1:800), 'all')];
            gi = [gi, mean(W(:, 801:1000), 'all')];
            waitbar(t/T, f, append('Please wait : ', int2str(100*t/T), ' %'));
        end
    end
    close(f)
    delete(f)
    
    % e_rate = sum(firings(:, 2) <= 800)/(T/1000)/800; % Hz
    % i_rate = sum(firings(:, 2) > 800)/(T/1000)/200; % Hz
end
