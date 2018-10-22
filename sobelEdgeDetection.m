%function to detect edges in an input image using a given treshold value
%returns a black and white image in which edges were detected
function edgeDetectionImage = sobelEdgeDetection(originalImage, threshold) 

%check that the size of the original image is greater than 0(all) and less
%than the set boundary and throw exception otherwise(assert)
assert(all(size(originalImage) <= [1024 1024]));

%check that all the elements of the input image and treshold are
%doubles(isa) and throw exception otherwise
assert(isa(originalImage, 'double'));
assert(isa(threshold, 'double'));

%kernel function used by sobel
kernel = [1 2 1; 0 0 0; -1 -2 -1];

%convolution of the original image matrix and the kernel function, using
%the 'same' identifier to produce an output that has the same size as the
%original image matrix
gradientApproxX = conv2(double(originalImage),kernel, 'same');
gradientApproxY = conv2(double(originalImage),kernel','same');

%create a gradient matrix that combines the two directions 
gradientMatrix = sqrt(gradientApproxX.*gradientApproxX + gradientApproxY.*gradientApproxY);

%convert the resulting image so it is in the greyscale limits
edgeDetectionImage = uint8((gradientMatrix > threshold) * 254);
end