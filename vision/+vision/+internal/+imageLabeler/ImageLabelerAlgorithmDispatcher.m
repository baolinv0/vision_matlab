% This class dispatches algorithms from an image labeler repository for the
% imageLabeler app.

% Copyright 2017 The MathWorks, Inc.

classdef ImageLabelerAlgorithmDispatcher < vision.internal.labeler.AlgorithmDispatcher
    
    methods (Static, Hidden)
        %------------------------------------------------------------------
        function repo = getRepository()
            repo = vision.internal.imageLabeler.ImageLabelerAlgorithmRepository.getInstance();
        end
    end
end