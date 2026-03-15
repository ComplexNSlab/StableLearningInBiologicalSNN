
% Parameters
fs = 44100;       % Sampling frequency (samples per second)
duration = 0.3;   % Duration of each tone in seconds

% Generate time vector for each tone
t = linspace(0, duration, fs * duration);

% Define frequencies for the chime tones
freq1 = 880;  % First tone frequency (A5)
freq2 = 1760; % Second tone frequency (A6)

% Generate the first tone (smooth start and end)
y1 = sin(2 * pi * freq1 * t) .* (0.5 * (1 - cos(2 * pi * t / duration)));

% Generate the second tone (smooth start and end)
y2 = sin(2 * pi * freq2 * t) .* (0.5 * (1 - cos(2 * pi * t / duration)));

% Combine the tones with a slight pause in between
pause_duration = 0.05; % Pause duration between tones
pause_samples = round(pause_duration * fs);
y = [y1, zeros(1, pause_samples), y2];

% Normalize the sound to avoid clipping
y = y / max(abs(y));

% Create audioplayer object
player = audioplayer(y, fs);

playNotificationSound1(player)

% Function to play notification sound 
function playNotificationSound1(player)
   
    play(player);
end


