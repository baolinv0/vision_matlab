classdef cascadeClassifierBuildable < coder.ExternalDependency %#codegen
    %CASCADECLASSIFIERBUILDABLE - encapsulate cascadeClassifier implementation library
    
    % Copyright 2013 The MathWorks, Inc.    
    
    methods (Static)
        
        function name = getDescriptiveName(~)
            name = 'vision.CascadeObjectDetector';
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
            buildInfo.addSourceFiles({'CascadeClassifierCore.cpp', ...
                'mwcascadedetect.cpp', ...  
                'mwhaar.cpp', ...
                'cgCommon.cpp'});

            buildInfo.addIncludeFiles({'vision_defines.h', ...
                                       'CascadeClassifierCore_api.hpp', ...
                                       'cgCommon.hpp', ...                                       
                                       'mwobjdetect.hpp', ...
                                       'mwcascadedetect.hpp', ...
                                       'precomp_objdetect.hpp'}); % no need 'rtwtypes.h'           
                                 
            vision.internal.buildable.portableOpenCVBuildInfo(buildInfo, context, ...
                'cascadeClassifier');            
        end

        %------------------------------------------------------------------
        % write all supported data-type specific function calls       
        function ptrObj = cascadeClassifier_construct()
            
            coder.inline('always');
            coder.cinclude('CascadeClassifierCore_api.hpp');

            ptrObj = coder.opaque('void *', 'NULL');
    
            % call function from shared library
            coder.ceval('cascadeClassifier_construct', coder.ref(ptrObj));
        end    
        
        %------------------------------------------------------------------
        % write all supported data-type specific function calls       
        function cascadeClassifier_load(ptrObj, ClassificationModel)
            coder.inline('always');
            coder.cinclude('CascadeClassifierCore_api.hpp'); 
            
            % call function from shared library
            coder.ceval('cascadeClassifier_load', ptrObj, coder.ref(ClassificationModel));
        end 
        
        %------------------------------------------------------------------
        % write all supported data-type specific function calls       
        function [originalWindowSize, featureTypeID] = cascadeClassifier_getClassifierInfo(ptrObj)
            coder.inline('always');
            coder.cinclude('CascadeClassifierCore_api.hpp'); 
            
            originalWindowSize = zeros(1,2,'uint32');
            featureTypeID = uint32(0);
            
            % call function from shared library
            coder.ceval('cascadeClassifier_getClassifierInfo', ptrObj, ...
                coder.ref(originalWindowSize), coder.ref(featureTypeID));
        end 
        
        %------------------------------------------------------------------
        % write all supported data-type specific function calls       
        function bboxes = cascadeClassifier_detectMultiScale(ptrObj, I, ScaleFactor, ...
                MergeThreshold, MinSize, MaxSize)
            
            coder.inline('always');
            coder.cinclude('CascadeClassifierCore_api.hpp'); 
            
            coder.varsize('bboxes_', [inf, 4]);
            if isempty(I)
                % no-op
                bboxes = zeros(0,4);
            else
                % call function
                nRows = int32(size(I, 1));
                nCols = int32(size(I, 2));
                ScaleFactor_ = double(ScaleFactor);
                MergeThreshold_ = uint32(MergeThreshold);
                MinSize_ = int32(MinSize);
                MaxSize_ = int32(MaxSize);
                
                ptrDetectedObj = coder.opaque('void *', 'NULL');
                
                num_bboxes = int32(0);
                
                 if coder.isColumnMajor
                    num_bboxes(:) = coder.ceval('-col','cascadeClassifier_detectMultiScale', ...
                        ptrObj, coder.ref(ptrDetectedObj), ...
                        I', nRows, nCols, ScaleFactor_, ...
                        MergeThreshold_, coder.ref(MinSize_), coder.ref(MaxSize_));
                else
                    num_bboxes(:) = coder.ceval('-row','cascadeClassifier_detectMultiScale', ...
                        ptrObj, coder.ref(ptrDetectedObj), ...
                        I, nRows, nCols, ScaleFactor_, ...
                        MergeThreshold_, coder.ref(MinSize_), coder.ref(MaxSize_));
                 end                
                
                coder.varsize('bboxes_', [inf, 4]);
                bboxes_ = coder.nullcopy(zeros(double(num_bboxes),4,'int32'));
                
                % call function from shared library
                if coder.isColumnMajor
                  coder.ceval('-col','cascadeClassifier_assignOutputDeleteBbox', ...
                    ptrDetectedObj, coder.ref(bboxes_));   
                else
                  coder.ceval('-row','cascadeClassifier_assignOutputDeleteBboxRM', ...
                    ptrDetectedObj, coder.ref(bboxes_));                      
                end
                
                bboxes = double(bboxes_);   
            end
            
        end 

        %------------------------------------------------------------------
        % write all supported data-type specific function calls       
        function cascadeClassifier_deleteObj(ptrObj)
            
            coder.inline('always');
            coder.cinclude('CascadeClassifierCore_api.hpp'); 
    
            % call function from shared library
            coder.ceval('cascadeClassifier_deleteObj', ptrObj);
        end         
        
    end   
end
