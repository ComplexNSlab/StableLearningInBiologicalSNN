import numpy as np


class SmwusNetwork:
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

        self.kisi = np.random.normal(loc=0, scale=1 / self.N, size=(self.N, self.N))

    @property
    def phi(self):
        return np.tanh(self.x)

    @property
    def phi_pre(self):
        return np.tanh(self.x - self.x_bar)

    @property
    def phi_post(self):
        return self.phi

    @property
    def learning_rate(self):
        return np.matmul(self.phi, self.y.T) - np.matmul(self.y, self.phi.T)

    @property
    def fluctuation_rate(self):
        beta = 0.1

        if self.homeostasis_state == 'Dissipation':
            return self.kisi - beta * self.W
        elif self.homeostasis_state == 'Rate control':
            return self.kisi + np.matmul(self.phi0 - self.phi, self.phi.T) * self.W
        elif self.homeostasis_state == 'Decorrelation':
            return self.kisi + np.identity(self.N) - np.matmul(self.phi_post, self.phi_pre.T)
        else:
            raise Exception("The state of network has been changed and is invalid!")

    def update_network(self, b: np.ndarray = None):
        dt = 0.1
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

        self.x = self.x + dx * dt
        self.W = self.W + dw * dt
        self.y = self.y + dy * dt
        self.x_bar = self.x_bar + dx_bar * dt
        self.kisi = np.random.normal(loc=0, scale=1 / self.N, size=(self.N, self.N))