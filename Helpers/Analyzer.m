classdef Analyzer
    properties
        data
        net
    end
    
    methods
        function obj = Analyzer(data, net)
            obj.data = data;
            obj.net = net;
        end
        
        %%
        function plotRasterMovie(obj)
            figure;
            firings = obj.data.firings;
            plot(firings(1,:) / 1000, firings(2,:), 'k.');
            xlabel('Time (s)');
            ylabel('Neuron index');
            title('Raster Plot');
        end
        
        %%
        function pair_correlation = computeCorrelation(obj)
            N = obj.net.N;
            signals = zeros(N, length(obj.net.time));
            firings = obj.data.firings;
            
            for i = 1:size(firings, 2)
                signals(firings(2, i), round(firings(1, i) / obj.net.dt)) = 1;
            end

            pair_correlation = zeros(N, N);
            for i = 1:N
                for j = 1:N
                    corr_coeff = xcorr(signals(i, :), signals(j, :));
                    normalization_factor = sqrt(sum(signals(i, :).^2) * sum(signals(j, :).^2));
                    pair_correlation(i, j) = max(corr_coeff) / normalization_factor;
                end
            end
        end
        
        %%
        function plotVoltageTrace(obj, neuronIdx)
            figure;
            plot(obj.data.time, obj.data.v(neuronIdx, :));
            xlabel('Time (ms)');
            ylabel('Membrane Potential (mV)');
            title(['Voltage Trace of Neuron ' num2str(neuronIdx)]);
        end
        
        %% COMPLETED 
        function plotWeightEvolution(obj)
            x = (1:size(obj.data.w, 3))*obj.net.dt*obj.net.sampling_rate;  % Assuming meanValues is your array of mean values

            data1 = reshape(obj.data.w(1:obj.net.Ne, 1:obj.net.Ne, :), obj.net.Ne*obj.net.Ne, length(x));
            data2 = reshape(obj.data.w(1:obj.net.Ne, obj.net.Ne+1:end, :), obj.net.Ne*obj.net.Ni, length(x));
            data3 = reshape(obj.data.w(obj.net.Ne+1:end, 1:obj.net.Ne, :), obj.net.Ni*obj.net.Ne, length(x));
            
            rowsToRemove = all(data1 == 0, 2);
            data1(rowsToRemove, :) = [];
            rowsToRemove = all(data2 == 0, 2);
            data2(rowsToRemove, :) = [];
            rowsToRemove = all(data3 == 0, 2);
            data3(rowsToRemove, :) = [];
            
            meanLine1 = squeeze(mean(data1, 1));     % Mean values
            meanLine2 = squeeze(mean(data2, 1));
            meanLine3 = squeeze(mean(data3, 1));
            
            % Calculate the upper and lower bounds
            upperBound1 = prctile(data1, 95, 1);
            lowerBound1 = prctile(data1, 5, 1);
            upperBound2 = prctile(data2, 95, 1);
            lowerBound2 = prctile(data2, 5, 1);
            upperBound3 = prctile(data3, 95, 1);
            lowerBound3 = prctile(data3, 5, 1);
            
            % Concatenate the upper bound and reversed lower bound
            xPolygon = [x, fliplr(x)];  % x coordinates for the polygon
            yPolygon1 = [upperBound1, fliplr(lowerBound1)];  % y coordinates for the polygon
            yPolygon2 = [upperBound2, fliplr(lowerBound2)];  % y coordinates for the polygon
            yPolygon3 = [upperBound3, fliplr(lowerBound3)];  % y coordinates for the polygon
            
            figure('Renderer', 'painters', 'Position', [100 100 1000 1000]); % Adjust position and size as needed
            % Plot the mean lines
            ax = axes('Position', [0.2, 0.2, 0.6, 0.6]); % [left, bottom, width, height]
            fsize = 25;
            plot(ax, x/1000, meanLine1, 'k', 'LineWidth', 2, 'Color',"#77AC30"); 
            hold on;
            plot(ax, x/1000, meanLine2, 'b.-', 'LineWidth', 2, 'Color',"#7E2F8E")
            plot(ax, x/1000, meanLine3, 'r', 'LineWidth', 2, 'Color',"#D95319")
            
            % Shade the area between upper and lower bounds
            % fillColor = [0.8, 0.8, 0.8]; % Light gray fill
            % plot(x, upperBound1, 'k')
            % plot(x, lowerBound1, 'k')
            % 
            % plot(x, upperBound2, 'b')
            % plot(x, lowerBound2, 'b')
            % 
            % plot(x, upperBound3, 'r')
            % plot(x, lowerBound3, 'r')
            
            fill(xPolygon/1000, yPolygon1, 'k', 'EdgeColor', 'none', 'FaceAlpha', 0.5, 'FaceColor', "#77AC30");
            hold on
            fill(xPolygon/1000, yPolygon2, 'b', 'EdgeColor', 'none', 'FaceAlpha', 0.5, 'FaceColor', "#7E2F8E");
            fill(xPolygon/1000, yPolygon3, 'r', 'EdgeColor', 'none', 'FaceAlpha', 0.5, 'FaceColor', "#D95319");
            
            % Additional plot adjustments
            xlabel('time (s)');
            ylabel('W');
            title('Weigths Evolution in Time (90% CI)');
            legend('g_{ee}', 'g_{ei}', 'g_{ie}', Location='southwest')
            ylim([-5, 5])
            hold off;
            set(gca, 'FontName', 'Arial', 'FontSize', fsize, 'FontWeight', 'bold'); 
        end
        
        %%
        function plotWeightHistogram(obj, frame)
            figure;
            hold on;
            histogram(obj.data.w(:, :, frame), 50, 'Normalization', 'pdf');
            xlabel('Weight');
            ylabel('PDF');
            title('Weight Distribution at a Specific Time');
            hold off;
        end
        
        %%
        function saveWeightAnimation(obj, videoFileName)
            writerObj = VideoWriter(videoFileName, 'MPEG-4');
            writerObj.FrameRate = 30;
            open(writerObj);
            fig = figure;
            for i = 1:5:size(obj.data.w, 3)
                clf;
                histogram(obj.data.w(:, :, i), 50, 'Normalization', 'pdf');
                title(sprintf('Weights Histogram at Time %.2f s', i * obj.net.sampling_rate * obj.net.dt / 1000));
                xlabel('Weight');
                ylabel('PDF');
                drawnow;
                frame = getframe(fig);
                writeVideo(writerObj, frame);
            end
            close(writerObj);
            close(fig);
        end
    
        %%
        function [check_flag_save, check_flag_save2] = computeOrders(obj)
             %% Computing the order vectors from patch.mat files for computation speed reasons:)

            off_set_time = 0;
            interval = 100;

            check_flag_save2 = zeros(round(obj.net.t/interval), obj.net.N);
            check_flag_save = zeros(round(obj.net.t/interval), obj.net.N);
            total_spike_count = zeros(1, round(obj.net.t/interval));
            ex_neurons_engagement_count = zeros(1, round(obj.net.t/interval));
            inh_neurons_engagement_count = zeros(1, round(obj.net.t/interval));
            
            f = waitbar(0, "Computing First to Spike Orders ...");
            trial_counter = 0;
            time_keeper = 0;
            for patch_num = 1:obj.net.PatchNumber-1
                patch_address = obj.net.RecordingDirectory + filesep + "Patch" + num2str(patch_num) + ".mat";
                pathParts = strsplit(patch_address, {'\', '/'});
                patch_address = fullfile(pathParts{:});
            
                variable_name = "data" + num2str(patch_num);
                s = load(patch_address);
                obj.data = getfield(s, variable_name);
                obj.net = getfield(s, 'obj');
                firings = transpose(obj.data.firings);
                firings(:, 1) = firings(:, 1) - time_keeper;
                
                for trial_number = 1:round((obj.net.t-time_keeper)/interval)
                    % Computing the orders
                    
                    start_time = (firings(:, 1) > (trial_number-1) * interval + off_set_time);
                    end_time = (firings(:, 1) <= trial_number * interval + off_set_time);
                    indices = start_time & end_time;
                    spike_times = firings(indices, 1);
                    neuron_indices = firings(indices, 2);    
                    
                    order = obj.TimeToFirstSpikeSort(spike_times, neuron_indices, true, obj.net.N, obj.net.Ne);
                    order2 = obj.TimeToFirstSpikeSort(spike_times, neuron_indices, false, obj.net.N, obj.net.Ne);
                    trial_counter = trial_counter + 1;
                    check_flag_save(trial_counter, :) = order;
                    check_flag_save2(trial_counter, :) = order2;
                    total_spike_count(trial_counter) =  length(spike_times);
                    ex_neurons_engagement_count(trial_counter) = sum(unique(neuron_indices)<=obj.net.Ne);
                    inh_neurons_engagement_count(trial_counter) = sum(unique(neuron_indices)>obj.net.Ne);
            
                    waitbar(patch_num/(obj.net.PatchNumber-1), f, sprintf("Computing First to Spike Orders ... \n trial %d, patch %d/%d", trial_counter, patch_num, obj.net.PatchNumber-1))
                end
            
                time_keeper = obj.net.t;
            end
            
            close(f)
        end
    end

    methods (Static)
        %%
        function order = TimeToFirstSpikeSort(spike_times, neuron_indices, separated, N, Ne)
            % TimeToFirstSpikeSort Sorting neurons based on first time to spike.
            %
            % Syntax:
            %   order = TimeToFirstSpikeSort(spike_times, neuron_indices)
            %
            % Description:
            %   A detailed description of the function, explaining its purpose and
            %   how it works.
            %
            % Input Arguments:
            %   spike_times - an array of spike timings.
            %   neuron_indices - an array of neuron indices of spikes.
            %   separated - if order excitatory and inhibitory spikes separately or
            %   together
            %
            % Output Arguments:
            %   order - ordered indices of neurons by who spiked earlier.
            
           
            order = zeros(1, N); % a vector that labels cells by spike order
            neuron_sorted_indices = zeros(size(spike_times, 1), 1); % sorted neuron indices signal
            
            if separated 
                counter_ex = 1;
                counter_inh = Ne + 1;
              
                for i = 1:length(spike_times)
                    if neuron_indices(i) <= Ne
                        if order(neuron_indices(i)) == 0 % First excitatory spikes
                            neuron_sorted_indices(i) = counter_ex;
                            order(neuron_indices(i)) = counter_ex;
                            counter_ex = counter_ex + 1;
                        else % Repeated excitatory spikes
                            neuron_sorted_indices(i) = order(neuron_indices(i));
                        end
                    else
                        if order(neuron_indices(i)) == 0 % First Inhibitory spikes
                            neuron_sorted_indices(i) = counter_inh;
                            order(neuron_indices(i)) = counter_inh;
                            counter_inh = counter_inh + 1;
                        else % Repeated Inhibitory spikes
                            neuron_sorted_indices(i) = order(neuron_indices(i));
                        end
                    end  
                end
            end
        
            if ~separated
                counter = 1; 
                for i = 1:length(spike_times)
                    if order(neuron_indices(i)) == 0 % First spike
                        neuron_sorted_indices(i) = counter;
                        order(neuron_indices(i)) = counter;
                        counter = counter + 1;
                    else % Repeated spike
                        neuron_sorted_indices(i) = order(neuron_indices(i));
                    end
                end
            end
        
        end
    end
end
