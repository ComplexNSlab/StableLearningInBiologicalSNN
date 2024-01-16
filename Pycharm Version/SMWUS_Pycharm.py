import numpy as np

dt = 0.1
eta = 0.01
beta = 0.1
N = 128
state = 'Decorrelation'

# time scales for lowpass filter signals (x_bar and y)
tau = 50
tau_x = 20

# Connectivity Matrix of the network
W = 2*np.random.randn(N, N)/np.sqrt(N)

# State Vector of the network
x = np.random.randn(N,  1)

# low pass filters
x_bar = np.copy(x)
y = np.copy(x)

phi0 = 2*np.random.rand(N, 1) - 1


def update_network(b: np.ndarray = 0):
    global x, W, eta, dt, tau, y, tau_x, x_bar

    def phi():
        global x
        return np.tanh(x)

    def phi_pre():
        global x, x_bar
        return np.tanh(x - x_bar)

    def phi_post():
        return phi()

    def learning_rate():
        global y
        return np.matmul(phi(), y.T) - np.matmul(y, phi().T)

    def fluctuation_rate():
        global state, beta, N, W, x

        kisi = np.random.normal(loc=0, scale=1 / N, size=(N, N))
        if state == 'Dissipation':
            return kisi - beta * W
        elif state == 'Rate control':
            return kisi + np.matmul(phi0 - phi(), phi().T) * W
        elif state == 'Decorrelation':
            return kisi + np.identity(N) - np.matmul(phi_post(), phi_pre().T)
        else:
            raise Exception("The state of network is invalid!")

    dx = -x + np.matmul(W, phi()) + b
    dw = eta*(fluctuation_rate() + learning_rate())
    dy = (x-y)/tau
    dx_bar = (x-x_bar)/tau_x

    x = x + dx*dt
    W = W + dw*dt
    y = y + dy*dt
    x_bar = x_bar + dx_bar*dt


save_w = []
time = np.arange(2000)*dt
for i in range(len(time)):
    update_network(b=np.zeros([N, 1]))
    save_w.append(W)

import matplotlib.pyplot as plt
save_w = np.array(save_w)
for i in range(2):
    for j in range(2):
        plt.plot(time, save_w[:, i, j], label=str(i+1) + ',' + str(j+1))
plt.title(state)
plt.xlabel("time")
plt.ylabel("W_ij")
plt.legend()
plt.show()