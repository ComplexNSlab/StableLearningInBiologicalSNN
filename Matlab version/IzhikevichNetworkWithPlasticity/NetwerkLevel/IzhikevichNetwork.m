% dt, W, v, u, Ne, Ni, N, tau

classdef IzhikevichNetwork < handle

   properties
       t = 0, dt = 0.1
       Ne, Ni, N 
       u, v, A, w, I_syn
       a, b, c, d  
       A_goal, tau_A = 6000 % ms
       sampling_rate = 2000 % sampling rate of slow variables (w, A)
       
       sigma = 6; % white noise strength 
        
       alpha = 20;

       current_jump = 2 
       tau_syn = 5 % ms
        
       Data = struct('time', [], 'v', [], 'A', [], 'I_syn', [], 'spike_train', [], 'w', []) % saved data points
       
       plasticity = false % a logical variable, whether plasticity is on or off
       sampling = false % a logical variable, whether sampling is on or off
       noise = false
       input = false
       heterogeneity = false

       firings = []
   end

   methods
      function obj = IzhikevichNetwork(N)
          Ex_ratio = 0.8;
         
          Ne = round(Ex_ratio * N);
          Ni = round((1 - Ex_ratio) * N);
          obj.Ne = Ne; obj.Ni = Ni; obj.N = N;

          % network initialization
          obj.w = zeros(N, N);

          for i = 1:Ne
            array = [1:i-1, i+1:Ne]; % Example array
            randomChoices = array(randperm(length(array), 20));
                
            obj.w(i, randomChoices) = abs(0.5 + sqrt(0.05*0.5)*randn(1, 20));
            obj.w(i, Ne + randperm(Ni, 5)) = -8 + sqrt(0.05*8)*randn(1, 5);
          end
          
          for i = Ne+1:N
            obj.w(i, randperm(Ne, 5)) = 2 + sqrt(0.05*2)*randn(1, 5);
          end
           
          
          % Excitatory neurons Inhibitory neurons (Izhikevich neurons)
          if obj.heterogeneity 
              re = rand(Ne,1); ri = rand(Ni,1);
              obj.a = [0.02*ones(Ne,1); 0.02+0.08*ri];
              obj.b = [0.2*ones(Ne,1); 0.25-0.05*ri];
              obj.c = [-65+15*re.^2; -65*ones(Ni,1)];
              obj.d =[8-6*re.^2; 2*ones(Ni,1)];
          else
              obj.a = [0.02*ones(obj.Ne,1); 0.1*ones(obj.Ni,1)];
              obj.b = [0.2*ones(obj.Ne,1); 0.2*ones(obj.Ni,1)];
              obj.c = [-65*ones(obj.Ne,1); -65*ones(obj.Ni,1)];
              obj.d = [8*ones(obj.Ne,1); 2*ones(obj.Ni,1)];
          end  
            
          % variables initialization 
          obj.v = -65*ones(Ne+Ni,1); % Initial values of v (membrane potentials)
          obj.u = obj.b.*obj.v; % Initial values of u (membrane recovery variable)           
          obj.A = [0.00825* ones(Ne, 1); 0.00575* ones(Ni, 1)]*0;
          obj.I_syn = zeros(Ne+Ni, 1); % Initial values of synaptic current 

          obj.sampling = true;

          % obj.run(2000);
          % obj.A_goal = obj.A;
          obj.A_goal = [0.001*ones(Ne, 1); 0.002*ones(Ni, 1)];
          obj.plasticity = true;
      end

      function run(obj,T)
           tic 

           % rng('default')
            n_t = round(T/obj.dt); % total integration steps

            % variables to save in simulation
            % spike_trains = zeros(obj.Ne+obj.Ni, n_t);
            if obj.sampling
                if obj.plasticity
                    w_save = zeros(obj.Ne+obj.Ni, obj.Ne+obj.Ni, round(n_t/obj.sampling_rate));             
                end
                % I_syn_save = zeros(obj.Ne+obj.Ni, n_t);
                % v_save = zeros(obj.Ne+obj.Ni, n_t);
                A_save = zeros(obj.Ne+obj.Ni, round(n_t/obj.sampling_rate));
            end

            f = waitbar(0,'Please wait...');
            for i=1:n_t % simulation of T in ms
                
                obj.t = obj.t + obj.dt;
                
                % sampling variables
                obj.v(obj.v > 30) = 30;
                % v_save(:, i) = obj.v;
               
                if mod(i, obj.sampling_rate) == 0   
                    A_save(:, round(i/obj.sampling_rate)) = obj.A;
                    if obj.plasticity
                        w_save(:, :, round(i/obj.sampling_rate)) = obj.w;
                    end
                end
                
                % finding fired cells
                fired = find(obj.v >= 30); % indices of spikes
                obj.firings = [obj.firings; obj.t + 0*fired,fired];
                % spike_trains(obj.v >= 30, i) = 1/obj.dt;
                
                obj.I_syn = obj.I_syn - obj.I_syn*obj.dt/obj.tau_syn + obj.current_jump*(obj.v >= 30);
                
                obj.v(fired) = obj.c(fired);
                obj.u(fired) = obj.u(fired)+obj.d(fired);
                
                % thalamic (noisy) input + synaptic input
                I_thalamic = [obj.sigma*randn(obj.Ne,1); 0.4*obj.sigma*randn(obj.Ni,1)]*obj.noise/sqrt(obj.dt);
                
                
                I = I_thalamic + obj.w * obj.I_syn;
                
                if obj.input
                    if mod(round(obj.t), 1000) <= 10
                        I = I + 5*[ones(10, 1); zeros(obj.N-10, 1)];
                    end
                end

                % I_syn_save(:, i) = I - I_thalamic;

                % updating system

                obj.A = obj.A + -obj.A *obj.dt/obj.tau_A;
                obj.A(fired) = obj.A(fired) + 1/obj.tau_A; 
        
                if obj.plasticity 
                    obj.w = obj.w + obj.alpha * (((obj.A_goal - obj.A) * obj.A') .* abs(obj.w)) * obj.dt ;
                end

                obj.v = obj.v + obj.dt*(0.04*obj.v.^2 + 5*obj.v + 140 - obj.u + I); 
                obj.u = obj.u + obj.a.*(obj.b.*obj.v - obj.u)*obj.dt;
                
                if mod(i, 1000) == 0     
                    waitbar(i/n_t,f, sprintf('please wait : %d%% \n Simulation t/T : %0.1f / %0.1f \n Real time %0.1f s', round(100*i/n_t), obj.t/1000, T/1000, toc));
                end
            end
            
            if obj.sampling
                waitbar(1, f, 'saving the samples ...');
                if ~ isempty(obj.Data.time)
                    obj.Data.time = [obj.Data.time, obj.Data.time(end) + (1:n_t)*obj.dt];
                else
                    obj.Data.time = (1:n_t)*obj.dt;
                end

                % obj.Data.v = [obj.Data.v, v_save];
                obj.Data.A = [obj.Data.A, A_save];
                % obj.Data.I_syn = [obj.Data.I_syn, I_syn_save];
                % obj.Data.spike_train = [obj.Data.spike_train, spike_trains];
                if obj.plasticity 
                    obj.Data.w = cat(3, obj.Data.w, w_save);
                end
     
            end

            delete(f)
      end
       
   end

end



