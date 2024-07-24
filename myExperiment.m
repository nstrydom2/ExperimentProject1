function results = myExperiment(params,monitor)
    if monitor.Stop
        return;
    end

    % Unpack parameters from the struct
    hiddenUnitsFirstLayer = params.cells;
    hiddenUnitsSecondLayer = params.cells;
    learnRate = params.learnRate;
    drop = params.dropFactor;
    maxEpochs = 40;%params.maxEpochs;
    miniBatchSize = params.batchSize;
    %vp = params.validationPersistence;
    %hi = params.hi; % hyperparameters

    %% Set up training monitor

    % Specify info and metric columns
    %monitor.Info = ["learnRate", "cells", "cycles", "dropFactor", 
    %    "batchSize", "seqNumber", "learnRate", "cells"];
    monitor.Metrics = ["TrainingLoss", "ValidationAccuracy"];
    
    % Set x-axis label for training plot
    monitor.XLabel = "Iteration";
    
    % Group metrics in the same subplot (optional)
    groupSubPlot(monitor, "Loss", ["TrainingLoss", "ValidationAccuracy"]);
    
    % Set y-axis scale (optional)
    %yscale(monitor, "Loss", "log");
    
    % Load and preprocess data
    mypath = "D:\capr4.xls";
    [trainData, trainLabels, valData, valLabels, pdata] = loadData(mypath, 1, 1, 582, 4, 2, 0.00004); % Implement this function based on your data
    
    % Define the network architecture
    layers = [
        sequenceInputLayer(4)
        lstmLayer(hiddenUnitsFirstLayer,'OutputMode','sequence')
        dropoutLayer(drop)
        lstmLayer(hiddenUnitsSecondLayer,'OutputMode','sequence')
        dropoutLayer(drop)
        fullyConnectedLayer(2)
        softmaxLayer
        classificationLayer];
    
    % Specify training options
    options = trainingOptions('adam',...
        'MaxEpochs',maxEpochs,...
        'MiniBatchSize',miniBatchSize,...
        'L2Regularization',0.000001,...
        'Shuffle','never',...
        'ExecutionEnvironment','gpu',...
        'LearnRateDropFactor',0.1,...
        'LearnRateDropPeriod',7,...
        'SquaredGradientDecayFactor',0.999,...
        'InitialLearnRate',learnRate,...
        'LearnRateSchedule','piecewise',...
        'ValidationData',{valData,valLabels},...
        'ValidationPatience',3,...
        'ValidationFrequency',1,...
        'OutputNetwork','best-validation-loss',...
        'SequenceLength',60,...
        'Verbose',false);
    
    % Train the network
    [net, info] = trainNetwork(trainData, trainLabels, layers, options);

    % Access training loss
    trainingLoss = info.TrainingLoss;
    if ~isscalar(trainingLoss)
        trainingLoss = mean(trainingLoss); % or another appropriate aggregation
    end

    
    % Access validation accuracy (for classification)
    if isfield(info, 'ValidationAccuracy')
        validationAccuracy = info.ValidationAccuracy;
        if ~isscalar(validationAccuracy)
            validationAccuracy = mean(validationAccuracy); % or another appropriate aggregation
        end
    else
        % For regression, you might use RMSE or loss
        validationRMSE = info.ValidationRMSE;
        validationLoss = info.ValidationLoss;
    end

    recordMetrics(monitor, 1, ...
    TrainingLoss=trainingLoss, ...
    ValidationAccuracy=validationAccuracy);
    
    % Evaluate the network
    %accuracy = evaluateNetwork(net, valData, valLabels); % Implement this function based on your evaluation criteria
    
    % Return the results
    results.Accuracy = validationAccuracy;

    monitor.Status = "Training complete";

end

