function sim = ComputePearsonSimilarity(A,B,minShared,blockRows,showWaitbar)
% Pair-wise Pearson correlation with NaN handling and per-pair centring.
%
%   sim(i,j) = corr( A(i,:), B(j,:) )   over the dimensions where both rows
%                                        have finite values.
%
%   Undefined pairs (too few shared samples or zero variance) return NaN.

    if nargin<3 || isempty(minShared), minShared = 50;   end
    if nargin<4 || isempty(blockRows), blockRows = 4000; end
    if nargin<5 || isempty(showWaitbar), showWaitbar = true; end

    [nA,D] = size(A);          nB = size(B,1);

    % ---------- preprocess B once --------------------------------------
    Bmask = ~isnan(B);                     % nB × D   logical
    Bz    = B;   Bz(~Bmask) = 0;           % zeros where NaN
    Bj2   = Bz.^2;                         % nB × D   squared terms

    sim   = NaN(nA,nB,'single');
    if showWaitbar
        wb = waitbar(0,'Computing Pearson blocks …');
    end

    for i1 = 1:blockRows:nA
        i2    = min(i1+blockRows-1,nA);
        idx   = i1:i2;
        m     = numel(idx);

        % ---------- current A block ------------------------------------
        Amask = ~isnan(A(idx,:));          % m × D
        Az    = A(idx,:);   Az(~Amask) = 0;
        Ai2   = Az.^2;                     % m × D

        % ---------- shared-dimension counts ----------------------------
        nShared = Amask * Bmask.';         % m × nB

        % ---------- Σ a , Σ b , Σ a² , Σ b² , Σ ab ---------------------
        sumA   = Az   * Bmask.';                 % m × nB
        sumB   = (Bz  * Amask.').';              % m × nB
        sumA2  = Ai2  * Bmask.';                 % m × nB
        sumB2  = (Bj2 * Amask.').';              % m × nB
        sumAB  = Az * Bz.';                      % m × nB

        % ---------- centre them: covariance & variances ----------------
        covAB  = sumAB - (sumA .* sumB) ./ nShared;
        varA   = sumA2 - (sumA.^2)      ./ nShared;
        varB   = sumB2 - (sumB.^2)      ./ nShared;
        denom  = sqrt(varA .* varB);

        % ---------- validity mask --------------------------------------
        valid = (nShared >= minShared) & (denom > 0);

        rho              = NaN(size(sumAB),'single');
        rho(valid)       = covAB(valid) ./ denom(valid);
        sim(idx,:)       = rho;

        if showWaitbar, waitbar(i2/nA,wb); end
    end
    if showWaitbar, close(wb); end
end


% function sim = ComputePearsonSimilarity(A,B,minShared,blockRows)
% 
%     if nargin<3 || isempty(minShared), minShared = 50;   end
%     if nargin<4 || isempty(blockRows), blockRows = 4000; end
% 
%     [nA,D] = size(A);                nB = size(B,1);
% 
%     % ---- preprocess B once -----------------------------------------
%     Bz    = B;           Bz(isnan(Bz)) = 0;
%     Bmask = ~isnan(B);                 % nB×D
%     Bj2   = Bz.^2;                     % nB×D  (for later)
% 
%     sim  = NaN(nA,nB,'single');
%     wb   = waitbar(0,'Computing Pearson blocks …');
% 
%     for i1 = 1:blockRows:nA
%         i2   = min(i1+blockRows-1,nA);     idx = i1:i2;
%         Az   = A(idx,:);   Az(isnan(Az)) = 0;
%         Amask= ~isnan(A(idx,:));           % m×D
%         Ai2  = Az.^2;                      % m×D
%         overlap = Amask * Bmask.';         % m×nB  (# shared dims)
% 
%         % numerator
%         num = Az * Bz.';                   % m×nB
% 
%         % denominator (pair-specific norms)
%         sumAi2 = Ai2 * Bmask.';            % m×nB
%         sumBj2 = (Bj2 * Amask.').';        % m×nB
%         denom  = sqrt(sumAi2 .* sumBj2);   % m×nB
% 
%         % mask of valid pairs
%         valid = (overlap >= minShared) & (denom > 0);
% 
%         rho         = NaN(size(num),'single');
%         rho(valid)  = num(valid) ./ denom(valid);
%         sim(idx,:)  = rho;                 % similarity (not distance)
% 
%         waitbar(i2/nA,wb);
%     end
%     close(wb);
% end
