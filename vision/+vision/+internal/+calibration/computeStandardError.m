function standardError = computeStandardError(jacobian, residual, useQR)
% computeStandardError compute the standard error of estimated parameters
% standardError = computeStandardError returns a vector containing the
% standard errors of estimated parameters. jacobian is the sparse Jacobian
% matrix, and residual is a vector of residuals. When useQR is true, QR
% decomposition is used to compute the covariance matrix, which is faster
% but potentially less accurate.

if nargin < 3
    useQR = true;
end

if useQR
    R = qr(jacobian,0);
    n = size(jacobian,1)-size(jacobian,2);
    % be careful with memory
    clear jacobian;
    mse = sum(sum(residual.^2, 2)) / n;
    Rinv = inv(R);
    Sigma = Rinv*Rinv'*mse;
    standardError = full(sqrt(diag(Sigma)));
else
    jacobian = full(jacobian);
    n = size(jacobian,1)-size(jacobian,2);
    mse = sum(sum(residual.^2, 2)) / n;
    Sigma = pinv(jacobian'*jacobian) * mse;
    standardError = full(sqrt(diag(Sigma)));
end