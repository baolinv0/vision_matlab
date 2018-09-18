classdef RegionCropAndResizer
    
    properties 
        % ExpansionAmount Amount to expand each region proposal. This 
        %                 captures more background context.
        ExpansionAmount = 0;
        
        % PadValue Value to use when padding image to size required by
        %          network. Used when PreserveAspectRatio is true.
        PadValue = [];
        
        % PreserveAspectRatio True or false.
        PreserveAspectRatio = false;
                
        % ImageSize The size of an image as a 1-by-3 vector.
        ImageSize
    end
    
    methods        
        
        %------------------------------------------------------------------
        % Returns a batch of image patches cropped from I and resized to
        % this.ImageSize.
        %------------------------------------------------------------------
        function batch = cropAndResize(this, I, bboxes)
            
            [height,width,~] = size(I);
            
            % rounds floats and casts to int32 to avoid saturation of smaller integer types.
            bboxes = vision.internal.detector.roundAndCastToInt32(bboxes); 
            
            if this.PreserveAspectRatio
                numObservations = size(bboxes,1);
                
                % Pad boxes, also clips to size of image.
                bboxes = vision.internal.detector.expandROI([height width], bboxes, this.ExpansionAmount(1));
                
                x1 = bboxes(:,1);
                x2 = x1 + bboxes(:,3) - 1;
                y1 = bboxes(:,2);
                y2 = y1 + bboxes(:,4) - 1;
                
                % pre-allocate mini-batch buffer
                dims = [this.ImageSize numObservations];
                batch = repelem( cast(this.PadValue,'like',I), dims(1), dims(2), dims(3), dims(4)); 
                
                sz = repmat(this.ImageSize(1:2), size(bboxes,1), 1);
                ind = sub2ind([size(bboxes,1),2], (1:size(bboxes,1))', (bboxes(:,3) < bboxes(:,4)) + 1);                
                sz(ind) = NaN;
                
                
                for i = 1:numObservations
                    
                    patch = imresize(I(y1(i):y2(i),x1(i):x2(i),:), sz(i,:));
                    
                    [m,n,~]=size(patch);                        
                                        
                    % add padding to fill 
                    if m < n              
                        % pad height                        
                        offset = floor( (this.ImageSize(1) - m) / 2 );                                              
                        batch((1:m)+offset, : , :, i) = patch;
                        
                    else
                        % pad width
                        offset = floor( (this.ImageSize(2) - n) / 2 );
                        batch(:, (1:n)+offset , :, i) = patch;
                    end                                                                           
                end                                
            else               
                % Crop and resize regsions. Also expands region.
                batch = visionCropAndResizeRegions(single(I), double(bboxes), ...
                    this.ImageSize(1), this.ImageSize(2), this.ExpansionAmount(1));                                
            end
        end
    end
end
        