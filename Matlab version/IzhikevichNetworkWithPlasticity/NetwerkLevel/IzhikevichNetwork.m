classdef IzhikevichNetwork < handle
   %% Izhikevich Network Class handle simulation of a SNN network with different plasticity mechanism on or off
   
   properties (Access = public)
       %% Recording Parameters
            RecordingDirectory 
            RecordingFile
            PatchNumber = 1
        
        Data = struct('time', [], 'A', [], 'w', [], 'firings', []) % saved data points

       %% Recording Containers
        time, w_save, A_save, firings
        %spike_trains
        spike_counter = 1;
   
       t = 0, dt = 0.1 
       %% Izhikevich Neurons Parameters 
           u, v
           Ne, Ni, N 
           a, b, c, d  
           heterogeneity = false % whether heterogenity is on or off
       %% Network Topology Parameters 
           w 
           Adjacency_matrix
           connections
           ExtoExDegree = 20, ExtoInhDegree = 5, InhtoExDegree = 5;
           g_ee = 0.5, g_ie = 2, g_ei = 8; % initial connectivity strength

           in_cells % the list of neurons connected to a given neuron (in_cells(Idx))
           out_cells % the list of neurons which a given neuron is connected to (out_cells(Idx))
       %% Post Synaptic Current Model 
           % it's an exponential decay current model
           I_syn
           current_jump = 2 
           tau_syn = 5 % ms
       %% Sampling (Recordings) Parameters 
           sampling = true % whether sampling is on or off
           sampling_rate = 5000 % sampling rate of slow variables (w, A)
       %% Noise Parameters
           noise = false % whether scaling is on or off
           sigma_ex = 5 % white noise strength 
           sigma_inh = 2
       %% Scaling Parameters 
           A
           scaling = false % whether scaling is on or off
           alpha = 20
           tau_A = 6000 % ms
           A_goal
       %% Hebbian STDP Parameters 
           STDP = false % whether STDP is on or off
           timer_vector
       %% External Stimulation (kick stim) Parameters 
           stimulation = false % whether external stimulation is on or off
           stims = [];
   end

   methods (Access = public)
      function obj = IzhikevichNetwork(N)
          %% Constructor of the network
          obj.RecordingDirectory = strrep(string(datetime('now', 'Format', 'MMM d uuuu HH mm')), ' ', '_');
          obj.RecordingDirectory = "Data" + filesep + obj.RecordingDirectory;

          obj.Constructor_IzhikevichNeurons(N)
          obj.Constructor_NetworkTopology

          clear N
          mkdir(obj.RecordingDirectory)
      end
      
      function SetInitialConnectivity(obj, g_ee, g_ei, g_ie)
          obj.g_ee = g_ee;
          obj.g_ei = g_ei;
          obj.g_ie = g_ie;
          
          obj.Constructor_NetworkTopology()
      end
        
      function AddHeterogeneity(obj)
          obj.heterogeneity = true;
          re = rand(obj.Ne,1); ri = rand(obj.Ni,1);
          obj.a = [0.02*ones(obj.Ne,1); 0.02+0.08*ri];
          obj.b = [0.2*ones(obj.Ne,1); 0.25-0.05*ri];
          obj.c = [-65+15*re.^2; -65*ones(obj.Ni,1)];
          obj.d =[8-6*re.^2; 2*ones(obj.Ni,1)];
      end

      function run(obj,T)
           tic 
           f = waitbar(0,'Please wait...');
            
           n_t = round(T/obj.dt); % total integration step
          
           obj.Constructor_RecordingContainers(n_t)
           obj.spike_counter = 1;
            

           for i=1:n_t % simulation of T in ms
                
                obj.t = obj.t + obj.dt;
                
                obj.v(obj.v > 30) = 30;
                % obj.v_save(:, i) = obj.v;
               
                if mod(i, obj.sampling_rate) == 0  && obj.sampling 
                    obj.A_save(:, round(i/obj.sampling_rate)) = obj.A;
                    if obj.scaling || obj.STDP
                        obj.w_save(:, :, round(i/obj.sampling_rate)) = obj.w;
                    end
                end
                
                % finding fired cells
                fired = find(obj.v >= 30); % indices of spikes
                
                if ~isempty(fired)
                    %obj.spike_trains(fired, i) = 1;
                    obj.firings(obj.spike_counter: obj.spike_counter + length(fired) - 1, :) = [obj.t + 0*fired, fired];
                    obj.spike_counter = obj.spike_counter + length(fired);
                    if obj.STDP
                        obj.applySTDP(fired)
                    end
                end
                
                if obj.STDP
                    obj.timer_vector = obj.timer_vector - obj.dt;
                    obj.timer_vector(obj.timer_vector < 0) = 0; 
                end

                obj.I_syn = obj.I_syn - obj.I_syn*obj.dt/obj.tau_syn + obj.current_jump*(obj.v >= 30);
                
                obj.v(fired) = obj.c(fired);
                obj.u(fired) = obj.u(fired)+obj.d(fired);
                
                
                I = obj.w * obj.I_syn;

                if obj.noise
                    I_noise = [obj.sigma_ex*randn(obj.Ne,1); obj.sigma_inh*randn(obj.Ni,1)]/sqrt(obj.dt);
                    I = I + I_noise;
                end

                if obj.stimulation
                   I_stim = zeros(obj.N, 1);
                   for stim = obj.stims
                       if stim.on
                           time_index = 1 + mod(round((obj.t - stim.start_time)/obj.dt), stim.interval/obj.dt);
                           I_stim = I_stim + stim.I_stim(:, time_index);
                       end
                   end
                   I = I + I_stim;
                end
                %obj.I_syn_save(:, i) = I;

                obj.A = obj.A - obj.A *obj.dt/obj.tau_A;
                obj.A(fired) = obj.A(fired) + 1000/obj.tau_A; 

                if obj.scaling && mod(i, 20) == 0
                    obj.w = obj.w + obj.alpha * (((obj.A_goal - obj.A) * obj.A') .* abs(obj.w)) * 20 * obj.dt ;
                end

                obj.v = obj.v + obj.dt*(0.04*obj.v.^2 + 5*obj.v + 140 - obj.u + I); 
                obj.u = obj.u + obj.a.*(obj.b.*obj.v - obj.u)*obj.dt;
                
                % updates the waitbar status
                if mod(i, 2000) == 0     
                    waitbar(i/n_t,f, sprintf('please wait : %d%% \n Simulation t/T : %0.1f / %0.1f \n Real time %0.1f s, Ratio : %0.2f', round(100*i/n_t), obj.t/1000, T/1000, toc, i*obj.dt/1000/toc));
                end
            end
            
           obj.firings = obj.firings(1:obj.spike_counter-1, :);
           
           waitbar(1, f,sprintf('Saving ... \n Real time %0.1f s', toc))
           obj.SaveRecordings
           

           delete(f)
      end
   
      function data = getData(obj)

        %% Reading and retrieving previously recorded dataset from the file
        if obj.PatchNumber > 2
            structs = {};
            for i = 1:obj.PatchNumber-1
                obj.RecordingFile = obj.RecordingDirectory + filesep + "Patch" + int2str(i);
                s = load(obj.RecordingFile, strcat('data', num2str(i)));
                structs{1, i} = s.(strcat('data', num2str(i)));
            end
            
            fields = fieldnames(obj.Data);
            data = struct();

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
                data.(field) = concatenatedData;
            end

            % obj.PatchNumber  = 2;
             
            % save(obj.RecordingFileName, "data1", 'obj', '-v7.3')
           
            
        else
            data = load(obj.RecordingFile, 'data1');
            data = data.data1;
        end
      end
   end
    
   methods (Static)
      function dw = STDP_kernel(w, t) 
          %% STDP Kernel for LTP and LTD 
          
          if t >= 0 % LTP
            % dw = exp(-t) - exp(-t/20);
            % dw = - 0.015 * w * log(abs(w)/3) * exp(-t/20);
            dw =  0.015 * w *  log(3/abs(w)) * exp(-t/20);
          else % LTD
             % dw = exp(t/5) * t * (19/20);
             dw =  - 0.03 * w *  exp(-abs(t)/20);
          end
          dw = 1 * dw;
      end
   end
    
   methods (Access = public)
      function Constructor_IzhikevichNeurons(obj, N)    
          Ex_ratio = 0.8;
          
          obj.N = N;
          obj.Ne = round(Ex_ratio * N);
          obj.Ni = round((1 - Ex_ratio) * N);

          % Excitatory neurons Inhibitory neurons (Izhikevich neurons)
          if obj.heterogeneity 
              re = rand(obj.Ne,1); ri = rand(obj.Ni,1);
              obj.a = [0.02*ones(obj.Ne,1); 0.02+0.08*ri];
              obj.b = [0.2*ones(obj.Ne,1); 0.25-0.05*ri];
              obj.c = [-65+15*re.^2; -65*ones(obj.Ni,1)];
              obj.d =[8-6*re.^2; 2*ones(obj.Ni,1)];
          else
              obj.a = [0.02*ones(obj.Ne,1); 0.1*ones(obj.Ni,1)];
              obj.b = [0.2*ones(obj.Ne,1); 0.2*ones(obj.Ni,1)];
              obj.c = [-65*ones(obj.Ne,1); -65*ones(obj.Ni,1)];
              obj.d = [8*ones(obj.Ne,1); 2*ones(obj.Ni,1)];
          end 
 
          obj.v = -65*ones(obj.Ne+obj.Ni,1); % Initial values of v (membrane potentials)
          obj.u = obj.b.*obj.v; % Initial values of u (membrane recovery variable)           
          obj.A = [0.0* ones(obj.Ne, 1); 0.0* ones(obj.Ni, 1)];
          obj.I_syn = zeros(obj.Ne+obj.Ni, 1); % Initial values of synaptic current
          obj.timer_vector = zeros(obj.N, 1);

          
      end

      function Constructor_NetworkTopology(obj)
          %% Constructor of Network Topology 
          obj.w = zeros(obj.N, obj.N);
         
          % 
          for i = 1:obj.Ne
            array = [1:i-1, i+1:obj.Ne]; % Example array
            randomChoices = array(randperm(length(array), obj.ExtoExDegree));
                
            obj.w(i, randomChoices) = abs(obj.g_ee + sqrt(0.05*obj.g_ee)*randn(1, obj.ExtoExDegree));
            obj.w(i, obj.Ne + randperm(obj.Ni, obj.InhtoExDegree)) = -obj.g_ei + sqrt(0.05*obj.g_ei)*randn(1, obj.InhtoExDegree);
          end
          
          for i = obj.Ne+1:obj.N
            obj.w(i, randperm(obj.Ne, 5)) = obj.g_ie + sqrt(0.05*obj.g_ie)*randn(1, obj.ExtoInhDegree);
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
            
          obj.w = obj.w;
      end
     
      function Constructor_RecordingContainers(obj, n_t)
            obj.RecordingFile = obj.RecordingDirectory + filesep + "Patch" + int2str(obj.PatchNumber);
            obj.firings = zeros(3000000, 2);
            obj.time = obj.t/1000 + (1: obj.sampling_rate : n_t)*obj.dt/1000;
            %obj.spike_trains = zeros(obj.Ne+obj.Ni, n_t);
            obj.w_save = zeros(obj.Ne+obj.Ni, obj.Ne+obj.Ni, round(n_t/obj.sampling_rate));             
            % obj.I_syn_save = zeros(obj.Ne+obj.Ni, n_t);
            % obj.v_save = zeros(obj.Ne+obj.Ni, n_t);
            obj.A_save = zeros(obj.Ne+obj.Ni, round(n_t/obj.sampling_rate));
      end
        
      function applySTDP(obj, fired)
            
            obj.timer_vector (fired) = 50;
            
            for fired_neuron = fired.'
                if fired_neuron <= obj.Ne
                    input_cells = obj.in_cells(fired_neuron); % If they have fired within a time window, they cause LTP
                    output_cells = obj.out_cells(fired_neuron); % If the have fired within a time window, they cause LTD
                    
                    % LTP
                    for in_idx = input_cells
                        delta_t = 50 - obj.timer_vector(in_idx);
                        if delta_t < 50 && in_idx <= obj.Ne
                            dw = IzhikevichNetwork.STDP_kernel(obj.w(fired_neuron, in_idx), delta_t);
                            obj.w(fired_neuron, in_idx) = obj.w(fired_neuron, in_idx) + dw;
                        end
                    end
    
                    % LTD
                    for out_idx = output_cells
                        delta_t = 50 - obj.timer_vector(out_idx);
                        if delta_t < 50 && out_idx <= obj.Ne
                            dw = IzhikevichNetwork.STDP_kernel(obj.w(out_idx, fired_neuron), -delta_t);
                            obj.w(out_idx, fired_neuron) = obj.w(out_idx, fired_neuron) + dw;
                        end
                    end
                end
            end
      end


      function SaveRecordings(obj)
     
              if ~obj.STDP && ~obj.scaling
                obj.w_save = repmat(obj.w, 1, 1, size(obj.w_save, 3));
              end
              
              data = struct('time', obj.time, 'A', obj.A_save, 'w', obj.w_save, 'firings', transpose(obj.firings));
              
              data.STDP = obj.STDP;
              
              data.scaling = obj.scaling;
              if obj.scaling
                  data.tau_A = obj.tau_A;
                  data.A_goal = obj.A_goal;
              end
              data.noise = obj.noise;
              data.stimulation = obj.stimulation;
              
              eval(['data' num2str(obj.PatchNumber) ' = data;']);
              obj.PatchNumber = obj.PatchNumber + 1;

              save(obj.RecordingFile, strcat('data', num2str(obj.PatchNumber-1)), 'obj');
      end
   
   end  

end

