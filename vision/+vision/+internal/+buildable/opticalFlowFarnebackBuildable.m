classdef opticalFlowFarnebackBuildable < coder.ExternalDependency %#codegen
    % opticalFlowFarnebackBuildable - encapsulate opticalFlowFarneback
    % implementation library

    % Copyright 2012-2016 The MathWorks, Inc.


    methods (Static)

        function name = getDescriptiveName(~)
            name = 'opticalFlowFarnebackBuildable';
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
            buildInfo.addSourceFiles({'opticalFlowFarnebackCore.cpp', 'cgCommon.cpp'});
            buildInfo.addIncludeFiles({'vision_defines.h', ...
                                       'cgCommon.hpp', ...
                                       'opticalFlowFarnebackCore_api.hpp'}); % no need 'rtwtypes.h'

            vision.internal.buildable.portableOpenCVBuildInfo(buildInfo, context, ...
                'opticalFlowFarneback');
        end

        %------------------------------------------------------------------
        function outFlowXY = opticalFlowFarneback_compute( ...
         			ImagePrev, ImageCurr, inFlowXY, params)

            coder.inline('always');
            coder.cinclude('opticalFlowFarnebackCore_api.hpp');

            paramStruct = struct( ...
                'pyr_scale', double(params.pyr_scale), ...
                'poly_sigma',double(params.poly_sigma), ...
                'levels',    int32(params.levels), ...
                'winsize',   int32(params.winsize), ...
                'iterations',int32(params.iterations), ...
                'poly_n',    int32(params.poly_n), ...
                'flags',     int32(params.flags));

            coder.cstructname(paramStruct,'cvstFarnebackStruct_T');

            if coder.isColumnMajor
                % allocate output
                % compute original numrows, nomcols
                nRows = size(ImagePrev, 2);
                nCols = size(ImagePrev, 1);

                outSize = [nRows nCols 2];
                outFlowXY = coder.nullcopy(zeros(outSize,'single'));
                
                coder.ceval('-col', 'opticalFlowFarneback_compute',...
                  coder.ref(ImagePrev), ...
                  coder.ref(ImageCurr), ...
                  coder.ref(inFlowXY), ...
                  coder.ref(outFlowXY), ...
                  coder.ref(paramStruct), ...
                        int32(nRows), ...
                        int32(nCols) ...
                      );
            else
                % allocate output
                % compute original numrows, nomcols
                nRows = size(ImagePrev, 1);
                nCols = size(ImagePrev, 2);

                outSize = [nRows nCols 2];
                outFlowXY = coder.nullcopy(zeros(outSize,'single'));
                
                coder.ceval('-row', 'opticalFlowFarneback_computeRM',...
                  coder.ref(ImagePrev), ...
                  coder.ref(ImageCurr), ...
                  coder.ref(inFlowXY), ...
                  coder.ref(outFlowXY), ...
                  coder.ref(paramStruct), ...
                        int32(nRows), ...
                        int32(nCols) ...
                      );                
            end
        end
    end
end
