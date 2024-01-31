import numpy as np
from numpy.random import randn
from numpy import sqrt, transpose, zeros, sign

N = 128
dt = 0.1
etaS = 0.01
g = 1.0
tau = 20
tauy = 100
Nmem = 2


TotalSteps = int(3000/dt - 1)
CalcEvery = int(10/dt)
Nsteps = int((TotalSteps + 1)/CalcEvery)

x = randn(N, 1)
x_all = zeros([N, TotalSteps])
xlp = randn()
W_all = zeros([N, N, Nsteps])
hs_all = zeros([N, N, Nsteps])
noise_all = zeros([N, N, Nsteps])
W = 2*randn(N, N)/sqrt(N)
r0 = 2*(randn(N, 1) - 0.5)
zeta = 0.01
y = randn(N, 1)

H = sign(randn(N, N)/sqrt(N))
u = transpose(H[0:Nmem, :])/sqrt(N)
v = transpose(H[Nmem:2*Nmem, :])/sqrt(N)
input1 = zeros([N, TotalSteps])
input2 = zeros([N, TotalSteps])

base = int(500/dt)
inLen = int(100/dt)
input = 0

# Construct input signal for learning
for i in range(Nmem):
    input1[:, base: base + inLen] = np.tile(u[:, i].reshape([N, 1]), [1, inLen])
    input2[:, base: base + inLen] = np.tile(v[:, i].reshape([N, 1]), [1, inLen])

# evolve network
for i in range(TotalSteps):
    print(np.squeeze(x).shape)
    x_all[:, i] = np.squeeze(x)
    r = np.tanh(g*x)
    xlp = ((-xlp + x/0.05)/tau)*dt
    y = y + (r-y)*dt/tauy
    input = input + (-zeta*input + randn()*input1[:, i] + randn()*input2[:, i])

    x = x + (-x + np.matmul(W, r) + 10*input)*dt
    L = np.matmul(r, transpose(y)) - np.matmul(y, transpose(r))
    hs = np.matmul((r0 - r), transpose(r)) * W

    noise = (1*randn(N, N))/sqrt(N)
    W = W + etaS*(noise + hs + L)*dt

    if np.mod(i, CalcEvery) == 0:
        W_all[:, :, int(i/CalcEvery) + 1] = W

