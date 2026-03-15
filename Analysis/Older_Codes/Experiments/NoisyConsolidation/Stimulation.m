classdef Stimulation < handle
    
    properties
        network % targeted network (IzhikevichNetwork obj)
        Ncells = 50 % number of targeted celss

        interval % time (ms) interval between consecutive stimulation 
        start_time 

        duration = 2 % (ms) duration of stim current for each cell 
        amplitude = 30 % strength of stim current
        
        pattern_indices % index of stimulated cells
        pattern_timings % start time of stimulation for each cell

        on = true % whether stimulation is on or off momentarily 
        I_stim 
    end


    methods
        function obj = Stimulation(net, interval, duration, amplitude, Ncells, start_time)
            obj.network = net;
            obj.interval = interval;
            obj.duration = duration;
            obj.amplitude = amplitude;
            obj.Ncells = Ncells;
            obj.start_time = start_time;
            obj.ConstructStimSubset(false);
            obj.ConstructStimTimings();
            obj.ConstructStimCurrent();
            
            obj.network.stims = [obj.network.stims, obj]; % adding stim obj to the list of stims in the network 
        end

        function ConstructStimSubset(obj, connected)
            rng('shuffle');
            if connected
                obj.pattern_indices = [randsample(obj.network.Ne, 1)];
                for i = 1:nNeurons-1
                    connected_to = obj.network.out_cells(obj.pattern_indices(end));
                    for j = 1:length(connected_to)
                        if ~ismember(connected_to(j), obj.pattern_indices)
                            obj.pattern_indices = [obj.pattern_indices, connected_to(j)];
                            break
                        end
                    end
                end
            else
                obj.pattern_indices = randsample(1:obj.network.Ne, obj.Ncells, false);
            end
        end
        
        function ConstructStimTimings(obj)
            obj.pattern_timings = (obj.start_time + 1*randn(obj.Ncells,1)) ;
        end
        
        function ConstructStimCurrent(obj)
            n_t = round(obj.interval/obj.network.dt);
            obj.I_stim = zeros(obj.network.N, n_t);
            time_ = repmat(obj.network.dt:obj.network.dt:obj.interval, obj.Ncells, 1);
            indices = (time_ - repmat(obj.pattern_timings, 1, n_t)) <= obj.duration & (time_ - repmat(obj.pattern_timings, 1, n_t)) >= 0;
            obj.I_stim(obj.pattern_indices, :) = indices*obj.amplitude;
        end

        % Method to create a deep copy of the Stimulation object
        function new_obj = copy(obj)
            % Create a new Stimulation object with the same parameters
            new_obj = Stimulation(obj.network, obj.interval, obj.duration, obj.amplitude, obj.Ncells, obj.start_time);
            
            % Copy the other properties manually
            new_obj.pattern_indices = obj.pattern_indices;
            new_obj.pattern_timings = obj.pattern_timings;
            new_obj.on = obj.on;
            new_obj.I_stim = obj.I_stim;
        end
        
    end

end