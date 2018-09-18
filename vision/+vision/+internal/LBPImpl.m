% Internal LPB Implementation
%#codegen
classdef LBPImpl < handle
    % ---------------------------------------------------------------------
    % Store relevant LBP properties
    % ---------------------------------------------------------------------
    properties(GetAccess = public, SetAccess = protected)
        NumNeighbors 
        Radius 
        Interpolation
        Normalization
        CellSize
        Uniform
        Upright
        LUT
    end
    
    % ---------------------------------------------------------------------
    % Minor properties
    % ---------------------------------------------------------------------
    properties(Access = protected, Hidden)
        % Number of bins for LBP histogram
        NumBins                           
        
        % Flag to control use of look-up table
        UseLUT
    end
    
    % ---------------------------------------------------------------------
    % Interpolation related properties. Support for nearest and linear
    % interpolation.
    % ---------------------------------------------------------------------
    properties(GetAccess = public, SetAccess = protected)                
        % Offsets - Offsets to each neighbor. Offsets are relative to the
        % the center pixel.
        Offsets
        
        % BilinearWeights - Bilinear interpolation weights
        BilinearWeights
    end
    
    % ---------------------------------------------------------------------
    % Public Methods
    % ---------------------------------------------------------------------
    methods
        
        function [lbpHist] = extractLBPFeatures(this, I)
            
            I = im2uint8(I);
            
            params = getParams(this);
            
            lbpHist = visionExtractLBPFeatures(I, params, this.LUT, this.Offsets, this.BilinearWeights);
            
            % remove border cells
            lbpHist = lbpHist(:, 2:end-1, 2:end-1);
            
            % normalize
            if strcmpi(this.Normalization, 'l2')
                lbpHist = bsxfun(@rdivide, lbpHist, sqrt(sum(lbpHist.^2)) + eps('single'));
            end
            
            % output features as 1-by-N
            lbpHist = reshape(lbpHist, 1, []);
        end
    end
    
    % ---------------------------------------------------------------------
    % Codegen static methods that implement LBP
    % ---------------------------------------------------------------------
    methods(Static)
        
        % -----------------------------------------------------------------
        function h = initializeHist(cellSize, numBins, M, N)
            numCells = floor([M N]./cellSize);
            h = zeros([numBins numCells+2],'single');  % +2 for cells bins at edges, these are remove later
        end
        
        % -----------------------------------------------------------------
        function [xmax, ymax] = computeRange(cellSize, radius, M, N)
            
            ymax = floor(M/cellSize(1)) * cellSize(1);
            xmax = floor(N/cellSize(2)) * cellSize(2);
            
            % range up to last pixel in cell or that fits in image
            ymax = min(ymax, M-radius);
            xmax = min(xmax, N-radius);
        end
        
        % -----------------------------------------------------------------
        % Return uniform LBP code from plain LBP (stored in multi-byte
        % format).
        function bin = getUniformLBPCode(lbp, index, numNeighbors, scaling, numBins, upright)
            coder.inline('always');
            u = vision.internal.LBPImpl.uniformLBP(lbp, numNeighbors);
            
            if u <= 2
                value = sum(scaling.*single(lbp));
                value = cast(value, 'uint32');
                
                numBits = vision.internal.LBPImpl.getNumSetBits(value, numNeighbors);
                
                [~, numShifts] = vision.internal.LBPImpl.rotateLBP(value, numNeighbors);
                
                if ~upright
                    % uniform + rotated
                    bin =  index(numBits+1) + 1; % +1 for 1-based
                else
                    % uniform
                    bin =  index(numBits+1) + numShifts + 1;
                end
            else
                bin = numBins;
            end
        end
        
        % -----------------------------------------------------------------
        % Return uniform rotated LBP code from plain LBP (stored in
        % multi-byte format).
        function [bin] = getUniformRotatedLBPCode(lbp, index, numNeighbors, scaling, numBins, upright)
            coder.inline('always');
            bin = vision.internal.LBPImpl.getUniformLBPCode(lbp, index, numNeighbors, scaling, numBins, upright);
        end
        
        % -----------------------------------------------------------------
        % Return LBP code and bin for histogram using look-up tables.
        % Used for uniform and uniform+rotated
        function [bin] = getLBPCodeLUT(lbp, lut, scaling)
            lbp = sum(scaling.*single(lbp));
            % convert multi-byte string into single value.
            bin = lut(single(lbp)+1) + 1; % LUT is 0-based, +1 to keep it one based.
        end
        
        % -----------------------------------------------------------------
        % Return plain LBP code and bin for histogram.
        function [bin] = getLBPCodePlain(lbp, scaling)
            lbp = sum(scaling.*single(lbp));
            bin = single(lbp)+1;
        end
        
        % -----------------------------------------------------------------
        function px = bilinearInterp(I, x, y, idx, offsets, weights)
            coder.inline('always')
            
            y = int32(y);
            x = int32(x);
            
            % neighbors of pixel,x
            % f(0,0) -- f(1,0)
            % |       x    |
            % f(0,1) -- f(1,1)
            f00 = single(I(y + offsets(2,1,idx), x + offsets(1,1,idx)));
            f10 = single(I(y + offsets(2,2,idx), x + offsets(1,2,idx)));
            f01 = single(I(y + offsets(2,3,idx), x + offsets(1,3,idx)));
            f11 = single(I(y + offsets(2,4,idx), x + offsets(1,4,idx)));
            
            a = f00;
            b = f10 - f00;
            c = f01 - f00;
            d = f00 - f10 - f01 + f11;
            
            xval = weights(1, idx);
            yval = weights(2, idx);
            xy   = weights(3, idx);
            
            px = a + b*xval + c*yval + d*xy;
            
        end
        
        % -----------------------------------------------------------------
        function px = nearestInterp(I, x, y, idx, offsets)
            coder.inline('always')
            y = int32(y);
            x = int32(x);
            px = single(I(y + offsets(2, idx), x + offsets(1, idx)));
        end
        
        % -----------------------------------------------------------------
        % Returns a multi-byte LBP code stored in stored as multiple uint8
        % values. lbp(1) is the MSB, lbp(end) is the LSB.
        % -----------------------------------------------------------------
        function lbp = computeMultibyteLBP(I, x, y, numNeighbors, interpolation, numBytes, offsets, weights)
            
            coder.inline('always');
            
            lbp = zeros(1,numBytes,'uint8');
            center = I(y,x);            
            
            p2 = coder.internal.indexInt(numNeighbors);
            p1 = coder.internal.indexInt((8*numBytes)-7+1);
            for n = coder.unroll(1:numBytes) % MSB [xxxx] LSB
                for p = p2:-1:p1 % reverse order b/c of bitshift to left
                    
                    if strcmpi(interpolation, 'linear')
                        neighbor = vision.internal.LBPImpl.bilinearInterp(I, x, y, p, offsets, weights);
                    else
                        neighbor = vision.internal.LBPImpl.nearestInterp(I, x, y, p, offsets);
                    end
                    
                    lbp(n) = bitor(lbp(n), uint8(neighbor >= center));
                    lbp(n) = bitshift(uint8(lbp(n)),uint8(1));
                end
                
                % bit p1-1
                if strcmpi(interpolation, 'linear')
                    neighbor = vision.internal.LBPImpl.bilinearInterp(I, x, y, p1-1, offsets, weights);
                else
                    neighbor = vision.internal.LBPImpl.nearestInterp(I, x, y, p1-1, offsets);
                end
                
                lbp(n) = bitor(lbp(n), uint8(neighbor >= center));
                
                % next byte
                p2 = p1-2;
                p1 = p2-7+1;
            end
        end
        % -----------------------------------------------------------------
        function [lbpHist] = codegenExtractLBPFeatures(I, numNeighbors, radius, interpolation, uniform, upright, cellSize, normalization)
            coder.extrinsic('eml_try_catch');
            I = im2uint8(I);
            
            [x, y] = vision.internal.LBPImpl.generateNeighborLocations(numNeighbors, radius);
            
            if strncmpi(interpolation, 'l',1)
                [offsets, weights] = vision.internal.LBPImpl.createBilinearOffsets(x, y, numNeighbors);
            else
                [offsets, weights] =  vision.internal.LBPImpl.createNearestOffsets(x, y);
            end
            
            % look-up table only used for 8 or 16 neighbors. Otherwise
            % in-line computation is used.
            if numNeighbors == 8 || numNeighbors == 16
                useLUT = true;
            else
                useLUT = false;
            end
            
            if ~uniform && upright                
                numBins = uint32(2^numNeighbors);
            elseif useLUT
                % force look-up table to be generated inline.
                myfun = 'vision.internal.LBPImpl.makeLUT';              
                [errid,errmsg,lut,numBins] = eml_const(eml_try_catch(myfun,numNeighbors,uniform,upright));
                eml_lib_assert(isempty(errmsg),errid,errmsg);               
            else
                
                % on-the-fly LBP computations                
                if uniform && ~upright
                    % uniform and rotated                    
                    numBins = uint32(numNeighbors + 2);
                    index   = uint32(0:numNeighbors);                    
                else
                    numBins = uint32(numNeighbors*(numNeighbors-1) + 3);
                    index   = uint32([0 1:numNeighbors:(numNeighbors*(numNeighbors-1)+1)]);
                end
            end
            
            [M, N] = size(I);
            
            lbpHist = vision.internal.LBPImpl.initializeHist(cellSize, numBins, M, N);
            
            [xmax, ymax] = vision.internal.LBPImpl.computeRange(cellSize, radius, M, N);
            
            invCellSize = 1./cellSize;
            
            numBytes = ceil(numNeighbors/8);
            
            % Scaling to convert N bytes to a float. MSB is at elem 1, LSB
            % is at end.
            scaling  = 2.^((8*numBytes-8):-8:0); % to store multi-byte LBP
            
            % start at Radius+1 to process full Radius+1-by-Radius+1 block
            for x = ((radius+1):xmax)
                
                cx = floor((x-0.5) * invCellSize(2) - 0.5);
                x0 = cellSize(2) * (cx + 0.5);
                
                wx2 = ((x-0.5) - x0) * invCellSize(2);
                wx1 = 1 - wx2;
                
                cx = cx + 2; % 1-based
                
                for y = ((radius+1):ymax)
                    
                    lbp = vision.internal.LBPImpl.computeMultibyteLBP(I, x, y, numNeighbors, interpolation, numBytes, offsets, weights);
                    
                    if ~uniform && upright
                        bin =  vision.internal.LBPImpl.getLBPCodePlain(lbp, scaling);
                    elseif useLUT
                        % uniform, uniform+rotated
                        bin = vision.internal.LBPImpl.getLBPCodeLUT(lbp, lut, scaling);
                    else
                        % on-the-fly LBP computations
                        if uniform && ~upright
                            % uniform and rotated
                            bin = vision.internal.LBPImpl.getUniformRotatedLBPCode(lbp, index, numNeighbors, scaling, numBins, upright);
                        else
                            bin = vision.internal.LBPImpl.getUniformLBPCode(lbp, index, numNeighbors, scaling, numBins, upright);
                        end
                    end
                    
                    % spatial weights for cell bins
                    cy = floor((y-0.5) * invCellSize(1) - 0.5);
                    y0 = cellSize(1) * (cy + 0.5);
                    
                    wy2 = ((y-0.5) - y0) * invCellSize(1);
                    wy1 = 1 - wy2;
                    cy = cy + 2; % 1 - based
                    
                    wx1y1 = wx1 * wy1;
                    wx2y2 = wx2 * wy2;
                    wx1y2 = wx1 * wy2;
                    wx2y1 = wx2 * wy1;
                    
                    lbpHist(bin, cy      , cx)     = lbpHist(bin, cy     , cx)     + wx1y1;
                    lbpHist(bin, cy + 1  , cx)     = lbpHist(bin, cy + 1 , cx)     + wx1y2;
                    lbpHist(bin, cy      , cx + 1) = lbpHist(bin, cy     , cx + 1) + wx2y1;
                    lbpHist(bin, cy + 1  , cx + 1) = lbpHist(bin, cy + 1 , cx + 1) + wx2y2;
                    
                end
            end
            
            % remove border cells
            lbpHist = lbpHist(:, 2:end-1, 2:end-1);
            
            % normalize
            if strcmpi(normalization, 'l2')
                lbpHist = bsxfun(@rdivide, lbpHist, sqrt(sum(lbpHist.^2)) + eps('single'));
            end
            
            % output features as 1-by-N
            lbpHist = reshape(lbpHist, 1, []);
        end
        
        % -----------------------------------------------------------------
        % Create offsets plus bilinear interp weights
        function [offsets, weights] = createBilinearOffsets(x, y, numNeighbors)
            
            % Pre-compute offsets to neighbors of pixel,px
            % f(0,0) -- f(1,0)
            % |      px    |
            % f(0,1) -- f(1,1)
            floorX = floor(x);
            floorY = floor(y);
            ceilX  = ceil(x);
            ceilY  = ceil(y);
            
            offsets = ...
                [floorX; floorY   % f(0,0)
                ceilX ; floorY    % f(1,0)
                floorX; ceilY     % f(0,1)
                ceilX ; ceilY];   % f(1,1)
            
            % Pre-compute interp weights, dx, dy, dx*dy for bilinear interp
            %
            %  dx and dy are distances from f(0,0) to the pixel, px, to be
            %  interpolated.
            %
            %  f(0,0)---->
            %         dx  |
            %             | dy
            %             v
            %            px
            %
            weights      = coder.nullcopy(zeros(3, numNeighbors, 'single'));
            weights(1,:) = x - offsets(1,:);               % x
            weights(2,:) = y - offsets(2,:);               % y
            weights(3,:) = weights(1,:) .* weights(2,:);   % xy
            
            % 2-by-4-by-N storage to simplify indexing during interp.
            offsets = reshape(offsets, 2, 4, []);
            
            offsets = int32(offsets);
            
        end
        
        % -----------------------------------------------------------------
        function [offsets, weights] = createNearestOffsets(x, y)
            offsets = int32(round([x;y]));
            weights = zeros(1,1,'single');
        end
        
        % -----------------------------------------------------------------
        function [x, y] = generateNeighborLocations(numNeighbors, radius)
            % generate locations for circular symmetric neighbors
            theta = single((360/numNeighbors) * (0:numNeighbors-1));
            
            x =  radius * cosd(theta);
            y = -radius * sind(theta);
        end
    end
    
    
    % ---------------------------------------------------------------------
    % Protected methods.
    % ---------------------------------------------------------------------
    methods(Access = protected, Hidden)
        function this = LBPImpl(params)
            
            setParams(this, params);
            
            initialize(this);
        end
        
        % -----------------------------------------------------------------
        function initialize(this)
            
            this.computeNeighborInfo();
                       
            this.updateNeighborDependentParameters();      
            
            if this.UseLUT   
                [this.LUT, this.NumBins] = vision.internal.LBPImpl.makeLUT(this.NumNeighbors, this.Uniform, this.Upright);
            end
                  
        end
        
        % -----------------------------------------------------------------
        function updateNeighborDependentParameters(this)
            
            if ~this.Uniform && this.Upright
                % internal testing only
                this.NumBins = 2^this.NumNeighbors;
                this.UseLUT  = false;
            else
                if this.Uniform && ~this.Upright
                    % uniform and rotated
                    this.NumBins = this.NumNeighbors + 2;
                elseif this.Uniform
                    this.NumBins = this.NumNeighbors*(this.NumNeighbors-1) + 3;
                end
            end
        end
        
        % -----------------------------------------------------------------
        % Update implementation parameters. Called when cached
        % implementations in getImpl require updated parameters.
        % -----------------------------------------------------------------
        function update(this, params)
            
            radiusChanged        = this.Radius ~= params.Radius;
            interpMethodChanged  = ~strcmpi(this.Interpolation(1), params.Interpolation(1));
            numNeighborsChanged  = this.NumNeighbors ~= params.NumNeighbors;
            uprightChanged       = this.Upright ~= params.Upright;
            
            setParams(this, params);
                        
            if radiusChanged || interpMethodChanged || numNeighborsChanged
                this.computeNeighborInfo();                                    
            end
            
            if numNeighborsChanged || uprightChanged           
                this.updateNeighborDependentParameters();                               
            end                        
        end
        
        % -----------------------------------------------------------------
        function setParams(this, params)
            this.NumNeighbors  = single(params.NumNeighbors);
            this.Radius        = single(params.Radius);
            this.Uniform       = params.Uniform;
            this.Upright       = params.Upright;
            this.CellSize      = params.CellSize;
            this.Interpolation = params.Interpolation;
            this.Normalization = params.Normalization;
            this.UseLUT        = params.UseLUT;            
        end
        
        % -----------------------------------------------------------------
        function params = getParams(this)
            params.NumNeighbors  = uint32(this.NumNeighbors);
            params.Radius        = uint32(this.Radius);
            params.Uniform       = this.Uniform;
            params.Upright       = this.Upright;
            params.CellSize      = uint32(this.CellSize);
            params.Interpolation = strcmpi(this.Interpolation(1),'l');
            params.Normalization = this.Normalization;
            params.UseLUT        = this.UseLUT;
            params.NumBins       = uint32(this.NumBins);
        end
        
        % -----------------------------------------------------------------
        % Pre-compute offsets for neighbor access and weights for bilinear
        % interpolation.
        function computeNeighborInfo(this)
            
            [x, y] = vision.internal.LBPImpl.generateNeighborLocations(this.NumNeighbors, this.Radius);
            
            if strncmpi(this.Interpolation, 'l',1)
                [this.Offsets, this.BilinearWeights] = vision.internal.LBPImpl.createBilinearOffsets(x, y, this.NumNeighbors);
            else
                [this.Offsets, this.BilinearWeights] = vision.internal.LBPImpl.createNearestOffsets(x, y);
            end
        end
    end
    
    % ---------------------------------------------------------------------
    % Static method to configure the LBP algorithm.
    % ---------------------------------------------------------------------
    methods(Static)
        % -----------------------------------------------------------------
        % Returns cached LBPImpl. Used to speed up look-up table based
        % implementation. Only 8 and 16 bit patterns use look-up tables.
        % Others use on-the-fly computations.
        % -----------------------------------------------------------------
        function impl = getImpl(params)
            persistent ...
                lbpImpl8u ...  % 8-bit  uniform LUT
                lbpImpl8ur ... % 8-bit  uniform+rotated LUT
                lbpImpl16u ... % 16-bit uniform LUT
                lbpImpl16ur ...% 16-bit uniform+rotated LUT
                lbpImpl        % on-the-fly computation
            
            % Set internal parameters
            params.Uniform = true;
            
            if params.NumNeighbors == 8
                
                params.UseLUT = true;
                
                if params.Upright
                    % 8-bit uniform
                    if isempty(lbpImpl8u)
                        lbpImpl8u = vision.internal.LBPImpl(params);
                    else
                        update(lbpImpl8u, params);
                    end
                    impl = lbpImpl8u;
                else
                    % 8-bit uniform + rotated
                    if isempty(lbpImpl8ur)
                        lbpImpl8ur = vision.internal.LBPImpl(params);
                    else
                        update(lbpImpl8ur, params);
                    end
                    impl = lbpImpl8ur;
                end
                
            elseif params.NumNeighbors == 16
                
                params.UseLUT = true;
                
                if params.Upright
                    % 16-bit uniform
                    if isempty(lbpImpl16u)
                        lbpImpl16u = vision.internal.LBPImpl(params);
                    else
                        update(lbpImpl16u, params);
                    end
                    impl = lbpImpl16u;
                else
                    % 16-bit uniform + rotated
                    if isempty(lbpImpl16ur)
                        lbpImpl16ur = vision.internal.LBPImpl(params);
                    else
                        update(lbpImpl16ur, params);
                    end
                    impl = lbpImpl16ur;
                end
            else
                params.UseLUT = false;
                if isempty(lbpImpl)
                    lbpImpl = vision.internal.LBPImpl(params);
                else
                    update(lbpImpl, params)
                end
                impl = lbpImpl;
            end
            
        end
        % -----------------------------------------------------------------
        % Used for internal testing.
        % -----------------------------------------------------------------
        function impl = configure(params)
            impl = vision.internal.LBPImpl(params);
        end
    end
    
    % ---------------------------------------------------------------------
    % Static methods for generating LBP look-up tables.
    % ---------------------------------------------------------------------
    methods(Static, Hidden)
        
        function [lut, nbins] = makeLUT(numNeighbors, uniform, upright)
            % Return LUT for uniform LBP patterns and/or rotated LBP.
            %   1) uniform means at most 2 0/1 or 1/0 transitions in LBP code.
            %   2) rotated patterns are circularly shifted until minimized.
            %   3) Max number of neighbors for LUT is 32, i.e. only 32-bit codes.
            
            if nargin == 2
                upright = true;
            end
            
            assert(uniform || ~upright);
            
            lut = visionMakeLBPLUT(uint32(numNeighbors), uniform, upright);
            
            if uniform && ~upright
                nbins = (numNeighbors+1) + 1; % +1 for non-uniform patterns
            else
                nbins = numNeighbors*(numNeighbors-1) + 2 + 1;
            end
            
        end        

        % -----------------------------------------------------------------
        function n = getNumSetBits(value, NumNeighbors)
            n = uint32(0);
            for i = 1:NumNeighbors
                n = n + cast(bitget(value, i),'uint32');
            end
        end
        
        % -----------------------------------------------------------------
        function u = uniformLBP(lbp, NumNeighbors)
            % Returns the number of transitions in a binary lbp code.
            % lbp may be stored in multi-byte format; elem 1 is MSB, end is LSB
            
            numBytes = int32(numel(lbp));
            
            % init
            n = int32(8) - int32((8*numBytes)) + int32(NumNeighbors); % position in the byte to start at
            % initialize with transition from MSB to LSB
            u = bitxor(bitget(lbp(1),n), bitget(lbp(end), 1));
            a = bitget(lbp(1), n);
            n = n - 1;
            
            for j = 1:numBytes  % MSB [xxxx] LSB
                while n
                    b = bitget(lbp(j), n);
                    u = u + bitxor(a,b);
                    a = b;
                    n = n - 1;
                end
                n = int32(8);
            end
        end
        
        % -----------------------------------------------------------------
        function [rotated, count] = rotateLBP(lbp, NumNeighbors)
            % Return minimized lbp pattern computed by rotating the input
            % lbp code to the right until it is minimized. Also return the
            % number of shifts needed to reach minimum.
            rotated = lbp;
            count = uint32(0);
            for k = 1:uint32(NumNeighbors)
                lbp  = vision.internal.LBPImpl.rotr(lbp, 1, NumNeighbors);
                if lbp < rotated
                    rotated = lbp;
                    count  = k;
                end
            end
        end
        
        % -----------------------------------------------------------------
        % circular right shift: x >> K | x << (NumNeighbors-K)
        function out = rotr(in, K, NumNeighbors)
            coder.inline('always');
            
            a = bitshift(in, -K);
            b = bitshift(in, NumNeighbors - K);
            mask = cast(2^NumNeighbors-1, 'like', in); % required for partial bytes
            b = bitand(b, mask);            % mask out upper 8-NumNeighbors bits
            out = bitor(a,b);
        end
    end
    
end