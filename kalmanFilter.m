%function to detect movement in an input video and return the area in which
%the movement happens
function output = kalmanFilter(fileName)

  %read input video and store it into a matrix 
  videoData = VideoReader(fileName);
  numberOfFrames = videoData.NumberOfFrames;
  videoHeight = videoData.Height;
  videoWidth = videoData.Width;
  
  video(1:numberOfFrames) = ...
      struct('cdata', zeros(videoHeight, videoWidth, 3, 'uint16'), ...
             'colormap', []);
  
  %copy all the pixel valuues for the current frame into a position 
  %in the work marix
  for k = 1:numberOfFrames
     video(k).cdata = read(videoData, k);
     video(k).colormap = [];
  end
  
%   maxRows = 0;
%   maxColumns = 0;
  output = zeros(96, 54, numberOfFrames);

  % Calculate the background image by averaging the first 5 images
  backgroundAverage = zeros(size(video(1).cdata));
  [rows,columns] = size(backgroundAverage(:,:,1));
  for frame = 1:5 
     backgroundAverage = double(video(frame).cdata) + backgroundAverage;
  end
  backgroundMean = backgroundAverage/5;

  % Initialization for Kalman Filtering
  windowCenterx = zeros(numberOfFrames,1);
  windowCentery = zeros(numberOfFrames,1);
  %predicted = zeros(numberOfFrames,4);
  actual = zeros(numberOfFrames,4);

  % % Initialize the Kalman filter parameters
  % measureNoise - measurement noise,
  % transform - transform from measure to state
  % systemNoise - system noise,
  % covarinceMatrix - the status covarince matrix
  % transformMatrix - state transform matrix
  
  measureNoise=[[0.2845,0.0045]',[0.0045,0.0455]'];
  transform=[[1,0]',[0,1]',[0,0]',[0,0]'];
  systemNoise=0.01*eye(4);
  covarianceMatrix = 100*eye(4);
  determinant=1;
  transformMatrix=[[1,0,0,0]',[0,1,0,0]',[determinant,0,1,0]',[0,determinant,0,1]'];

  % loop over all image frames in the video
  initial = 0;
  
  %treshold to distinguish between noise and relevant data 
  treashold = 59;
  
  %main loop to process movement detection 
  for frame=1:numberOfFrames
%     imshow(video(frame).cdata);
%     hold on
    currentFrame = double(video(frame).cdata);
  
    % Calculate the difference image to extract pixels with more than 25(threshold) 
    %change
    %differenceFrame = zeros(rows,columns); 
    differenceFrame = (abs(currentFrame(:,:,1)-backgroundMean(:,:,1))>treashold) ...
        | (abs(currentFrame(:,:,2)-backgroundMean(:,:,2))>treashold) ...
        | (abs(currentFrame(:,:,3)-backgroundMean(:,:,3))>treashold);

    % Label the image and mark
    labeledFrame = logical(differenceFrame);
    markedFrame = regionprops(labeledFrame,'basic');
    [rowsMarked,~] = size(markedFrame);

    % Do bubble sort (large to small) on regions in case there are more than 1
    % The largest region is the object (1st one)
    for index = 1:rowsMarked
       if markedFrame(index).Area > markedFrame(1).Area
           temp = markedFrame(1);
           markedFrame(1)= markedFrame(index);
           markedFrame(index)= temp;
       end
    end

   % Get the upper-left corner, the measurement centroid and bounding window size
   bestBoundingBox = markedFrame(1).BoundingBox;
   boundingCornerx = bestBoundingBox(1);
   boundingCornery = bestBoundingBox(2);
   boundingWidthx = bestBoundingBox(3);
   boundingWidthy = bestBoundingBox(4);
   centroid = markedFrame(1).Centroid;
   windowCenterx(frame)= centroid(1);
   windowCentery(frame)= centroid(2);

   % Plot the rectangle of background subtraction algorithm -- blue
%    hold on
%    rectangle('Position',[boundingCornerx boundingCornery boundingWidthx boundingWidthy],'EdgeColor','b');
%    hold on
%    plot(windowCenterx(frame),windowCentery(frame), 'bx');

   % Kalman window size
   kalmanSizex = windowCenterx(frame)- boundingCornerx;
   kalmanSizey = windowCentery(frame)- boundingCornery;

   %check if we have a prvious prediction or if it is the first one
   if initial == 0
       % Initialize the predicted centroid and velocity
       predicted =[windowCenterx(frame),windowCentery(frame),0,0]' ;
   else
       % Use the former state to predict the new centroid and velocity
       predicted = transformMatrix*actual(frame-1,:)';
   end
   initial = 1;

   priorPredError = transformMatrix*covarianceMatrix*transformMatrix' + systemNoise;
   Kalman = priorPredError*transform'/(transform*priorPredError*transform'+measureNoise);
   actual(frame,:) = (predicted + Kalman*([windowCenterx(frame),windowCentery(frame)]' - transform*predicted))';
   covarianceMatrix = (eye(4)-Kalman*transform)*priorPredError;

   startRow =  int16(actual(frame,2)-kalmanSizey);
   if(startRow < 1)
       startRow = 1;
   end
   startColumn = int16(actual(frame,1)-kalmanSizex);
   if(startColumn < 1)
       startColumn = 1;
   end
   endRow = int16(startRow + boundingWidthy);
   if(endRow > rows)
       endRow = rows;
   end
   endColumn = int16(startColumn + boundingWidthx);
   if(endColumn > columns)
       endColumn = columns;
   end
   
   rowsNo = endRow-startRow+1;
   columnsNo = endColumn-startColumn+1;
   
%    if(maxRows < rowsNo)
%        maxRows = rowsNo;
%    end
%    
%    if(maxColumns < columnsNo)
%        maxColumns = columnsNo;
%    end
   
   currentFrame = video(frame).cdata;   
   output(1:rowsNo,1:columnsNo,frame) = currentFrame(startRow:endRow, startColumn:endColumn,1);
   
%    imshow(video(frame).cdata);
%    %Plot the tracking rectangle after Kalman filtering -- red
%    hold on
%    rectangle('Position',[(actual(frame,1)-kalmanSizex) (actual(frame,2)-kalmanSizey) boundingWidthx boundingWidthy],'EdgeColor','r','LineWidth',1.5);
%    hold on
%    plot(actual(frame,1),actual(frame,2), 'rx','LineWidth',1.5);
%    drawnow;
  end
end