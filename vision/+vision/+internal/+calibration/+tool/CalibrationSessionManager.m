classdef CalibrationSessionManager < vision.internal.uitools.SessionManager
    properties
        IsStereo = false;
    end
    
    methods
        %------------------------------------------------------------------
        function isValid = isValidSessionFile(this, sessionStruct)
            isValid = isValidSessionFile@vision.internal.uitools.SessionManager(this, sessionStruct);
            if isValid
                session = sessionStruct.(this.SessionField);
                if this.IsStereo
                    isValid = session.IsValidStereoCameraSession;
                    if session.IsValidSingleCameraSession
                        this.CustomErrorMsgId = ...
                            'vision:caltool:loadingSingleCameraSessionIntoStereoCalibrator';
                    end
                else
                    isValid = session.IsValidSingleCameraSession;
                    if session.IsValidStereoCameraSession
                        this.CustomErrorMsgId = ...
                            'vision:caltool:loadingStereoCameraSessionIntoCameraCalibrator';
                    end
                end
            end
        end
    end
end