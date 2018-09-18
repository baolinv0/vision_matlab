% This class dispatches algorithms from a video labeler repository for the
% groundTruthLabeler app.

% Copyright 2017 The MathWorks, Inc.

classdef VideoLabelerAlgorithmDispatcher < vision.internal.labeler.AlgorithmDispatcher
    
    methods (Static, Hidden)
        %------------------------------------------------------------------
        function repo = getRepository()
            repo = vision.internal.labeler.VideoLabelerAlgorithmRepository.getInstance();
        end
    end
end