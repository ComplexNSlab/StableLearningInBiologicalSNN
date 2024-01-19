import numpy as np


class SmwusNetwork:
    # time step
    dt = 0.1

    def __init__(self, state: str, n: int = 128):
        """
            Class of Stable-Memory-With-Unstable-Synapses
            :param
            state (str): Initial homeostasis state of the network
            n (int): Number of neurons in the network
         """

        if state not in ['Dissipation', 'Rate control', 'Decorrelation']:
            raise Exception("The state of network is invalid!")
        self.homeostasis_state = state

        self.N = n

        # Connectivity Matrix
        self.W = 2 * np.random.randn(n, n) / np.sqrt(n)

        # State Vector
        self.x = np.random.randn(n, 1)

        # low pass filters
        self.y = np.copy(self.x)
        self.x_bar = np.copy(self.x)

        # desired rate for 'Rate control' state
        self.phi0 = 2 * np.random.rand(n, 1) - 1

        self.kisi = np.random.normal(loc=0, scale=1 / np.sqrt(self.N), size=(self.N, self.N))

        self.time = 0

        self._phi = self.phi
        self._phi_pre = self.phi_pre
        self._phi_post = self.phi_post
        self._learning_rate = self.learning_rate
        self._fluctuation_rate = self.fluctuation_rate

        keys = list(self.__dict__.keys())
        keys.remove('N')
        keys.remove('phi0')
        self._record = {key: [] for key in keys}

    @property
    def phi(self):
        self._phi = np.tanh(self.x)
        return self._phi

    @property
    def phi_pre(self):
        self._phi_pre = np.tanh(self.x)
        return self._phi_pre

    @property
    def phi_post(self):
        self._phi_post = np.tanh(self.x - self.x_bar)
        return self._phi_post

    @property
    def learning_rate(self):
        self._learning_rate = np.matmul(self.phi, self.y.T) - np.matmul(self.y, self.phi.T)
        return self._learning_rate

    @property
    def fluctuation_rate(self):
        beta = 0.1
        self._fluctuation_rate = None

        if self.homeostasis_state == 'Dissipation':
            self._fluctuation_rate = self.kisi - beta * self.W
        elif self.homeostasis_state == 'Rate control':
            self._fluctuation_rate = self.kisi + np.matmul(self.phi0 - self.phi, self.phi.T) * self.W
        elif self.homeostasis_state == 'Decorrelation':
            self._fluctuation_rate = self.kisi + 0.5*np.identity(self.N) - np.matmul(self.phi_post, self.phi_pre.T)
        else:
            raise Exception("The state of network has been changed and is invalid!")

        return self._fluctuation_rate

    def _update_network(self, b: np.ndarray = None):
        eta = 0.01

        # time scales for lowpass filter signals (x_bar and y)
        tau = 50
        tau_x = 20

        if b is None:
            b = np.zeros([self.N, 1])

        dx = -self.x + np.matmul(self.W, self.phi) + b
        dw = eta * (self.fluctuation_rate + self.learning_rate)
        dy = (self.x - self.y) / tau
        dx_bar = (self.x - self.x_bar) / tau_x

        self.x = self.x + dx * SmwusNetwork.dt
        self.W = self.W + dw * SmwusNetwork.dt
        self.y = self.y + dy * SmwusNetwork.dt
        self.x_bar = self.x_bar + dx_bar * SmwusNetwork.dt
        self.kisi = np.random.normal(loc=0, scale=1 / np.sqrt(self.N), size=(self.N, self.N))
        self.time += SmwusNetwork.dt

    def _save_sample(self):
        keys = list(self.__dict__.keys())
        keys.remove('N')
        keys.remove('_record')
        keys.remove('phi0')
        for key in keys:
            self._record[key].append(self.__getattribute__(key))

    def run(self, t: float, sampling_rate: int = 100):
        """
        :param t: time
        :param sampling_rate:
        Parameters
        ----------
        t
        sampling_rate

        Returns
        -------

        """
        counter = 0
        for step in range(int(t/SmwusNetwork.dt)):
            self._update_network()
            counter += 1
            if counter >= 1/sampling_rate/SmwusNetwork.dt:
                counter = 0
                self._save_sample()

    def get_record(self, name):
        return np.array(self._record[name])
