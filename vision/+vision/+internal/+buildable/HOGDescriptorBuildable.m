classdef HOGDescriptorBuildable < coder.ExternalDependency  %#codegen
    %HOGDescriptorBUILDABLE - used by vision.PeopleDetector 
    
    % Copyright 2013 The MathWorks, Inc.    
    
    methods (Static)
        
        function name = getDescriptiveName(~)
            name = 'HOGDescriptorBuildable';
        end
        
        function b = isSupportedContext(~)
            b = true; % supports non-host target
        end
        
        function updateBuildInfo(buildInfo, context)
  
            buildInfo.addIncludePaths({fullfile(matlabroot,'toolbox', ...
                'vision','builtins','src','ocv','include'), ...
                fullfile(matlabroot,'toolbox', ...
                'vision','builtins','src','ocvcg', 'opencv', 'include')} );

            buildInfo.addSourcePaths({fullfile(matlabroot,'toolbox', ...
                'vision','builtins','src','ocv')});
            buildInfo.addSourceFiles({'HOGDescriptorCore.cpp', ...
                'mwhog.cpp', ...
                'mwhaar.cpp', ...
                'mwcascadedetect.cpp', ...  
                'cgCommon.cpp'});

            buildInfo.addIncludeFiles({'vision_defines.h', ...
                                       'HOGDescriptorCore_api.hpp', ...
                                       'cgCommon.hpp', ...                                       
                                       'mwobjdetect.hpp', ...
                                       'mwcascadedetect.hpp', ...
                                       'precomp_objdetect.hpp'}); % no need 'rtwtypes.h'           
                                 
            vision.internal.buildable.portableOpenCVBuildInfo(buildInfo, context, ...
                'HOGDescriptor');             
        end

        %------------------------------------------------------------------
        % write all supported data-type specific function calls       
        function ptrObj = HOGDescriptor_construct()
            
            coder.inline('always');
            coder.cinclude('HOGDescriptorCore_api.hpp');
            
            ptrObj = coder.opaque('void *', 'NULL');
    
            % call function from shared library
            coder.ceval('HOGDescriptor_construct', coder.ref(ptrObj));
        end    
        
        %------------------------------------------------------------------
        % write all supported data-type specific function calls       
        function HOGDescriptor_setup(ptrObj, whichModel)
            coder.inline('always');
            coder.cinclude('HOGDescriptorCore_api.hpp');
            
            % call function from shared library
            coder.ceval('HOGDescriptor_setup', ptrObj, int32(whichModel));
        end 
        
        %------------------------------------------------------------------
        % write all supported data-type specific function calls       
        function [bbox, scores] = HOGDescriptor_detectMultiScale(ptrObj, I, ScaleFactor, ...
                ClassificationThreshold, ...
                postMergeThreshold, ...
                MinSize, MaxSize, WindowStride, ...
                MergeDetections)
                        
            coder.inline('always');
            coder.cinclude('HOGDescriptorCore_api.hpp');
            
             % call function
            nRows = int32(size(I, 1));
            nCols = int32(size(I, 2));
            isRGB = (size(I, 3) == 3);
            ScaleFactor_ = cCast1('double', ScaleFactor);
            ClassificationThreshold_ = cCast1('double', ClassificationThreshold);
            postMergeThreshold_ = cCast1('double', postMergeThreshold);
            MinSize_ = cCast2('int32_T', MinSize);
            MaxSize_ = cCast2('int32_T', MaxSize);
            WindowStride_ = cCast2('int32_T', WindowStride);
            MergeDetections_ = (MergeDetections==true);% output always logical
            
            ptrDetectedObj     = coder.opaque('void *', 'NULL');
            ptrDetectionScores = coder.opaque('void *', 'NULL');
            
            numDetectedObj = int32(0);
            numDetectionScores = int32(0);
         
%             algoFcnName = 'HOGDescriptor_detectMultiScale';
%             outputFcnName = 'HOGDescriptor_assignOutputDeleteVectors';
%                 algoFcnName = [algoFcnName 'RM'];
%                 outputFcnName = [outputFcnName 'RM'];
                
            %{
            if ~coder.internal.const(coder.isColumnMajor)
                algoFcnName = [algoFcnName 'RM'];
                outputFcnName = [outputFcnName 'RM'];
            end
            %}
%{
                switch coder.isColumnMajor
                    case true
                        algoFcnName = 'HOGDescriptor_detectMultiScale';
                        outputFcnName = 'HOGDescriptor_assignOutputDeleteVectors';
                    case false
                        algoFcnName = 'HOGDescriptor_detectMultiScaleRM';
                        outputFcnName = 'HOGDescriptor_assignOutputDeleteVectorsRM';
                end
                %}
if coder.isColumnMajor
            coder.ceval('-col', 'HOGDescriptor_detectMultiScale', ...
                ptrObj, coder.ref(ptrDetectedObj), coder.ref(ptrDetectionScores), ...
                I, nRows, nCols, isRGB, ...
                ScaleFactor_, ...
                ClassificationThreshold_, ...
                postMergeThreshold_, ...
                coder.ref(MinSize_), coder.ref(MaxSize_), coder.ref(WindowStride_), ...
                MergeDetections_, ...
                coder.ref(numDetectedObj), coder.ref(numDetectionScores));
else
            coder.ceval('-row','HOGDescriptor_detectMultiScaleRM', ...
                ptrObj, coder.ref(ptrDetectedObj), coder.ref(ptrDetectionScores), ...
                I, nRows, nCols, isRGB, ...
                ScaleFactor_, ...
                ClassificationThreshold_, ...
                postMergeThreshold_, ...
                coder.ref(MinSize_), coder.ref(MaxSize_), coder.ref(WindowStride_), ...
                MergeDetections_, ...
                coder.ref(numDetectedObj), coder.ref(numDetectionScores));    
end
            
            coder.varsize('bboxes_', [inf, 4]);
            bbox_ = coder.nullcopy(zeros(double(numDetectedObj),4,'int32'));
            coder.varsize('scores_', [inf, 1]);
            scores_ = coder.nullcopy(zeros(double(numDetectionScores),1,'double'));
            
            % call function from shared library
            if coder.isColumnMajor
            coder.ceval('-col', 'HOGDescriptor_assignOutputDeleteVectors', ...
                ptrDetectedObj, ptrDetectionScores, ...
                coder.ref(bbox_), coder.ref(scores_));
            else
            coder.ceval('-row', 'HOGDescriptor_assignOutputDeleteVectorsRM', ...
                ptrDetectedObj, ptrDetectionScores, ...
                coder.ref(bbox_), coder.ref(scores_));                
            end
            bbox   = double(bbox_);
            scores = double(scores_);
        end 

        %------------------------------------------------------------------
        % write all supported data-type specific function calls       
        function HOGDescriptor_deleteObj(ptrObj)
            
            coder.inline('always');
            coder.cinclude('HOGDescriptorCore_api.hpp');
    
            % call function from shared library
            coder.ceval('HOGDescriptor_deleteObj', ptrObj);
        end         
        
    end   
end

function outVal = cCast2(outClass, inVal)
    outVal = coder.nullcopy(zeros(size(inVal), outClass));
    outVal(1) = cCast1(outClass, inVal(1));
    outVal(2) = cCast1(outClass, inVal(2));
end

function outVal = cCast1(outClass, inVal)
    outVal = coder.nullcopy(zeros(1,1,outClass));
    outVal = coder.ceval(['('   outClass  ')'], inVal);
end
