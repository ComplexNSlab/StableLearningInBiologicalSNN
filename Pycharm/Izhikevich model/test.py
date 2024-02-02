import matplotlib.pyplot as plt
import matplotlib;
import numpy as np

matplotlib.use("TkAgg")
from matplotlib.animation import FuncAnimation
from Izhikevich import *


network = IzhikevichNetwork(n=1000)
network.simulate(T=1000)

# plt.eventplot(network.get_spike_raster, colors='k')
# plt.xlabel('time (mS)')
# plt.ylabel('cell index')
# plt.hlines(xmin=0, xmax=network.totalTime, y=800, colors='k', linewidth = 0.5)
# plt.title('Izhikevich model spike raster')
# plt.show()


def lowpass(signal, tau):
    n, n_t = signal.shape

    S = np.zeros([n, n_t])
    s = np.zeros(n) - 65
    for i in range(n_t):
        S[:, i] = s
        s += (signal[:, i] - s)*IzhikevichSpikingNeuron.dt/tau

    return S


A = lowpass(network.get_potential_traces, 0.1)
plt.plot(network.get_potential_traces[0, :])
plt.plot(A[0, :])

plt.show()

# array = np.array(network.w_save)

# def animate(frame):
#     global array
#     plt.clf()  # Clear the previous frame
#     plt.imshow(array[frame, :, :], cmap='viridis')
#     plt.colorbar(orientation='horizontal')
#     plt.title(f'Frame {frame*IzhikevichSpikingNeuron.dt} mS')
#
#
# anim = FuncAnimation(plt.figure(), animate, frames=1000, interval=0)
#
# plt.show()


# traces = network.get_potential_traces()
# plt.plot(traces[0, :])
# plt.show()
#
#
# traces = network.get_axon_current_traces()
# plt.plot(traces[0, :])
# plt.show()


# mycell = network.cells[0]
#
# t, axon_current = mycell.axon_current_trace
# plt.plot(t, axon_current)
# plt.show()

# mycell = IzhikevichSpikingNeuron(inhibitory=True)
# dt = 0.1
# T = 100
# t0 = 50
# tau = 20 # mS
# g = 100 #
# time_array = np.arange(0, T, dt)
# for t in time_array:
#     input_current = 1*(t-t0 > 0)*g*np.exp(-(t-t0)/tau)
#     mycell.update(I=input_current)
#
# plt.subplot(3,1,1)
# plt.plot(time_array, np.multiply(1*(time_array-t0 > 0), g*np.exp(-(time_array-t0)/tau)))
# plt.ylabel('input current ')
# plt.subplot(3,1,2)
# plt.plot(time_array, mycell.potential_trace)
# plt.ylabel('potential (mV)')
# plt.subplot(3,1,3)
# plt.plot(time_array, mycell.axon_current_trace)
# plt.ylabel('output current')
# plt.show()
#
