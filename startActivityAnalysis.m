function [] = startActivityAnalysis(name)

% Action recording values
framenumber = 300;
frequency = 1;
foldername = 'frames';
enable_preview = true;
 
% Create folder
if exist(foldername, 'dir') ~= 7
    mkdir(foldername);
end
 
% Video preferences
vid = videoinput('winvideo', 1, 'MJPG_176x144');
vid.FramesPerTrigger = framenumber;
set(vid, 'ReturnedColorSpace', 'RGB') ;
set(vid,'FrameGrabInterval', frequency);
% set(vid, 'TriggerRepeat', Inf);
% vid.FrameGrabInterval = 5;


% Preview
if enable_preview == true
    preview(vid);
end

% Get frames
start(vid);

%wait until the user closes input
wait(vid,Inf);

%get the current frame from webcam
frames = getdata(vid,vid.FramesPerTrigger, 'uint8');


flushdata(vid);
%get the current colormap 
map = colormap;
% [~,~,~,framenumber] = size(frames);
%create the movie that will store the frames from webcam
movie(1:framenumber) = struct('cdata',[], 'colormap',[]);

for k = 1 : framenumber
    movie(k).cdata = frames(:,:,:,k);
    movie(k).colormap = map;
end  
outputName = strcat('frames\',name,'.avi');

movie2avi(movie, outputName, 'compression','None', 'fps',10);
winopen(outputName);

delete(vid);
clear vid;
%activityAnalysis(name);
end
 