classdef pointTrackerBuildable < coder.ExternalDependency %#codegen
    %pointTrackerBuildable - encapsulate pointTracker implementation library

    % Copyright 2013-2017 The MathWorks, Inc.
    %#ok<*EMCA>
    methods (Static)

        function name = getDescriptiveName(~)
            name = 'pointTrackerBuildable';
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
            buildInfo.addSourceFiles({'pointTrackerCore.cpp', ...
                'cgCommon.cpp'});

            buildInfo.addIncludeFiles({'vision_defines.h', ...
                                       'pointTrackerCore_api.hpp', ...
                                       'cgCommon.hpp', ...
                                       'PointTrackerParams.hpp', ...
                                       'PointBuffers.hpp', ...
                                       'ImageBuffers.hpp', ...
                                       'PointTrackerOcv.hpp'}); % no need of 'rtwtypes.h'

            vision.internal.buildable.portableOpenCVBuildInfo(buildInfo, context, ...
                'pointTracker');
        end

        %------------------------------------------------------------------
        % call shared library function
        function ptrObj = pointTracker_construct()

            coder.inline('always');
            coder.cinclude('pointTrackerCore_api.hpp');

            ptrObj = coder.opaque('void *', 'NULL');

            % call function from shared library
            coder.ceval('pointTracker_construct', coder.ref(ptrObj));
        end

        %------------------------------------------------------------------
        % call shared library function
        function pointTracker_initialize(ptrObj, params, Iu8_gray, points)

            coder.inline('always');
            coder.cinclude('pointTrackerCore_api.hpp');

            % call function
            nRows = int32(size(Iu8_gray, 1));
            nCols = int32(size(Iu8_gray, 2));
            numPoints = int32(size(points, 1));

            % do not use cCast on vector; use ccast only for scalar
            blockH = cCast('int32_T',params.BlockSize(1));
            blockW = cCast('int32_T',params.BlockSize(2));
            blockSize = [blockH blockW];
            paramStruct = struct( ...
                'blockSize', blockSize, ...
                'numPyramidLevels', cCast('int32_T',params.NumPyramidLevels), ...
                'maxIterations', cCast('double',params.MaxIterations), ...
                'epsilon', double(params.Epsilon), ...
                'maxBidirectionalError', double(params.MaxBidirectionalError));

            coder.cstructname(paramStruct,'cvstPTStruct_T', 'extern');
            
            % call function from shared library
            if coder.isColumnMajor
                Iu8_grayT = Iu8_gray';
                coder.ceval('-col','pointTracker_initialize', ...
                            ptrObj, ...
                            coder.ref(Iu8_grayT), nRows, nCols, ...
                            coder.ref(points), numPoints, ...
                            coder.ref(paramStruct)); % pass struct by reference
            else
                coder.ceval('-row','pointTracker_initializeRM', ...
                            ptrObj, ...
                            coder.ref(Iu8_gray), nRows, nCols, ...
                            coder.ref(points), numPoints, ...
                            coder.ref(paramStruct)); % pass struct by reference
            end

        end

        %------------------------------------------------------------------
        % call shared library function
        function pointTracker_setPoints(ptrObj, points, pointValidity)

            coder.inline('always');
            coder.cinclude('pointTrackerCore_api.hpp');

            numPoints = int32(size(points, 1));

            % call function from shared library
            if coder.isColumnMajor
                coder.ceval('-col','pointTracker_setPoints', ...
                ptrObj, ...
                coder.ref(points), numPoints, coder.ref(pointValidity));
            else
                coder.ceval('-row','pointTracker_setPointsRM', ...
                ptrObj, ...
                coder.ref(points), numPoints, coder.ref(pointValidity));
            end
        end

        %------------------------------------------------------------------
        % call shared library function
        function [points, pointValidity, scores] = ...
                pointTracker_step(ptrObj, Iu8_gray, num_points)

            coder.inline('always');
            coder.cinclude('pointTrackerCore_api.hpp');

            % call function
            nRows = int32(size(Iu8_gray, 1));
            nCols = int32(size(Iu8_gray, 2));

            numPoints = int32(num_points);

            coder.varsize('points', [inf, 2]);
            coder.varsize('pointValidity', [inf, 1]);
            coder.varsize('scores', [inf, 1]);

            points = coder.nullcopy(zeros(double(numPoints),2,'single'));
            pointValidity = coder.nullcopy(false(double(numPoints),1));
            scores = coder.nullcopy(zeros(double(numPoints),1));

            % call function from shared library
            % no need to pass numPoints (retrieved from class member)
            if coder.isColumnMajor
                Iu8_grayT = Iu8_gray';
                coder.ceval('-col', 'pointTracker_step', ...
             ptrObj, coder.ref(Iu8_grayT), nRows, nCols, ...
             coder.ref(points),coder.ref(pointValidity),coder.ref(scores));
            else
                coder.ceval('-row', 'pointTracker_stepRM', ...
             ptrObj, coder.ref(Iu8_gray), nRows, nCols, ...
             coder.ref(points),coder.ref(pointValidity),coder.ref(scores));
            end
        end

        %------------------------------------------------------------------
        % call shared library function
        function outFrame = pointTracker_getPreviousFrame(ptrObj, frameSize)

            coder.inline('always');
            coder.cinclude('pointTrackerCore_api.hpp');

            outFrame = coder.nullcopy(zeros(double(frameSize),'uint8'));
            % call function from shared library
            % no need to pass frameSize (retrieved from class member)
            if coder.isColumnMajor
                coder.ceval('-col', 'pointTracker_getPreviousFrame', ...
                ptrObj, coder.ref(outFrame));
            else
                coder.ceval('-row', 'pointTracker_getPreviousFrameRM', ...
                ptrObj, coder.ref(outFrame));
            end
        end

        %------------------------------------------------------------------
        % call shared library function
        function [points, pointValidity] = ...
                pointTracker_getPointsAndValidity(ptrObj, num_points)

            coder.inline('always');
            coder.cinclude('pointTrackerCore_api.hpp');

            coder.varsize('points', [inf, 1]);
            coder.varsize('pointValidity', [inf, 1]);

            numPoints = int32(num_points);

            points = coder.nullcopy(zeros(double(numPoints),1,'single'));
            pointValidity = coder.nullcopy(false(double(numPoints),1));

            % call function from shared library
            % no need to pass numPoints (retrieved from class member)
            if coder.isColumnMajor
                coder.ceval('-col', 'pointTracker_getPointsAndValidity', ...
                ptrObj, ...
                coder.ref(points), coder.ref(pointValidity));
            else
                coder.ceval('-row', 'pointTracker_getPointsAndValidityRM', ...
                ptrObj, ...
                coder.ref(points), coder.ref(pointValidity));
            end
        end

        %------------------------------------------------------------------
        % call shared library function
        function pointTracker_deleteObj(ptrObj)

            coder.inline('always');
            coder.cinclude('pointTrackerCore_api.hpp');

            % call function from shared library
            coder.ceval('pointTracker_deleteObj', ptrObj);
        end

    end
end

function outVal = cCast(outClass, inVal)
outVal = coder.nullcopy(zeros(1,1,outClass));
outVal = coder.ceval(['('   outClass  ')'], inVal);
end