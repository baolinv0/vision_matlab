classdef RPNMiniBatchSummary < handle
    % MiniBatchSummary   Class to hold a mini batch training summary
    
    %   Copyright 2016 The MathWorks, Inc.
    
    properties
        % Epoch (int)   Number of current epoch
        Epoch
        
        % Iteration (int)   Number of current iteration
        Iteration
        
        % Time (double)   Time spent since training started
        Time
        
        % Loss (double)   Current loss
        Loss
        
        % LearnRate (double)   Current learning rate
        LearnRate
    end
    
    properties (Dependent)
        % Predictions   4-D array of network predictions
        Predictions
        
        % Response   4-D array of responses
        Response
        
        % Accuracy (double)   Current accuracy for a classification problem
        Accuracy = [];
        
        % RMSE (double)   Current RMSE for a regression problem
        RMSE = [];
    end
    
    properties (Access = private)
        PrivateAccuracy
        PrivateRMSE
        PrivatePredictions
        PrivateResponse
    end
    
    methods
        function update( this, predictions, response, epoch, iteration, elapsedTime, miniBatchLoss, learnRate )
            % update   Use this function to update all the
            % properties of the class without having to individually fill
            % in each property.
            this.Predictions = predictions;
            this.Response = response;
            this.Epoch = epoch;
            this.Iteration = iteration;
            this.Time = elapsedTime;
            this.Loss = miniBatchLoss;
            this.LearnRate = learnRate;
        end
        
        function accuracy = get.Accuracy( this )
            % get.Accuracy   Get the current accuracy. If the accuracy is
            % empty, recompute it using Predictions and Response.
            if isempty( this.PrivateAccuracy )
                if isempty(this.Predictions) || isempty(this.Response)
                    this.PrivateAccuracy = 0;
                else
                    this.PrivateAccuracy = gather( iAccuracy(this.Predictions, this.Response) );
                end
            end
            accuracy = this.PrivateAccuracy;
        end
        
        function rmse = get.RMSE( this )
            % get.RMSE   Get the current RMSE. If the RMSE is empty,
            % recompute it using Predictions and Response.
            if isempty( this.PrivateRMSE )
                if isempty(this.Predictions) || isempty(this.Response)
                    this.PrivateRMSE = 0;
                else
                    this.PrivateRMSE = gather( iRMSE(this.Predictions, this.Response) );
                end
            end
            rmse = this.PrivateRMSE;
        end        
        
        function predictions = get.Predictions( this )
            predictions = this.PrivatePredictions;
        end
        
        function response = get.Response( this )
            response = this.PrivateResponse;
        end
        
        function set.Accuracy( this, accuracy )
            this.PrivateAccuracy = accuracy;
        end
        
        function set.RMSE( this, rmse)
            this.PrivateRMSE = rmse;
        end
        
        function set.Predictions( this, predictions )
            % set.Predictions   Set predictions and make sure related
            % metrics go out of sync by setting them to empty.
            this.PrivatePredictions = predictions;
            this.Accuracy = [];
            this.RMSE = [];
        end
        
        function set.Response( this, response )
            % set.Response   Set response and make sure related metrics go
            % out of sync by setting them to empty.
            this.PrivateResponse = response;
            this.Accuracy = [];
            this.RMSE = [];
        end
    end
end

function rmse = iRMSE(predictions, response)
squares = (predictions-response).^2;
rmse = sqrt( mean( squares ) );
end

function accuracy = iAccuracy(y, t)
[~, yIntegers] = max(y, [], 3);
[t, tIntegers] = max(t, [], 3);
x = (t.* (yIntegers == tIntegers));
numObservations = nnz(t);
accuracy = gather( 100 * (sum(x(:)) / numObservations) );
end