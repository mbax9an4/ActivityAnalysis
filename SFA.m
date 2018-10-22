function [slowFunctions] = SFA(inputVector, count)
[~, depth] = size(inputVector);

% temp = inputVector';
% for i = 1:depth
%     temp(~isnan(temp))=0;
%     temp(~isfinite(temp))=0;
% end
% inputVector = temp';
% if frame == 1
%     disp('size of vector and count')
%     size(inputVector)
%     count
% end
%apply pca to find the eigenvalues for the input vector
[S,~] = PCA1(inputVector);

% normalize input function
rowMean = mean(inputVector,2);
inputVector = inputVector - repmat(rowMean,1,depth);

%apply the spherical normalization method to the input vector
spheredVector = S*inputVector;
z = spheredVector*spheredVector';

%apply pca to find the slowest varying functions for this input vector
[~,V] = PCA1(z);
[~,d] = size(V);
%select and store the slow functions
slowFunctions = V(:,d-depth+1:d);

%train the functions by running the process again with the input parameters
%being the slow functions we just learned
while count > 0
    count = count-1;
    slowFunctions = SFA(slowFunctions, count);
end


% expansionRowsNo = rowsNo + rowsNo*(rowsNo+1)/2
% nonlinearExpVector = zeros(expansionRowsNo,depth);

% for t = 1:depth
%     nonlinearExpVector(1:rowsNo, t) = inputVector(:,t);
% end
% 
% index = rowsNo+1;
% for t = 1:depth
%     for term1 = 1:rowsNo
%         for term2 = term1:rowsNo
%             nonlinearExpVector(index,t) = inputVector(term1,t)*inputVector(term2,t);
%             index = index+1;
%         end     
%     end
% end




end