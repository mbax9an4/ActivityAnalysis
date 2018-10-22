function [S, V] = PCA(data,n)

[~, frames] = size(data);

% PCA2: Perform PCA using SVD
% data - MxN matrix of input data
% (dimensions, trials)
% PC - each column is a PC
% V - Mx1 matrix of variances

% subtract off the mean for each dimension
rowMean = mean(data,2);
data = data - repmat(rowMean,1,frames);

% construct the matrix Y ./ = right division
Y = data' ./ sqrt(frames);

Y(isnan(Y))=0;

% apply singular value decomposition
[~,S,V] = svds(Y,n);

% calculate the variances
% S = diag(S);
% eigenvalues = S .* S;

end

