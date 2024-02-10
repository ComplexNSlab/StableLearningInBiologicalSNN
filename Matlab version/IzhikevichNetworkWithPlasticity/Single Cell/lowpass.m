function l = lowpass(signal, tau)
    
    [n, n_t] = size(signal);
    l = zeros(n, n_t);
    l(:, 1) = signal(:, 1);
    for i=2:n_t
        l(:, i) = l(:,i-1) + (signal(:, i-1) - l(:, i-1))*0.1/tau;
    end
    l = 1000 * l; % this part convert the signal from KHz to Hz
end