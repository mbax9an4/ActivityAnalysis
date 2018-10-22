function [] = SVMclassifier(testFeature)
dataFiles = dir('C:\Users\geo\Desktop\third year project\data\*.mat');
dataSize = length(dataFiles);
labels = zeros(dataSize,1);
for d = 1:dataSize
    data(d) = load(dataFiles(d).name);
    if isempty(strfind(dataFiles(d).name, 'walking')) == 0
        labels(d,1) = 1;
    else if isempty(strfind(dataFiles(d).name, 'running')) == 0
            labels(d,1) = 2;
        else if isempty(strfind(dataFiles(d).name, 'handclapping')) == 0
                labels(d,1) = 3;
            end
        end
    end
end

[~,col] = size(data(1).ans);
noTrainData = uint8(3*dataSize/4);
train  = double(zeros(noTrainData,col));
test = double(zeros(dataSize-noTrainData, col));

trainLabels = double(zeros(noTrainData,1));
testLabels = double(zeros(dataSize-noTrainData,1));
models_liniar = cell(7,1);
models_kernel = cell(7,1);
%acc_liniar = zeros(7,1);
%acc_kernel = zeros(7,1);
for iter = 1:7
    indices = crossvalind('Kfold', dataSize, dataSize);

    for d = 1:dataSize
        if d <= noTrainData
            train(d,:) = data(indices(d)).ans;
            trainLabels(d,1) = labels(indices(d));
        else 
            i = d-noTrainData;
            test(i,:) = data(indices(d)).ans;
            testLabels(i,1) = labels(indices(d),1);
        end
    end
%     testLabels
    %train several times on the training data, store all the models
    %obtained and after training and test on the model that gives the best
    %accuracy
    
    models_liniar{iter} = svmtrain(trainLabels, train, '-c 1 -g 0.01 -q -t 0');
    %[~, acc, ~] = svmpredict(testLabels, test, models_liniar{iter}, '-b 1');
    %acc_liniar(iter,1) = acc(1);
    models_kernel{iter} = svmtrain(trainLabels, [double((1:noTrainData))', train*train'], '-t 1');
    %[~, acc, ~] = svmpredict(testLabels, [double((1:dataSize-noTrainData))', test*train'], models_kernel{iter}); 
    %acc_kernel(iter,1) = acc(1);
    
    
    %disp('liniar accuracy');
    %acc_liniar(iter,1)
    %disp('kernel accuracy');
    %acc_kernel(iter,1)
end

%test label is unknown so we use a random value 
label = rand(1,1);

vote_liniar = zeros(3,1);
vote_kernel = zeros(3,1);

for i = 1:7
[pred_label_liniar, ~, ~] = svmpredict(label, testFeature, models_liniar{i});
[pred_label_kernel, ~, ~] = svmpredict(label, [double((1))', testFeature*train'], models_kernel{i}); 

vote_liniar(pred_label_liniar,1) = vote_liniar(pred_label_liniar,1) + 1;
vote_kernel(pred_label_kernel,1) = vote_kernel(pred_label_kernel,1) + 1;
end
vote_liniar
vote_kernel
[~,index_liniar] = max(vote_liniar);
[~, index_kernel] = max(vote_kernel);

if index_liniar == 1
    disp('The activity recognized is walking.');
else if index_liniar == 2
        disp('The activity recognized is running');
    else if index_liniar == 3
            disp('The activity recognized is handclapping');
        else
            disp('The activity could not be recognized');
        end
    end
end

if index_kernel == 1
    disp('The activity - recognized is walking.');
else if index_kernel == 2
        disp('The activity - recognized is running');
    else if index_kernel == 3
            disp('The activity - recognized is handclapping');
        else
            disp('The activity - could not be recognized');
        end
    end
end
        
    
end