dt_array = 10.^(-5:0.1:-1);
alpha_array = -3:0.01:3;

error_matrix = zeros(length(dt_array), length(alpha_array));

for i = 1:length(dt_array)
    for j = 1:length(alpha_array) 
        error_matrix(i, j) = func(dt_array(i), alpha_array(j));
    end
end

surf(log10(dt_array), alpha_array, log10(error_matrix)')
xlabel('log10(dt)')
ylabel('alpha')
zlabel('log10(error)')
colorbar


function error = func(dt, alpha)
    T = 10;
    n_t = T/dt;
    

    x = 1;

    for i = 1:n_t
        x = x + alpha*x*dt;
    end
    
    error = abs(exp(+alpha*T) - x);
end