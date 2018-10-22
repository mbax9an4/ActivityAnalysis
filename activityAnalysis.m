%!!!!!!!!!!!!!!!!!!!!!!!!!!!!! to view results
%image(boundingBoxEdgeDet(:,:,frame));!!!!!!!!!!!!!!!!!!!!!!!!
%main function, given a video file name it calls kalmen filter for motion
%detection, sobel operator for edge detection, learns slow feature
%functions
function [ASDfeature] = activityAnalysis(videoName) 

%call kalman filter function to determine the area of the movement
%output is a 3-d matrix: rows, columns, frames
kalman = kalmanFilter(videoName);
[rowsNo, columnsNo, framesNo] = size(kalman);
if framesNo > 300
    kalmanBoundingBox = kalman( :, :,1:300);
    [rowsNo, columnsNo, framesNo] = size(kalmanBoundingBox);
else
    kalmanBoundingBox = kalman;
end
size(kalmanBoundingBox)

boundingBoxEdgeDet = zeros(rowsNo, columnsNo, framesNo);

disp('after kalman filter')

%for each frame in the video
for frame = 1:framesNo
    frameData = kalmanBoundingBox(:,:,frame);
    rowsMean = mean(frameData,2);
    %loop over all the rows in each frame 
    for row = 1:rowsNo
        standardDev = 0.001;
        
        %loop over the columns of the current row to calculate the 
        %standard deviation summation and perform the first step of
        %normalization for the current value
        for column = 1:columnsNo
            kalmanBoundingBox(row,column,frame) = kalmanBoundingBox(row,column,frame) - rowsMean(row);  
            standardDev = standardDev + (kalmanBoundingBox(row,column,frame)*kalmanBoundingBox(row,column,frame));
        end
    
        %compute standard deviation for current row 
        %standardDev = standardDev/columnsNo;
        standardDev = sqrt(standardDev);
        
        %finish normalization for each value in the current row 
        for column = 1:columnsNo
            kalmanBoundingBox(row,column,frame) = kalmanBoundingBox(row,column,frame) / standardDev;
        end
    end
end

%reshape the original frames into a rows*columns vector 
pcaInput = reshape(kalmanBoundingBox, rowsNo*columnsNo, framesNo);

%the 50 most varying frames in the video as selected using PCA
[~,V] = PCA(pcaInput,50);
bestFrames = V(:,1:50);
[dataSize,frameNo] = size(bestFrames);

disp('after pca')

%for each frame remove some of the noise in the frame
for frame = 1:frameNo
    for row = 1:dataSize
        if bestFrames(row, frame) < 0 || bestFrames(row, frame) > 0.012
            bestFrames(row,frame) = 0.0;
        end
    end
end

%after selecting the best frames of the video reexpand the frame matrix 
%to have the shape rows_columns instead of rows*columns
reshapedFrames = zeros(rowsNo, columnsNo, frameNo);
for frame = 1:frameNo
    start = 1;
    limit = rowsNo;
    for column = 1:columnsNo   
        reshapedFrames(:, column, frame) = bestFrames(start:limit, frame);
        start = limit+1;
        limit = start+rowsNo-1;
    end
end

 for frame = 1:frameNo
    %apply the sobel edge detector on the normalized image
    boundingBoxEdgeDet(:,:,frame) = sobel(reshapedFrames(:,:,frame),0.01);
 end

 disp('after sobel')
 
%extract cuboids from the original image using the image on which we have 
%previously detected edges
cuboidsExtracted = extractCuboids(boundingBoxEdgeDet, kalmanBoundingBox);

disp('after extract cuboids')

%get the size of the structure in which we have stored the cuboids
[rows,depth,~] = size(cuboidsExtracted{1});

%set the no of cuboids to expand after applying PCA
cuboidsSelected = 50;

%set the size of the sfa input vector 
%!!!expansion size has to be smaller than cuboid depth!!!
expansionSize = 3;

%temporary matrix that stores an iinput vector 
sfaInput = zeros(expansionSize*rows, depth-2);

%cell array to store the learned slow feature functions 
ASDfeature = zeros(1,expansionSize*rows);


%loop to create an sfa vector and to call the SFA function;
%for each frame in the video, for each cuboid extracted, up to the set no
%create the nonlinear expansion and learn SFF from it
for frame = 1:frameNo
    ASDcuboids = zeros(1,expansionSize*rows);
    for cuboidIndex = 1:cuboidsSelected
        
        %variable to set the depth of the extracted cuboid with regard to
        %the nonlinear expansion vector 
        cuboidDepth = 1;
        
        %depth of the nonlinear expansion vector 
        for depthIndex = 1:depth-2
            
           %index to help store the areas in consecutive depths of the
           %cuboid
           startIndex = 1;
           
           %add each area from consecutive depths up to the set exansion
           %limit into the vector 
           for expansionIndex = 1:expansionSize
               
              %add each area from the original extracted cuboids to the input vector  
              sfaInput(startIndex:expansionIndex*rows, depthIndex) = cuboidsExtracted{frame}(:,cuboidDepth,cuboidIndex);
              
              %compute the starting point of the next area and increment
              %the depth of the next area in the original cuboid
              startIndex = expansionIndex*rows+1;
              cuboidDepth = cuboidDepth+1;
           end
           
           %reset the area of the cuboid so we have an overlap 
           cuboidDepth = cuboidDepth-2;
        end
        
%         if frame == 100 && cuboidIndex == 1
%         all(sfaInput(1:rows,1) == cuboidsExtracted{frame}(:, 1,cuboidIndex))
%         all(sfaInput(rows+1:rows*2,1) == cuboidsExtracted{frame}(:, 2,cuboidIndex))
%         all(sfaInput(rows*2+1:rows*3,1) == cuboidsExtracted{frame}(:, 3,cuboidIndex))
%         all(sfaInput(rows*2+1:rows*3,2) == cuboidsExtracted{frame}(:, 4,cuboidIndex))
%         end
        %   !!!!here call SFA !!!!
        
         slowFunctions = SFA(sfaInput, 2);
         [r,K] = size(slowFunctions);
         [s,d] = size(sfaInput);
         V = zeros(s,1);

         for j = 1:K
             v = zeros(s,1);
             for i = 1:d-1
                 k = 0;
                 while k < s
                     start = k+1;
                    if k + r <=s 
                        k = k+r;
                    else
                        k = s;
                    end
                     if k-start == r-1
                 v(start:k) = v(start:k) + (sfaInput(start:k,i+1).*slowFunctions(:,j) - sfaInput(start:k,i).*slowFunctions(:,j)).^2;
                     else
                 v(start:k) = v(start:k) + (sfaInput(start:k,i+1).*slowFunctions(1:k-start+1,j) - sfaInput(start:k,i).*slowFunctions(1:k-start+1,j)).^2;
                     end       
                 end
             end
             V(:,1) = V(:,1) + double(v./(d-1));
         end
         %V = V./K;
         ASDcuboids = ASDcuboids + V';
    end
    %ASDcuboids = ASDcuboids ./cuboidsSelected;
    ASDfeature = ASDfeature + ASDcuboids;
    frame
end

ASDfeature = ASDfeature/norm(ASDfeature);
%SVMclassifier(ASDfeature);
% cuboidRows = 16;
% cuboidColumns = 16;
% cuboidDepth = 2;
% cuboidIndex = 3;
% pcaOutput = cell(framesNo,1);
% for frame = 1:framesNo
%     cuboid = zeros(cuboidRows*cuboidColumns, cuboidDepth);
%     for index = 1:cuboidIndex
%         for depth = 1:cuboidDepth
%             indexStart = 1;
%             indexEnd = cuboidColumns;
%             for row = 1:cuboidRows
%                 cuboid(indexStart:indexEnd,depth) = cuboidsExtracted{frame}(row,:,depth, index);
%                 indexStart = indexEnd+1;
%                 indexEnd = indexEnd+cuboidColumns;
%             end
%         end
%         pcaOutput{frame}(:,:,index) = PCA(cuboid);
%     end
% end

end