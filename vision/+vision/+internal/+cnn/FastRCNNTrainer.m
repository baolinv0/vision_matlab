classdef FastRCNNTrainer < handle
    % Trainer   Class for training a network
    
    %   Copyright 2015-2017 The MathWorks, Inc.
    
    properties(Access = protected)
        Options
        Schedule
        Precision
        Reporter
        ExecutionStrategy
        StopTrainingFlag
        InterruptException
    end
    
    methods
        function this = FastRCNNTrainer(opts, precision, reporter, executionSettings)
            % Trainer    Constructor for a network trainer
            %
            % opts - training options (nnet.cnn.TrainingOptionsSGDM)
            % precision - data precision
            this.Options = opts;
            scheduleArguments = iGetArgumentsForScheduleCreation(opts.LearnRateScheduleSettings);
            this.Schedule = nnet.internal.cnn.LearnRateScheduleFactory.create(scheduleArguments{:});
            this.Precision = precision;
            this.Reporter = reporter;
            % Declare execution strategy
            if ismember( executionSettings.executionEnvironment, {'gpu'} )
                this.ExecutionStrategy = vision.internal.cnn.RCNNTrainerGPUStrategy;
            else
                this.ExecutionStrategy = vision.internal.cnn.RCNNTrainerHostStrategy;
            end
            
            % Print execution environment if in verbose mode
            iPrintExecutionEnvironment(opts, executionSettings);
            
            % Register a listener to detect requests to terminate training
            addlistener( reporter, ...
                'TrainingInterruptEvent', @this.stopTrainingCallback);
        end
        
        function net = train(this, net, data)
            % train   Train a network
            %
            % Inputs
            %    net -- network to train
            %    data -- data encapsulated in a data dispatcher
            % Outputs
            %    net -- trained network
            reporter = this.Reporter;
            schedule = this.Schedule;
            prms = collectSettings(this, net);
            summary = iSummary(net);
            
            trainingTimer = tic;
            
            reporter.start();
            iteration = 0;
            this.StopTrainingFlag = false;
            [velocity, learnRate] = initializeLearning(this, net);
            
            needsStatefulTraining = iNeedsStatefulTraining(data, net);
            for epoch = 1:prms.maxEpochs
                this.shuffle( data, prms.shuffleOption, epoch );
                data.start();
                while ~data.IsDone && ~this.StopTrainingFlag
                    [X, response] = data.next();
                    % Cast data to appropriate execution environment for
                    % training and apply transforms
                    X{1} = this.ExecutionStrategy.environment(X{1});
                    X{1} = apply(prms.transforms, X{1});
                    
                    propagateState = iNeedsToPropagateState(data);
                    [gradients, predictions, ~] = this.computeGradients(net, X, response, needsStatefulTraining, propagateState);
                    
                    % Reuse the layers outputs to compute loss
                    miniBatchLoss = net.loss( predictions, response );
                    
                    % cls
                    velocity{1} = calculateVelocity( this, ...
                        prms.momentum, velocity{1}, ...
                        prms.l2Regularization, net.LearnableParameters, ...
                        learnRate, gradients{1});
                             
                    % reg
                    velocity{2} = calculateVelocity( this, ...
                        prms.momentum, velocity{2}, ...
                        prms.l2Regularization, net.RegLearnableParameters, ...
                        learnRate, gradients{2});
                    
                    net = net.updateLearnableParameters(velocity);
                    
                    %net = net.updateNetworkState(states, needsStatefulTraining);
                    
                    elapsedTime = toc(trainingTimer);
                    
                    iteration = iteration + 1;
                    response = iResponse(net, response);
                    summary.update(predictions, response, epoch, iteration, elapsedTime, miniBatchLoss, learnRate );
                    % It is important that computeIteration is called
                    % before reportIteration, so that the summary is
                    % correctly updated before being reported
                    reporter.computeIteration( summary, net );
                    reporter.reportIteration( summary );
                end
                learnRate = schedule.update(learnRate, epoch);
                
                reporter.reportEpoch( epoch, iteration, net );
                
                % If an interrupt request has been made, break out of the
                % epoch loop
                if this.StopTrainingFlag
                    break;
                end
            end
            reporter.finish();
        end               
        
        function net = finalizeNetwork(this, net, data)
            % Perform any finalization steps required by the layers
            
            % Call shared implementation
            net = this.doFinalize(net, data);
        end
    end

    methods(Access = protected)
        function stopTrainingCallback(this, ~, ~)
            % stopTraining  Callback triggered by interrupt events that
            % want to request training to stop
            this.StopTrainingFlag = true;
        end

        function settings = collectSettings(this, net)
            % collectSettings  Collect together fixed settings from the
            % Trainer and the data and put in the correct form.
            settings.maxEpochs = this.Options.MaxEpochs;
            settings.lossFunctionType = iGetLossFunctionType(net);
            settings.shuffleOption = this.Options.Shuffle;
            
            settings.momentum = this.Precision.cast( this.Options.Momentum );
            settings.l2Regularization = this.Precision.cast( this.Options.L2Regularization );
            
            settings.transforms = [iGetAugmentations(net) iGetNormalization(net)];
        end

        function [velocity, learnRate] = initializeLearning(this, net)
            % initializeLearning  Set the learning parameters to their
            % starting values.
            velocity = iInitializeVelocity(net, this.Precision);
            learnRate = this.Precision.cast( this.Options.InitialLearnRate );
        end

        function [gradients, predictions, states] = computeGradients(~, net, X, Y, needsStatefulTraining, propagateState)
            % computeGradients   Compute the gradients of the network. This
            % function returns also the network output so that we will not
            % need to perform the forward propagation step again.
            [gradients, predictions, states] = net.computeGradientsForTraining(X, Y, needsStatefulTraining, propagateState);
        end

        function newVelocity = calculateVelocity(~, momentum, oldVelocity, globalL2Regularization, learnableParametersArray, globalLearnRate, gradients)
            numLearnableParameters = numel(learnableParametersArray);
            newVelocity = cell(numLearnableParameters, 1);
            for i = 1:numLearnableParameters
                param = learnableParametersArray(i);
                newVelocity{i} = iVelocity(momentum,oldVelocity{i}, ...
                    globalL2Regularization, globalLearnRate, gradients{i}, ...
                    param.L2Factor, param.LearnRateFactor, param.Value);
            end
        end

        function net = doFinalize(this, net, data)
            % Perform any finalization steps required by the layers
            needsFinalize = cellfun(@(x) isa(x,'nnet.internal.cnn.layer.Finalizable'), net.Layers);
            if any(needsFinalize)
                prms = collectSettings(this, net);
                % Do one final epoch
                data.start();
                while ~data.IsDone
                    d = data.next();
                  
                    % Cast data to appropriate execution environment for
                    % training and apply transforms
                    d{1} = this.ExecutionStrategy.environment(d{1});
                    d{1} = apply(prms.transforms, d{1});
                    % Ask the network to finalize
                    net = finalizeNetwork(net, d);
                end
                
            end
        end
    end
    
    methods(Access = protected)
        function shuffle(~, data, shuffleOption, epoch)
            % shuffle   Shuffle the data as per training options
            if ~isequal(shuffleOption, 'never') && ...
                    ( epoch == 1 || isequal(shuffleOption, 'every-epoch') )
                data.shuffle();
            end
        end
    end
end

function response = iResponse(net, Y)
if isa(net,'vision.internal.cnn.internalFastRCNNSeriesNetwork')
    response = Y{1};
else
    response = Y{1}{1};
end
end

function summary = iSummary(net)
if isa(net,'vision.internal.cnn.internalFastRCNNSeriesNetwork')
    summary = nnet.internal.cnn.util.MiniBatchSummary;
else
    summary = vision.internal.cnn.RPNMiniBatchSummary;
end
end

function tf = iNeedsToPropagateState(data)
tf = isa(data,'nnet.internal.cnn.SequenceClassificationDispatcher') && data.IsNextMiniBatchSameObs;
end

function tf = iNeedsStatefulTraining(data,net)
needsUpdate = cellfun(@(x) isa(x,'nnet.internal.cnn.layer.Updatable'), net.Layers);
haveSequenceDispatcher = isa(data,'nnet.internal.cnn.SequenceClassificationDispatcher');
tf = needsUpdate & haveSequenceDispatcher;
end

function t = iGetLossFunctionType(net)
if isempty(net.Layers)
    t = 'nnet.internal.cnn.layer.NullLayer';
else
    t = class(net.Layers{end});
end
end

function n = iGetNormalization(net)
if isempty(net.Layers)
    n = nnet.internal.cnn.layer.ImageTransform.empty;
elseif isa(net.Layers{1},'nnet.internal.cnn.layer.SequenceInput')
    n = nnet.internal.cnn.layer.ImageTransform.empty;
else
    n = net.Layers{1}.Transforms;
end
end

function a = iGetAugmentations(net)
if isempty(net.Layers)
    a = nnet.internal.cnn.layer.ImageTransform.empty;
elseif isa(net.Layers{1},'nnet.internal.cnn.layer.SequenceInput')
    a = nnet.internal.cnn.layer.ImageTransform.empty;
else
    a = net.Layers{1}.TrainTransforms;
end
end

function scheduleArguments = iGetArgumentsForScheduleCreation(learnRateScheduleSettings)
scheduleArguments = struct2cell(learnRateScheduleSettings);
end

function velocity = iInitializeVelocity(net, precision)
velocity{1} = num2cell( precision.zeros([numel(net.LearnableParameters) 1]) );
velocity{2} = num2cell( precision.zeros([numel(net.RegLearnableParameters) 1]) );
end

function vNew = iVelocity(m,vOld,gL2,gLR,grad,lL2,lLR,W)
% [1]   A. Krizhevsky, I. Sutskever, and G. E. Hinton, "ImageNet
%       Classification with Deep Convolutional Neural Networks", in
%       Advances in Neural Information Processing Systems 25, 2012.

% m = momentum
% gL2 = globalL2Regularization
% gLR = globalLearnRate
% g = gradients, i.e., deriv of loss wrt weights
% lL2 = l2Factors, i.e., learn rate for a particular factor
% lLR = learnRateFactors
% W = learnableParameters

% learn rate for this parameters
alpha = gLR*lLR;
% L2 regularization for this parameters
lambda = gL2*lL2;

% Velocity formula as per [1]
vNew = m*vOld - lambda.*alpha.*W - alpha.*grad;
end

function iPrintMessage(messageID, varargin)
string = getString(message(messageID, varargin{:}));
fprintf( '%s\n', string );
end

function iPrintExecutionEnvironment(opts, executionSettings)
% Print execution environment if in 'auto' mode
if opts.Verbose
    if ismember(opts.ExecutionEnvironment, {'auto'})
        if ismember(executionSettings.executionEnvironment, {'cpu'})
            iPrintMessage( ...
                'nnet_cnn:internal:cnn:Trainer:TrainingInSerialOnCPU');
        elseif ismember(executionSettings.executionEnvironment, {'gpu'})
            iPrintMessage( ...
                'nnet_cnn:internal:cnn:Trainer:TrainingInSerialOnGPU');
        end
    elseif ismember(opts.ExecutionEnvironment, {'parallel'})
        if ismember(executionSettings.executionEnvironment, {'cpu'})
            iPrintMessage( ...
                'nnet_cnn:internal:cnn:Trainer:TrainingInParallelOnCPUs');
        elseif ismember(executionSettings.executionEnvironment, {'gpu'})
            iPrintMessage( ...
                'nnet_cnn:internal:cnn:Trainer:TrainingInParallelOnGPUs');
        end
    end
end
end
