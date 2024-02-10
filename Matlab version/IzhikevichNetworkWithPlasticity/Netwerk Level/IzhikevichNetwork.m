
classdef IzhikevichNetwork < handle
   properties
       Parameters struct % A struct to hold simulation parameters
       dt = 0.1; % ms
       data = struct; % all the data of simulation are in s
   end

   methods
      function obj = IzhikevichNetwork(T)
          p = struct;
          p.dt = obj.dt;
          p.Ne = 800;
          p.Ni = 200;
          p.ge = 0.5;
          p.syn_tau = 5; % ms
          p.A_tau = 10000; % ms

          obj.Parameters = p;

          obj.run(T)
      end

      function run(obj,T)
            rng('default')

           % Excitatory neurons Inhibitory neurons (Izhikevich neurons)
            Ne=800; Ni=200;
            re=rand(Ne,1); ri=rand(Ni,1);
            a=[0.02*ones(Ne,1); 0.02+0.08*ri];
            b=[0.2*ones(Ne,1); 0.25-0.05*ri];
            c=[-65+15*re.^2; -65*ones(Ni,1)];
            d=[8-6*re.^2; 2*ones(Ni,1)];
    
            % network initialization
            ge = obj.Parameters.ge; gi = -2*ge;
            w=[ge*rand(Ne+Ni,Ne), gi*rand(Ne+Ni,Ni)];
            diagonalMask = logical(eye(size(w)));
            w(diagonalMask) = 0;
    
            % variables initialization 
            v = -65*ones(Ne+Ni,1); % Initial values of v (membrane potentials)
            u = b.*v; % Initial values of u (membrane recovery variable)
            
            A_goal = [repmat(0.008, Ne, 1); repmat(0.016, Ni, 1)];
            A = [repmat(0.008, Ne, 1); repmat(0.016, Ni, 1)];
    
    
            I_syn = zeros(Ne+Ni, 1); % Initial values of synaptic current
            tau = obj.Parameters.syn_tau; % ms
            current_jump = 1/tau;
            


            T = T*1000; % ms
            n_t = T/obj.dt; % total integration steps

            % variables to save in simulation
            I_syn_save = zeros(Ne+Ni, n_t);
            I_thalamic_save = zeros(Ne+Ni, n_t);
            v_save = zeros(Ne+Ni, n_t);
            firings=[]; % spike timings
            spike_trains = zeros(Ne+Ni, n_t);
            A_save = zeros(Ne+Ni, n_t);

            sampling_rate = 100;
            % w_save = zeros(Ne+Ni, Ne+Ni, n_t/sampling_rate);

            f = waitbar(0,'Please wait...');
            for i=1:n_t % simulation of T in ms
            
                % sampling variables
                I_syn_save(:, i) = I_syn;
                v(v > 30) = 30;
                v_save(:, i) = v;
                A_save(:, i) = A;
                % if mod(i, sampling_rate) == 0
                %     w_save(:, :, i/sampling_rate) = w;
                % end
                
                
                % finding fired cells
                fired=find(v>=30); % indices of spikes
                firings=[firings; i*obj.dt+0*fired,fired];
                spike_trains(v>=30, i) = 1/obj.dt;
                
                I_syn = I_syn - I_syn*obj.dt/tau + current_jump*(v >= 30);
                
                v(fired)=c(fired);
                u(fired)=u(fired)+d(fired);
                
                % thalamic (noisy) input + synaptic input
                I_thalamic = [5*randn(Ne,1);2*randn(Ni,1)]/sqrt(obj.dt);
                I_thalamic_save(:, i) = I_thalamic;
                I= I_thalamic + w*I_syn;
            
                % updating system
                A = A + (- A+ spike_trains(:, i))*obj.dt/obj.Parameters.A_tau ;
                % w = w + (A_goal - A)*transpose(A) .* w * dt;
                v=v+obj.dt*(0.04*v.^2+5*v+140-u+I); 
                u=u+a.*(b.*v-u)*obj.dt;
                
                if mod(i, 1000) == 0
                    waitbar(i/n_t,f, append('please wait : ',num2str(100*i/n_t) , ' %'));
                end
            end
                
            delete(f)
            
            time_array = (obj.dt:obj.dt:T)/1000;
    
    
    
            s = struct;
            s.time = time_array;
            s.v = v_save;
            s.A = A_save;
            % s.w = w_save;
            s.spike_trains = spike_trains;
            s.I_syn = I_syn_save;
            s.firings = firings;
            s.I_thalamic = I_thalamic_save;
            obj.data = s;

      end

      function NeuronActivity(obj, index)

            s = obj.data;
            T = length(s.time)*obj.dt;
           
            figure("Name", append('Neuron ',  int2str(index) , ' Activity'))
            
            tiledlayout(2, 2)
            title(append('Neuron ',  int2str(index) , ' Activity'));

            ax1 = nexttile;
            plot(s.time, s.v(index, :))
            xlabel('time (s)')
            ylabel('mebrane potential (mV)')
            
            ax2 = nexttile;
            plot(s.time, s.spike_trains(index, :) * obj.dt)
            xlabel('time (s)')
            ylabel('spike train')
     
            ax3 = nexttile;
            plot(s.time, 1000*s.A(index, :))
            hold on 
            plot(s.time, repmat(1000*sum(s.spike_trains(index,:))*obj.dt/T, 1, T/obj.dt));
            hold off
            legend(append('tau = ', num2str(obj.Parameters.A_tau), ' ms'));
            xlabel('time (s)')
            ylabel('A (Hz)')

            ax4 = nexttile;
            plot(s.time, s.I_syn(index, :))
            xlabel('time (s)')
            ylabel('current (?)')

            linkaxes([ax1, ax2, ax3, ax4], 'x')
            ax1.XLim = [0 T/1000];
      end
   
      function Raster(obj)
          figure("Name", 'Raster Plot')
          plot(obj.data.firings(:,1)/1000,obj.data.firings(:,2), '.' )
          ylabel('Neuron index')
          xlabel('time (s)')
          title('Raster plot')
      end
   end
end




