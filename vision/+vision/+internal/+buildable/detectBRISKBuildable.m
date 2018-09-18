classdef detectBRISKBuildable < coder.ExternalDependency %#codegen
   
    % Copyright 2012-2016 The MathWorks, Inc.
        
    methods (Static)
        
        function name = getDescriptiveName(~)
            name = 'detectBRISKFeatures';
        end
        
        function b = isSupportedContext(~)
            b = true; % supports non-host target
        end
        
        function updateBuildInfo(buildInfo, context)
           
            %{
            buildInfo.addIncludePaths({fullfile(matlabroot,'toolbox', ...
                'vision','builtins','src','ocv','include')} );
            %}
            buildInfo.addIncludePaths({fullfile(matlabroot,'toolbox', ...
                'vision','builtins','src','ocv','include'), ...
                fullfile(matlabroot,'toolbox', ...
                'vision','builtins','src','ocvcg', 'opencv', 'include')} );

            buildInfo.addSourcePaths({fullfile(matlabroot,'toolbox', ...
                'vision','builtins','src','ocv')});
            buildInfo.addSourceFiles({'detectBRISKCore.cpp', ...
                'agast_score_mw.cpp', ...
                'cgCommon.cpp', ...
                'mwbrisk.cpp'});

            buildInfo.addIncludeFiles({'vision_defines.h', ...
                                       'detectBRISKCore_api.hpp', ...
                                       'cgCommon.hpp', ...                                       
                                       'agast_score_mw.hpp', ...
                                       'features2d_other_mw.hpp', ...
                                       'precomp_f2d_mw.hpp'});
                                 
            vision.internal.buildable.portableOpenCVBuildInfo(buildInfo, context, ...
                'detectBRISK');
        end
        
        %------------------------------------------------------------------
        % write all supported data-type specific function calls        
        function points = detectBRISK(Iu8, threshold, numOctaves)
            
            coder.inline('always');
            coder.cinclude('detectBRISKCore_api.hpp');

            ptrKeypoints = coder.opaque('void *', 'NULL');
    
            % call function
            numOut = int32(0);
            
            nRows = int32(size(Iu8,1));
            nCols = int32(size(Iu8,2));

            %> Detect BRISK Features
            if coder.isColumnMajor
                numOut(1) = coder.ceval('-col', 'detectBRISK_detect',...
                    coder.ref(Iu8), ...
                    nRows, nCols,...
                    threshold, numOctaves,...
                    coder.ref(ptrKeypoints));  
            else
                numOut(1) = coder.ceval('-row', 'detectBRISK_detectRM',...
                    coder.ref(Iu8), ...
                    nRows, nCols,...
                    threshold, numOctaves,...
                    coder.ref(ptrKeypoints));                  
            end
            
            coder.varsize('location',[inf 2]);
            coder.varsize('metric',[inf 1]);
            coder.varsize('scale',[inf 1]);
            coder.varsize('orientation',[inf 1]);
            
            location = coder.nullcopy(zeros(numOut,2,'single'));
            metric   = coder.nullcopy(zeros(numOut,1,'single'));
            scale    = coder.nullcopy(zeros(numOut,1,'single'));
            orientation = coder.nullcopy(zeros(numOut,1,'single'));
            
            %> Copy detected BRISK Features to output
            if coder.isColumnMajor
                coder.ceval('-col','detectBRISK_assignOutputs', ptrKeypoints, ...
                    coder.ref(location),...
                    coder.ref(metric),...
                    coder.ref(scale),...
                    coder.ref(orientation)); 
            else
                coder.ceval('-row','detectBRISK_assignOutputsRM', ptrKeypoints, ...
                    coder.ref(location),...
                    coder.ref(metric),...
                    coder.ref(scale),...
                    coder.ref(orientation));                 
            end
                                  
            points.Location = location;
            points.Metric   = metric;
            points.Scale    = scale;
            points.Orientation = orientation;                      

        end       
    end   
end
