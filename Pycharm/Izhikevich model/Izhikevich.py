import numpy as np


class IzhikevichNetwork:
    # synaptic plasticity rate
    alpha = 0.05
    tau = 10000

    def __init__(self, n):
        """
        Parameters
        ----------
        n: number of neurons
        ni : number of inhibitory neurons
        ne : number of excitatory neurons

        W : weight matrix (synaptic connections)

        cells : a list of all cells in the network
        totalTime : total time simulated in the network in mS
        """

        # initializing n, ne, ni
        self.n = n
        ne, ni = int(0.8 * n), int(0.2 * n)
        self.ne = ne
        self.ni = ni

        # initializing average activities parameters
        self.A_goal = np.array([1]*ne + [2]*ni).reshape([ne + ni, 1])
        self.A = np.zeros([ne + ni, 1])

        # initializing W
        self.W = np.zeros((ne + ni, ne + ni))
        self.W[:, :ne] = 0.5 * np.random.rand(ne + ni, ne)
        self.W[:, ne:ne + ni] = -1 * np.random.rand(ne + ni, ni)
        np.fill_diagonal(self.W, 0)

        # creation of cells and totalTime
        self.cells = []
        self.w_save = []
        self.totalTime = 0

        # creation of cells and addition to the cells attribute
        for i in range(ne):
            self.cells.append(IzhikevichSpikingNeuron(inhibitory=True))
        for i in range(ni):
            self.cells.append(IzhikevichSpikingNeuron(inhibitory=False))

    def simulate(self, T, plasticity = True):
        """
        simulation of network for a given time in mS
        Parameters
        ----------
        T : time period for simulation (mS)
        plasticity : whether plasticity rule is active or not on W synaptic matrix

        """

        # updating
        self.totalTime += T

        # for loop for time integration
        dt = IzhikevichSpikingNeuron.dt
        for i in range(int(T / dt)):
            print(str(int(100 * i * dt / T)) + ' %')

            # thalamic input as a noise to each cell
            thalamic_input = np.concatenate((5 * np.random.randn(self.ne), 2 * np.random.randn(self.ni)))/np.sqrt(IzhikevichSpikingNeuron.dt)

            fired = np.array([cell.axon_current for cell in self.cells]).T
            synaptic_input = np.matmul(self.W, fired)

            for cell_index, cell in enumerate(self.cells):
                cell.update(thalamic_input[cell_index] + synaptic_input[cell_index])

            if plasticity:
                self._update_synapses()
                self._update_A()
                self.w_save.append(self.W)

    def _update_synapses(self):
        self.W = self.W + self.alpha * np.multiply(np.matmul(self.A, (self.A_goal - self.A).T), self.W)

    def _update_A(self):
        self.A += (np.array([cell.v for cell in self.cells]).reshape(self.n, 1) - self.A) * IzhikevichSpikingNeuron.dt / self.tau

    @property
    def get_spike_raster(self):
        spike_raster = []
        for cell in self.cells:
            spike_raster.append(cell.spike_timings)

        return spike_raster

    @property
    def get_potential_traces(self):
        trace = np.zeros([self.ne + self.ni, int(self.cells[0].t / IzhikevichSpikingNeuron.dt)])
        for cell_index, cell in enumerate(self.cells):
            trace[cell_index, :] = cell.potential_trace

        return trace

    @property
    def get_axon_current_traces(self):
        trace = np.zeros([self.ne + self.ni, int(self.cells[0].t / IzhikevichSpikingNeuron.dt)])
        for cell_index, cell in enumerate(self.cells):
            trace[cell_index, :] = cell.axon_current_trace

        return trace


class IzhikevichSpikingNeuron:
    """
        Bifurcation methodologies enable us to reduce many biophysical accurate Hodgkin–Huxley-type neuronal
        models to a two-dimensional (2-D) system of ordinary differential equations of the form :

        dv/dt = 0.04v^2 + 5v + 140 - u + I
        du/dt = a(bv-u)

        if v >= 30 mv:
            v -> c
            u -> u + d

        The parameter a describes the timescale of the recovery variable u. Smaller values result in slower recovery. A
        typical value is a = 0.02.

        The parameter b describes the sensitivity of the recovery variable u to the sub threshold fluctuations of the
        membrane potential v. Greater values couple v and u more strongly resulting in possible sub threshold
        oscillations and low-threshold spiking dynamics. A typical value is b = 0.2. The case b < a(b > a) corresponds
        to saddle-node (Andronov–Hopf) bifurcation of the resting state

        The parameter c describes the after-spike reset value of the membrane potential v caused by the fast
        high-threshold K+ conductance. A typical value is c = -65 mV

        The parameter d describes after spike reset of the recovery variable u caused by slow high-threshold Na+ and K+
        conductance. A typical value is d = 2
    """

    threshold = 30  # mV
    dt = 0.5  # mS
    spike_current_amplitude = 0.20
    axon_decay = 5  # mS

    def __init__(self, inhibitory: 'inhibitory cell' = True):
        """

        Parameters
        ----------
        inhibitory : whether the cell is inhibitory or excitatory (True/False)
        v : membrane potential
        u : recovery variable

        spike_timing : spike timing of membrane potential (a list of spike times)
        trace : trace of membrane potential in time
        t : time passed since the beginning of simulation


        """

        # setting Izhikevich parameters
        if inhibitory:
            r = np.random.rand()
            self._a, self._b = 0.02, 0.2
            self._c, self._d = -65 + 15 * r ** 2, 8 - 6 * r ** 2
        else:
            r = np.random.rand()
            self._a, self._b = 0.02 + 0.08 * r, 0.25 - 0.05 * r
            self._c, self._d = -65, 2

        # initializing v and u
        self.v = -65
        self.u = self._b * self.v

        # data of the cell to be recorded
        self._spike_timings = []
        self._potential_trace = []
        self._axon_trace = []

        # instantaneous time, axon current and fired status
        self.t = 0
        self.axon_current = 0
        self.fired = 0

    def update(self, I):
        """
            update the neuron by one time step (dt)
            Parameters
            ----------
            I : input current (A)

            Returns
            -------

        """

        # getting instantaneous derivatives
        dv, du = self._derivatives(I)

        # updating the neuron
        self.v += dv * self.dt
        self.u += du * self.dt
        self.axon_current -= self.axon_current * self.dt / self.axon_decay

        self.t += self.dt

        # recording important data
        self._potential_trace.append(self.v)
        self._axon_trace.append(self.axon_current)

        # checking whether the neuron spiked or not
        if self.v >= self.threshold:
            # recording spike timing history
            self._spike_timings.append(self.t)

            # updating variables after spike
            self.v = self._c
            self.u = self.u + self._d
            self.axon_current += self.spike_current_amplitude
            self.fired = 1
        else:
            self.fired = 0

    def _derivatives(self, I):
        # calculation of derivatives
        dv = (0.04 * self.v ** 2 + 5 * self.v + 140 - self.u + I)
        du = self._a * (self._b * self.v - self.u)

        return dv, du

    @property
    def parameters(self):
        """
        Returns the parameters of the cell a, b, c, d
        Returns
        -------
        [a, b, c, d]
        """
        return [self._a, self._b, self._c, self._d]

    @property
    def axon_current_trace(self):
        return self._axon_trace

    @property
    def potential_trace(self):
        return self._potential_trace

    @property
    def spike_timings(self):
        return self._spike_timings
