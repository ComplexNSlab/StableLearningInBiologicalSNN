% dt, W, v, u, Ne, Ni, N, tau

classdef IzhikevichNetwork < handle
    
   properties (Access = private)
        % temporary containers for sampling variables
        data_file_name 
        patch_number = 1
        
        Data = struct('time', [], 'A', [], 'w', [], 'firings', []) % saved data points
        time, w_save, A_save 
        spike_counter = 1;
        timer_vector
   end

   properties
       t = 0, dt = 0.1
       Ne, Ni, N 
       u, v, A, w, I_syn
       a, b, c, d  
       A_goal, tau_A = 6000 % ms
       sampling_rate = 2000 % sampling rate of slow variables (w, A)
       
       Adjacency_matrix
       connections
       sigma = 6; % white noise strength 
        
       alpha = 20;

       current_jump = 2 
       tau_syn = 5 % ms
        

       scaling = false % a logical variable, whether scaling is on or off
       sampling = true % a logical variable, whether sampling is on or off
       noise = true
       input = false
       heterogeneity = false
       STDP = false
       firings

       in_cells
       out_cells
   end

   methods
      function obj = IzhikevichNetwork(N)
          obj.data_file_name = strrep(strcat(string(datetime('now', 'Format', 'MMM d uuuu HH mm')), '.mat'), ' ', '_');
          save(obj.data_file_name)

          Ex_ratio = 0.8;
         
          Ne = round(Ex_ratio * N);
          Ni = round((1 - Ex_ratio) * N);
          obj.Ne = Ne; obj.Ni = Ni; obj.N = N;
          
          obj.firings = zeros(1000000, 2);
          obj.Initialize_Topology
          obj.timer_vector = zeros(obj.N, 1);

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
          obj.A = [0.0* ones(Ne, 1); 0.0* ones(Ni, 1)];
          obj.I_syn = zeros(Ne+Ni, 1); % Initial values of synaptic current 
      end
      
      function run(obj,T)
           tic 
           f = waitbar(0,'Please wait...');
            
           obj.firings = zeros(1000000, 2);
           n_t = round(T/obj.dt); % total integration step
           
           
          
           obj.Initialize_SamplingContainers(n_t)
           
           for i=1:n_t % simulation of T in ms
                
                obj.t = obj.t + obj.dt;
                
                % sampling variables
                obj.v(obj.v > 30) = 30;
                % obj.v_save(:, i) = obj.v;
               
                if mod(i, obj.sampling_rate) == 0   
                    obj.A_save(:, round(i/obj.sampling_rate)) = obj.A;
                    if obj.scaling || obj.STDP
                        obj.w_save(:, :, round(i/obj.sampling_rate)) = obj.w;
                    end
                end
                
                % finding fired cells
                fired = find(obj.v >= 30); % indices of spikes
                
                if ~isempty(fired)        
                    obj.firings(obj.spike_counter: obj.spike_counter + length(fired) - 1, :) = [obj.t + 0*fired, fired];
                    obj.spike_counter = obj.spike_counter + length(sum(fired));
                    if obj.STDP
                        obj.applySTDP(fired)
                    end
                end
                if obj.STDP
                    obj.timer_vector = obj.timer_vector - obj.dt;
                    obj.timer_vector(obj.timer_vector < 0) = 0; 
                end
                

                % obj.spike_trains(obj.v >= 30, i) = 1/obj.dt;
                
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
                

                if obj.scaling && mod(i, 20) == 0
                    obj.w = obj.w + obj.alpha * (((obj.A_goal - obj.A) * obj.A') .* abs(obj.w)) * 20 * obj.dt ;
                end

    
                obj.v = obj.v + obj.dt*(0.04*obj.v.^2 + 5*obj.v + 140 - obj.u + I); 
                obj.u = obj.u + obj.a.*(obj.b.*obj.v - obj.u)*obj.dt;
                
                if mod(i, 1000) == 0     
                    waitbar(i/n_t,f, sprintf('please wait : %d%% \n Simulation t/T : %0.1f / %0.1f \n Real time %0.1f s', round(100*i/n_t), obj.t/1000, T/1000, toc));
                end
            end
            
           if obj.sampling 
               waitbar(1, f,sprintf('Saving ... \n Real time %0.1f s', toc))
               obj.SampleContainers
           end

           delete(f)
      end
       
     function data1 = getData(obj)
        if obj.patch_number > 2
            structs = {};
            for i = 1:obj.patch_number-1
                s = load(obj.data_file_name, strcat('data', num2str(i)));
                structs{1, i} = s.(strcat('data', num2str(i)));
            end
            
            fields = fieldnames(obj.Data);
            data1 = struct();

            for i = 1:length(fields)
                field = fields{i};
                % Initialize an empty array to hold the concatenated data
                concatenatedData = [];
                dim = length(size(structs{1}.(field)));
                % Loop over each struct
                for j = 1:length(structs)
                    concatenatedData = cat(dim ,concatenatedData, structs{j}.(field));
                end
                
                % Assign the concatenated data to the corresponding field in the new struct
                data1.(field) = concatenatedData;
            end

            obj.patch_number  = 2;
             
            save(obj.data_file_name, "data1", 'obj', '-v7.3')
           
            
        else
            data1 = load(obj.data_file_name, 'data1');
        end
     end
   end
    
   methods (Access = private)
      function Initialize_Topology(obj)
          % network initialization
          obj.w = zeros(obj.N, obj.N);
         
          for i = 1:obj.Ne
            array = [1:i-1, i+1:obj.Ne]; % Example array
            randomChoices = array(randperm(length(array), 20));
                
            obj.w(i, randomChoices) = abs(0.5 + sqrt(0.05*0.5)*randn(1, 20));
            obj.w(i, obj.Ne + randperm(obj.Ni, 5)) = -8 + sqrt(0.05*8)*randn(1, 5);
          end
          
          for i = obj.Ne+1:obj.N
            obj.w(i, randperm(obj.Ne, 5)) = 2 + sqrt(0.05*2)*randn(1, 5);
          end

          obj.Adjacency_matrix = logical(obj.w);
          [row, col] = find(obj.Adjacency_matrix);
          obj.connections = [row, col]; 

          obj.in_cells = containers.Map('KeyType', 'double', 'ValueType', 'any');
          obj.out_cells = containers.Map('KeyType', 'double', 'ValueType', 'any');
        
          for i = 1:obj.N
               obj.in_cells(i) = find(obj.Adjacency_matrix(i, :));
          end
          for i = 1:obj.N
               obj.out_cells(i) = find(obj.Adjacency_matrix(:, i)).';
          end

      end
     
      function Initialize_SamplingContainers(obj, n_t)
            % variables to sample in simulation
            obj.time = obj.t + (1:n_t)*obj.dt;
            % obj.spike_trains = zeros(obj.Ne+obj.Ni, n_t);
            obj.w_save = zeros(obj.Ne+obj.Ni, obj.Ne+obj.Ni, round(n_t/obj.sampling_rate));             
            % obj.I_syn_save = zeros(obj.Ne+obj.Ni, n_t);
            % obj.v_save = zeros(obj.Ne+obj.Ni, n_t);
            obj.A_save = zeros(obj.Ne+obj.Ni, round(n_t/obj.sampling_rate));
      end
        
      function applySTDP(obj, fired)
            
            obj.timer_vector (fired) = 50;
            
            for fired_neuron = fired.'
                input_cells = obj.in_cells(fired_neuron); % If they have fired within a time window, they cause LTP
                output_cells = obj.out_cells(fired_neuron); % If the have fired within a time window, they cause LTD
                
                % LTP
                for in_idx = input_cells
                    delta_t = 50 - obj.timer_vector(in_idx);
                    if delta_t < 50 && in_idx <= obj.Ne
                        dw = STDP_kernel(obj, obj.w(fired_neuron, in_idx), delta_t);
                        obj.w(fired_neuron, in_idx) = obj.w(fired_neuron, in_idx) + dw;
                    end
                end

                % LTD
                if fired_neuron <= obj.Ne
                    for out_idx = output_cells
                        delta_t = 50 - obj.timer_vector(out_idx);
                        if delta_t < 50   
                            dw = STDP_kernel(obj, obj.w(out_idx, fired_neuron), -delta_t);
                            obj.w(out_idx, fired_neuron) = obj.w(out_idx, fired_neuron) + dw;
                        end
                    end
                end
            end
      end

      function dw = STDP_kernel(~, w, t) 
          
          if t > 0 % potentiation 
            % dw = exp(-t) - exp(-t/20);
            dw = - 0.01 * w * log(abs(w)/3) * exp(-t/20);
          else % depression
             % dw = exp(t/5) * t * (19/20);
             dw =  - 0.003 * w *  exp(t/20);
          end
      end

      function SampleContainers(obj)
          obj.firings = obj.firings(1:obj.spike_counter-1, :);
          data = struct('time', obj.time, 'A', obj.A_save, 'w', obj.w_save, 'firings', transpose(obj.firings));
          
          eval(['data' num2str(obj.patch_number) ' = data;']);

          save(obj.data_file_name, strcat('data', num2str(obj.patch_number)), '-append');
         
          obj.patch_number = obj.patch_number + 1;
          
          obj.spike_counter = 1;
      end
   end
end



