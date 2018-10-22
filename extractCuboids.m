%from an image in which we have detected edges extract cuboids 
function cuboidsArray = extractCuboids(edgeDetImage, originalData)
%get the size of the input image on which the sobel operator was applied
[rowsNo, columnsNo, framesNo] = size(edgeDetImage);

%set the size of a cuboid, hight, width, depth, no of cuboids to extract
%from each sequence of frames
cuboidHeight = 16;
cuboidWidth = 16;
cuboidDepth = 7;
cuboidsExtracted = 200;

%array of cells that will hold all the cuboids extracted from a video
%sequence
cuboidsArray = cell(framesNo,1);

%loop over all the frames 
for frame = 1:framesNo
    
    %array that will store temporarily the cuboids extracted from this
    %sequence of frames
    cuboids = double(zeros(cuboidHeight*cuboidWidth, cuboidDepth, cuboidsExtracted));
    
    %exctract a set number of cuboids 
    for cuboidIndex = 1:cuboidsExtracted
        
        %variable that will help keep track of the next frame in the
        %sequence from which we have to extract the same area
        currentDepth = frame;
        
        %variable to determine if we have any movement in the frame => we
        %extracted cuboids or not 
        extract = 0;

        %check if the current frame has any elements greater than 0, find the 
        %first 20 coordinates of the nonzero elements and check if they exist 
        %in the current frame => movement was identifed in the frame
        if(isempty(find(edgeDetImage(:,:,currentDepth)>0,20))~=1)
            extract = 1;      
        
            %compute a random area from which to extract the cuboid
            randomRow = randi([1 rowsNo]);
            randomColumn = randi([1 columnsNo]);
            
            %check that there is an edge at the current position, otherwise
            %calculate another random postion until we find an edge
            while(edgeDetImage(randomRow, randomColumn, currentDepth) == 0)
                randomRow = randi([1 rowsNo]);
                randomColumn = randi([1 columnsNo]); 
            end
        
            %we have identified an area that has detected an edge, tha we want
            %to extract from the sequence of consecutive frames
            for depth = 1:cuboidDepth
                            
                %compute an area that is centered at the idetified position and
                %check that the area is inside the maximum sizes of the image
                if(randomRow-7 < 1)
                    cuboidMinRow = 1;
                else
                    cuboidMinRow = randomRow-7;
                end
                if(randomRow+8 > rowsNo)
                    cuboidMaxRow = rowsNo;
                else
                    cuboidMaxRow = randomRow+8;
                end
                if(randomColumn-7 < 1)
                    cuboidMinColumn = 1;
                else
                    cuboidMinColumn = randomColumn-7;
                end
                if(randomColumn+8 > columnsNo)
                    cuboidMaxColumn = columnsNo;
                else
                    cuboidMaxColumn = randomColumn+8;
                end
            
                %compute the size of the area we will extract
                %extractedHeight = cuboidMaxRow-cuboidMinRow+1;
                extractedWidth = cuboidMaxColumn-cuboidMinColumn+1;
            
                indexStart = 1;
                indexEnd = cuboidWidth;
                width = extractedWidth;
            
                for vectorRow = cuboidMinRow:cuboidMaxRow
                    %store the areas extraced from the original image in the 
                    %temporary matrix
                    cuboids(indexStart:width,depth,cuboidIndex) = originalData(vectorRow,cuboidMinColumn:cuboidMaxColumn, currentDepth);
                    left = indexEnd-width;
                    if (left > 0)
                        cuboids(width+1:indexEnd,depth,cuboidIndex) = zeros(left,1, 1);
                    end
                    indexStart = indexEnd+1;
                    width = indexStart+extractedWidth-1;
                    indexEnd = indexEnd+cuboidWidth;
                end
            
                %make sure there are still frames in the original image 
                if(currentDepth <= framesNo-depth)
                    currentDepth = currentDepth + depth;
                end
            end
        end
    end
    %store the extracted cuboids from the sequence into the cell array
    if (extract == 1)
        cuboidsArray{frame} = cuboids;
    else
        cuboidsArray{frame} = zeros(cuboidHeight*cuboidWidth, cuboidDepth, cuboidsExtracted);
    end
end


end