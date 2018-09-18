classdef ValidationUtils 
    
    methods(Static)              
        
        %------------------------------------------------------------------
        function checkMinSize(minSize, modelSize, fname)

            vision.internal.detector.ValidationUtils.checkSize(minSize, 'MinSize', fname);

            % validate that MinSize is greater than or equal to the minimum
            % object size used to train the classification model
            coder.internal.errorIf(any(minSize < modelSize) , ...
                'vision:ObjectDetector:minSizeLTTrainingSize', ...
                modelSize(1),modelSize(2));
        end
        
        %------------------------------------------------------------------
        function checkMaxSize(maxSize, modelSize, fname)

            vision.internal.detector.ValidationUtils.checkSize(maxSize, 'MaxSize', fname);

            % validate the MaxSize is greater than the model size when
            % MinSize is not specified
            coder.internal.errorIf(any(modelSize >= maxSize) , ...
                'vision:ObjectDetector:modelMinSizeGTMaxSize', ...
                modelSize(1),modelSize(2));
        end

        %------------------------------------------------------------------
        function checkSize(sz, name, fname)
            validateattributes(sz,{'numeric'},...
                {'nonempty','nonsparse','real','finite','integer','positive','size',[1,2]},...
                fname,name);
        end
        
        %------------------------------------------------------------------
        % Issue warning if sz < min size or sz < model size.
        %------------------------------------------------------------------
        function checkImageSizes(sz, userInput, wasMinSizeSpecified, modelSize, minSizeID, modelID)
            if wasMinSizeSpecified
                if any(sz < userInput.MinSize)
                    warning(message(minSizeID, ...
                        mat2str(sz),...
                        mat2str(userInput.MinSize)));
                end
            else
                if any(sz < modelSize)
                    warning(message(modelID, ...
                        mat2str(sz),...
                        mat2str(modelSize)));
                end
            end
        end               
        
    end
end