# # ''' A Learning Rule for the Emergence of Stable Dynamics and Timingin Recurrent Networks '''
# #
# # import numpy as np
# # import matplotlib.pyplot as plt
# #
# # def average_activity(S):
# #     global tau, dt
# #
# #     N_neurons, time_steps = S.shape
# #     A = np.zeros([N_neurons, time_steps])
# #     for step in range(time_steps - 1):
# #         A[:, step+1] = A[:, step] + (S[:, step] - A[:, step])*dt/tau
# #     return A
# #
# #
# # '''
# #     A_i measures the average activity of neuron i
# #     S_i(t) represents the presence (1) or absence (0) of a spike at time
# #         dA_i(t) =  S_i(t) - A_i(t)
# #
# #     The synaptic scaling learning rule is generally represented as (vanRossum et al. 2000):
# #         dW_pre,post =  alpha * (A_goal - A_post(t)). W_pre,post
# #
# #     A_goal was set at 1 and 2 for the Ex and Inh units
# # '''
# #
# # tau = 1  # the timescale for A equation in (s)
# # alpha = 0.05  # the rate of change of W
# # N = 5  # number of neurons
# # p = 0.05  # probability of spiking
# #
# # dt = 0.1
# # T = 10
# # n_t = int(T/dt)
# # time_array = np.arange(n_t)*dt
# #
# #
# #
# #
# # S = np.random.choice([0, 1], size=[N, n_t], p=[1-p, p])  # sparse
# #
# # neuron_indices, spike_times = np.where(S == 1)
# # spike_train = [[] for i in range(N)]
# # for iterator, neuron_index in enumerate(neuron_indices):
# #     spike_train[neuron_index].append(spike_times[iterator]*dt)
# #
# # plt.eventplot(spike_train, linelengths=0.5)
# # # plt.show()
# # for neuron in range(N):
# #     plt.plot(time_array, average_activity(S).T[:, neuron] + neuron)
# #
# # plt.grid()
# # plt.show()
# #
#
# from neuron import h, rxd
# from neuron.units import ms, mV, µm
#
# class BallAndStick:
#     def __init__(self, gid):
#         self._gid = gid
#         self.soma = h.Section(name="soma", cell=self)
#         self.dend = h.Section(name="dend", cell=self)
#         self.dend.connect(self.soma)
#         self.soma.L = self.soma.diam = 12.6157 * µm
#         self.dend.L = 200 * µm
#         self.dend.diam = 1 * µm
#
#     def __repr__(self):
#         return "BallAndStick[{}]".format(self._gid)
#
#
# my_cell = BallAndStick(0)
#
# h.topology()
#
# # enable NEURON's graphics
# from neuron import gui
#
# # here: True means show using NEURON's GUI; False means do not do so, at least not at first
# ps = h.PlotShape(True)
# ps = h.PlotShape(True)
# ps.show(0)

from neuron import h, gui

from neuron.units import ms, mV

h.load_file("stdrun.hoc")
