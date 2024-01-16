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

    def update_network(self, b: np.ndarray = None):
        dt = 0.1
        eta = 0.01
        beta = 0.1

        # time scales for lowpass filter signals (x_bar and y)
        tau = 50
        tau_x = 20

        if b is None:
            b = np.zeros([self.N, 1])

        def phi():
            return np.tanh(self.x)

        def phi_pre():
            return np.tanh(self.x - self.x_bar)

        def phi_post():
            return phi()

        def learning_rate():
            return np.matmul(phi(), self.y.T) - np.matmul(self.y, phi().T)

        def fluctuation_rate():
            kisi = np.random.normal(loc=0, scale=1 / self.N, size=(self.N, self.N))
            if self.homeostasis_state == 'Dissipation':
                return kisi - beta * self.W
            elif self.homeostasis_state == 'Rate control':
                return kisi + np.matmul(self.phi0 - phi(), phi().T) * self.W
            elif self.homeostasis_state == 'Decorrelation':
                return kisi + np.identity(self.N) - np.matmul(phi_post(), phi_pre().T)
            else:
                raise Exception("The state of network has been changed and is invalid!")

        dx = -self.x + np.matmul(self.W, phi()) + b
        dw = eta * (fluctuation_rate() + learning_rate())
        dy = (self.x - self.y) / tau
        dx_bar = (self.x - self.x_bar) / tau_x

        self.x = self.x + dx * dt
        self.W = self.W + dw * dt
        self.y = self.y + dy * dt
        self.x_bar = self.x_bar + dx_bar * dt
