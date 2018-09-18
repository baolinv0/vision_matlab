classdef ComputeMetricBuildable < coder.ExternalDependency %#codegen
    % ComputeMetricBuildable - encapsulate ComputeMetric implementation library
    %   This function is used by cvalgMatchFeatures function
    
    % Copyright 2012 The MathWorks, Inc.
    
    
    methods (Static)
        
        function name = getDescriptiveName(~)
            name = 'ComputeMetricBuildable';
        end
        
        function b = isSupportedContext(context)
            b = context.isMatlabHostTarget();
        end
        
        function updateBuildInfo(buildInfo, context)
            vision.internal.buildable.cvstBuildInfo(buildInfo, context, ...
                'ComputeMetric', ...
                {'use_tbb', ...
                 'use_tbbmalloc'}); %#ok<EMCA>
        end

        %------------------------------------------------------------------
        % write all supported data-type specific function calls      
        function scores = ComputeMetric_core(features1,features2, method, N1, N2, output_class)        
            
            coder.inline('always');
            coder.cinclude('cvstCG_ComputeMetric.h');                       
            
            numFeatures1   = uint32(size(features1, 1));
            numFeatures2   = uint32(size(features2, 1)); 
            featureLength  = uint32(size(features1, 2)); 
            % output_class is 'double' or 'single'
            fcnName = ['ComputeMetric_' lower(method) '_' output_class];
            
            if coder.isColumnMajor
                scores = zeros(N1, N2, output_class);
                
                coder.ceval('-col',fcnName,...
                    features1', ...
                    features2', ...
                    coder.ref(scores), ...
                    numFeatures1, ...
                    numFeatures2, ...
                    featureLength);
            else
                tempScores = zeros(N2, N1, output_class);
                
                coder.ceval('-row', fcnName,...
                    coder.ref(features1), ...
                    coder.ref(features2), ...
                    coder.ref(tempScores), ...
                    numFeatures1, ...
                    numFeatures2, ...
                    featureLength);
                
                scores = tempScores';
            end
        end       
    end   
end
