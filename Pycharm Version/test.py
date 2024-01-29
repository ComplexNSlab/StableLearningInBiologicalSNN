import matplotlib.pyplot as plt

from Izhikevich_Spiking_Neuron import IzhikevichNetwork

network = IzhikevichNetwork(n=1000)
network.simulate(T=1000)


plt.eventplot(network.get_spike_raster(), colors='k')
plt.xlabel('time (mS)')
plt.ylabel('cell index')
plt.hlines(xmin=0, xmax=network.totalTime, y=800, colors='k', linewidth = 0.5)
plt.title('Izhikevich model spike raster')
plt.show()

