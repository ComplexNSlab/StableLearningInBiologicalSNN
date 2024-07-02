classdef Stimulation < handle
    
    properties
        network % targeted network (IzhikevichNetwork obj)
        Ncells = 50 % number of targeted celss

        interval = 1000 % time (ms) interval between consecutive stimulation 
        
        duration = 2 % duration of stim current 
        amplitude = 30 % strength of stim current
        
        pattern_indices % index of stimulated cells
        pattern_timings % start time of stimulatino for each cell

        on = true % whether stimulation is on or off momentarily 
    end


    methods
        function obj = Stimulation(net, interval, duration, amplitude, Ncells)
            obj.network = net;
            obj.interval = interval;
            obj.duration = duration;
            obj.amplitude = amplitude;
            obj.Ncells = Ncells;
            obj.ConstructStimSubset(false);
            obj.ConstructStimTimings();
        end

        function ConstructStimSubset(obj, connected)
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
                obj.pattern_indices = randsample(setxor(1:obj.network.Ne, obj.pattern_indices), obj.Ncells, false);
            end
        end
        
        function ConstructStimTimings(obj)
            obj.pattern_timings = (5 + 2*randn(obj.Ncells,1)) ;
        end

        function I_stim = getStimCurrent(obj, n_t)
            I_stim = zeros(obj.network.N, n_t);

            if obj.on
                time_ = repmat(mod(obj.network.dt*(1:n_t) + obj.network.t, obj.interval), obj.Ncells, 1);
                indices = (time_ - repmat(obj.pattern_timings, 1, n_t)) <= obj.duration & (time_ - repmat(obj.pattern_timings, 1, n_t)) >= 0;
                I_stim(obj.pattern_indices, :) = indices*obj.amplitude;
            end
        end
    end

end