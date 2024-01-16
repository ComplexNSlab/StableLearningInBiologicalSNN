import numpy as np

eta = 0.01
dt = 0.1

beta = 0.1
N = 128
state = 'Rate control'

# Connectivity Matrix
W = 2*np.random.randn(N, N)/np.sqrt(N)

# State Vector
x = np.random.randn(N,1)
x_bar = np.copy(x)
y = np.copy(x)

phi0 =  2*np.random.rand(N, 1)- 1


def derivatives(b: np.ndarray) -> np.ndarray:
    global x, W
    dx = -x + np.matmul(W, phi()) + b
    return dx


def phi():
    global x
    return np.tanh(x)


def learning_rate ():
    return np.matmul(phi(), y.T) - np.matmul(y, phi().T)


def phi_pre():
    global x, x_bar
    return np.tanh(x - x_bar)


def phi_post():
    return phi()


def fluctuation_rate ():
    global state, beta, N, W, x

    kisi = np.random.normal(loc=0, scale=1/N, size=(N, N))
    if state == 'Dissipation':
        return kisi - beta*W
    elif state == 'Rate control':
        return kisi + np.matmul(phi0-phi(), phi().T)*W
    elif state == 'Decorrelation':
        return kisi + np.identity(N) - np.matmul(phi_post(), phi_pre().T)
    else:
        raise Exception("The state of network is invalid!")


