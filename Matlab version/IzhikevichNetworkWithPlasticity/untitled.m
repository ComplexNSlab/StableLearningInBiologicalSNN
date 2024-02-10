dt = 0.1; % ms
T = 15000; % ms
period = 100; %ms

signal = zeros(1, T/dt);
for i = 1:T/dt/2
    if mod(i, period/dt) == 0
        signal(i) = 1/dt;
    end
end
for i = T/dt/2+2:T/dt
    if moTes
        d(i, period/2/dt) == 0
        signal(i) = 1/dt;
    end
end

subplot(2, 1, 1)
plot((dt:dt:T)/1000, signal)
xlabel('time (s)')
ylabel('signal')
legend(append('Period : ', num2str(period), ' ms', newline,'Frequency : ', num2str(1000*1/period), ' Hz'))

subplot(2, 1, 2)
tau = 1000;
plot((dt:dt:T)/1000, 1000*lowpass(signal, tau))
hold on
plot((dt:dt:T)/1000, 1000*repmat(1/period, 1, T/dt), 'r')
hold on
plot((dt:dt:T)/1000, 2*1000*repmat(1/period, 1, T/dt), 'r')
hold off
xlabel('time (s)')
ylabel('lowpass signal (Hz)')
legend(append('tau = ', num2str(tau/1000), ' s'))