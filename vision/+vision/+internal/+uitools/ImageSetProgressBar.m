% Progress bar to use when processing a set of images.

% This class is for internal use only and may change in the future.

classdef ImageSetProgressBar < handle
   
    properties
        WaitBar
        CurrentState
        NumImages
        
        % MessageID for custom message to display. Must be a message ID
        % that takes two parameters: the current image index being
        % processed and the number of images. 
        MessageID
    end  
    
    %----------------------------------------------------------------------
    properties(Dependent)
        Canceled
    end
    
    methods
                
        %------------------------------------------------------------------
        % Create a progress bar. Provide an title ID and a message ID. The
        % message ID must take 2 parameters. The first parameter passed to
        % the message ID is current index and the second is the total
        % number of images.
        %------------------------------------------------------------------
        function this = ImageSetProgressBar(numImages, titleID, msgID)
           
            this.WaitBar = waitbar(0, ...
                vision.getMessage(titleID), ...
                'Tag', 'ImageSetProgressBar', ...
                'WindowStyle', 'modal',...
                'Name', vision.getMessage(titleID) );
            this.NumImages = numImages;
            this.CurrentState = 1;
            this.MessageID = msgID;
        end
        
        %------------------------------------------------------------------
        function canceled = get.Canceled(this)
            canceled = this.NumImages > 1 && ...
                (isempty(this.WaitBar) || ~ishandle(this.WaitBar));
        end                
        
        %------------------------------------------------------------------
        function update(this)                       

            percentage = this.CurrentState/this.NumImages;
            msg = vision.getMessage(this.MessageID, ...               
                this.CurrentState, this.NumImages);
            
            if this.NumImages > 1 && ~this.Canceled
                waitbar(percentage, this.WaitBar, msg);
                this.CurrentState = this.CurrentState + 1;
            end
            
        end
        
        %------------------------------------------------------------------
        function delete(this)
            if ishandle(this.WaitBar)
                delete(this.WaitBar)
            end
        end
    end
end