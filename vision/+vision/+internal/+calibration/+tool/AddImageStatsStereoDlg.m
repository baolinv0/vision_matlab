classdef AddImageStatsStereoDlg < vision.internal.calibration.tool.AddImageStatsDlg
    methods
        function this = AddImageStatsStereoDlg(groupName, stats, rejectedFileNames)
            this = this@vision.internal.calibration.tool.AddImageStatsDlg(...
                groupName, stats, rejectedFileNames);
        end
    end
    
    methods(Access=protected)
        %------------------------------------------------------------------
        function setHeadingStringNoDuplicates(this)
            this.HeadingString = vision.getMessage(...
                'vision:caltool:NumDetectedBoardsStereo');
        end
        
        %------------------------------------------------------------------
        function setHeadingStringWithDuplicates(this)
            this.HeadingString = vision.getMessage(...
                'vision:caltool:AddBoardStatisticsStereo');
        end        
    end
end