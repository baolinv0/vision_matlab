classdef BinaryFileReader< matlab.system.SFunSystem & matlab.system.mixin.FiniteSource
%BinaryFileReader Read binary video data from files
%   -----------------------------------------------------------------------
%   The vision.BinaryFileReader will be removed in a future release. Use
%   the vision.VideoFileReader system Object with equivalent functionality
%   instead.
%   -----------------------------------------------------------------------
%
%   HBFR = vision.BinaryFileReader returns a System object, HBFR, that
%   reads binary video data from the specified file in the specified
%   format.
%
%   HBFR = vision.BinaryFileReader('PropertyName', PropertyValue, ...)
%   returns a binary file reader System object, HBFR, with each specified
%   property set to the specified value.
%
%   HBFR = vision.BinaryFileReader(FILE, 'PropertyName', PropertyValue,
%   ...) returns a binary file reader System object, HBFR, with the
%   Filename property set to FILE and other specified properties set to the
%   specified values.
%
%   Step method syntax:
%
%   [Y, Cb, Cr] = step(HBFR) reads the luma (Y) and chroma (Cb and Cr)
%   components of a video stream from the specified binary file when the
%   VideoFormat property is 'Four character codes'.
%
%   Y = step(HBFR) reads video component Y from the binary file when the
%   VideoFormat property is 'Custom' and the VideoComponentCount property
%   is 1.
%
%   [Y, Cb] = step(HBFR) reads video components Y and Cb from the binary
%   file when the VideoFormat property is 'Custom' and the
%   VideoComponentCount property is 2.
%
%   [Y, Cb, Cr] = step(HBFR) reads video components Y, Cb and Cr when the
%   VideoFormat property is 'Custom' and the VideoComponentCount property
%   is 3.
%
%   [Y, Cb, Cr, Alpha] = step(HBFR) reads video components Y, Cb, Cr and
%   Alpha when the VideoFormat property is 'Custom' and the
%   VideoComponentCount property is 4.
%
%   [..., EOF] = step(HBFR) also returns the end-of-file indicator, EOF.
%   EOF is true each time the output contains the last video frame in the
%   file.
%
%   System objects may be called directly like a function instead of using
%   the step method. For example, y = step(obj) and y = obj() are
%   equivalent.
%
%   BinaryFileReader methods:
%
%   step     - See above description for use of this method
%   release  - Allow property value and input characteristics changes, and
%              release binary file reader resources
%   clone    - Create binary file reader object with same property values
%   isLocked - Locked status (logical)
%   reset    - Reset to the beginning of the file
%   isDone   - Returns true if System object has reached end-of-file
%
%   BinaryFileReader properties:
%
%   Filename            - Name of binary file to read from
%   VideoFormat         - Format of binary video data
%   FourCharacterCode   - Four Character Code video format
%   BitstreamFormat     - Format of data as planar or packed
%   OutputSize          - Size of output matrix
%   VideoComponentCount - Number of video components in video stream
%   VideoComponentBits  - Bit size of video components
%   VideoComponentSizes - Size of output matrix
%   VideoComponentOrder - How to arrange video components in binary file
%   InterlacedVideo     - Whether data stream represents interlaced video
%   LineOrder           - How to fill binary file
%   SignedData          - Whether input data is signed
%   ByteOrder           - Byte ordering as little endian or big endian
%   PlayCount           - Number of times to play the file
%
%   % EXAMPLE: Read in a binary video file and play it back on the screen
%       hbfr = vision.BinaryFileReader();
%
%       hvp = vision.VideoPlayer;
%       while ~isDone(hbfr)
%           y = step(hbfr);
%           step(hvp, y);
%       end
%       release(hbfr);   % close the input file
%       release(hvp);    % close the video display 
%
%   See also vision.VideoFileReader, vision.BinaryFileWriter. 

 
%   Copyright 2008-2016 The MathWorks, Inc.

    methods
        function out=BinaryFileReader
            %BinaryFileReader Read binary video data from files
            %   -----------------------------------------------------------------------
            %   The vision.BinaryFileReader will be removed in a future release. Use
            %   the vision.VideoFileReader system Object with equivalent functionality
            %   instead.
            %   -----------------------------------------------------------------------
            %
            %   HBFR = vision.BinaryFileReader returns a System object, HBFR, that
            %   reads binary video data from the specified file in the specified
            %   format.
            %
            %   HBFR = vision.BinaryFileReader('PropertyName', PropertyValue, ...)
            %   returns a binary file reader System object, HBFR, with each specified
            %   property set to the specified value.
            %
            %   HBFR = vision.BinaryFileReader(FILE, 'PropertyName', PropertyValue,
            %   ...) returns a binary file reader System object, HBFR, with the
            %   Filename property set to FILE and other specified properties set to the
            %   specified values.
            %
            %   Step method syntax:
            %
            %   [Y, Cb, Cr] = step(HBFR) reads the luma (Y) and chroma (Cb and Cr)
            %   components of a video stream from the specified binary file when the
            %   VideoFormat property is 'Four character codes'.
            %
            %   Y = step(HBFR) reads video component Y from the binary file when the
            %   VideoFormat property is 'Custom' and the VideoComponentCount property
            %   is 1.
            %
            %   [Y, Cb] = step(HBFR) reads video components Y and Cb from the binary
            %   file when the VideoFormat property is 'Custom' and the
            %   VideoComponentCount property is 2.
            %
            %   [Y, Cb, Cr] = step(HBFR) reads video components Y, Cb and Cr when the
            %   VideoFormat property is 'Custom' and the VideoComponentCount property
            %   is 3.
            %
            %   [Y, Cb, Cr, Alpha] = step(HBFR) reads video components Y, Cb, Cr and
            %   Alpha when the VideoFormat property is 'Custom' and the
            %   VideoComponentCount property is 4.
            %
            %   [..., EOF] = step(HBFR) also returns the end-of-file indicator, EOF.
            %   EOF is true each time the output contains the last video frame in the
            %   file.
            %
            %   System objects may be called directly like a function instead of using
            %   the step method. For example, y = step(obj) and y = obj() are
            %   equivalent.
            %
            %   BinaryFileReader methods:
            %
            %   step     - See above description for use of this method
            %   release  - Allow property value and input characteristics changes, and
            %              release binary file reader resources
            %   clone    - Create binary file reader object with same property values
            %   isLocked - Locked status (logical)
            %   reset    - Reset to the beginning of the file
            %   isDone   - Returns true if System object has reached end-of-file
            %
            %   BinaryFileReader properties:
            %
            %   Filename            - Name of binary file to read from
            %   VideoFormat         - Format of binary video data
            %   FourCharacterCode   - Four Character Code video format
            %   BitstreamFormat     - Format of data as planar or packed
            %   OutputSize          - Size of output matrix
            %   VideoComponentCount - Number of video components in video stream
            %   VideoComponentBits  - Bit size of video components
            %   VideoComponentSizes - Size of output matrix
            %   VideoComponentOrder - How to arrange video components in binary file
            %   InterlacedVideo     - Whether data stream represents interlaced video
            %   LineOrder           - How to fill binary file
            %   SignedData          - Whether input data is signed
            %   ByteOrder           - Byte ordering as little endian or big endian
            %   PlayCount           - Number of times to play the file
            %
            %   % EXAMPLE: Read in a binary video file and play it back on the screen
            %       hbfr = vision.BinaryFileReader();
            %
            %       hvp = vision.VideoPlayer;
            %       while ~isDone(hbfr)
            %           y = step(hbfr);
            %           step(hvp, y);
            %       end
            %       release(hbfr);   % close the input file
            %       release(hvp);    % close the video display 
            %
            %   See also vision.VideoFileReader, vision.BinaryFileWriter. 
        end

        function checkAndAdjustVideoComponentOrder(in) %#ok<MANU>
        end

        function isCustomFormat(in) %#ok<MANU>
        end

        function isDoneImpl(in) %#ok<MANU>
            %isDone Returns true if System object has reached end-of-file
            %   isDone(OBJ) returns true if the BinaryFileReader System object,
            %   OBJ, has reached the end of the binary file. If PlayCount
            %   property is set to a value greater than 1, this method will
            %   return true every time the end is reached.
        end

        function isInactivePropertyImpl(in) %#ok<MANU>
        end

        function isPackedFormat(in) %#ok<MANU>
        end

    end
    methods (Abstract)
    end
    properties
        %BitstreamFormat Format of data as planar or packed
        %   Specify the data format as one of [{'Planar'} | 'Packed']. This
        %   property is applicable when the VideoFormat property is 'Custom'.
        BitstreamFormat;

        %ByteOrder Byte ordering as little endian or big endian
        %   Specify the byte ordering in the output binary file as one of
        %   [{'Little endian'} | 'Big endian']. This property is applicable
        %   when the VideoFormat property is 'Custom'.
        ByteOrder;

        %Filename Name of binary file to read from
        %  Specify the name of the binary file as a string. The full path
        %  for the file needs to be specified only if the file is not on the 
        %  MATLAB path. The default value of this property is 'vipmen.bin'.
        Filename;

        %FourCharacterCode Four Character Code video format
        %   Specify the binary file format from the available list of Four
        %   Character Code video formats. For more information on Four
        %   Character Codes, see http://www.fourcc.org. This property is
        %   applicable when the VideoFormat property is 'Four character codes'.
        FourCharacterCode;

        %InterlacedVideo Whether data stream represents interlaced video
        %   Set this property to true if the video stream represents interlaced
        %   video data. This property is applicable when the VideoFormat
        %   property is 'Custom'. The default value of this property is false.
        InterlacedVideo;

        %LineOrder How to fill binary file
        %   Specify how to fill the binary file as one of [{'Top line first'} |
        %   'Bottom line first']. If this property is set to 'Top line first',
        %   the System object first fills the binary file with the first row of
        %   the video frame. If it is set to 'Bottom line first', the System
        %   object first fills the binary file with the last row of the video
        %   frame.
        LineOrder;

        %OutputSize Size of output matrix
        %   Specify the size of the output matrix. This property is applicable
        %   when the BitstreamFormat property is 'Packed'.
        OutputSize;

        %PlayCount Number of times to play the file
        %   Specify the number of times to play the file as a positive integer
        %   or inf. The default value of this property is 1.
        PlayCount;

        %SignedData Whether input data is signed
        %   Set this property to true if the input data is signed. This
        %   property is applicable when the VideoFormat property is 'Custom'.
        %   The default value of this property is false.
        SignedData;

        %VideoComponentBits Bit size of video components
        %   Specify the bit sizes of video components as an integer valued
        %   vector of length N, where N is the value of the VideoComponentCount
        %   property. This property is applicable when the VideoFormat property
        %   is 'Custom'. The default value of this property is [8 8 8].
        VideoComponentBits;

        %VideoComponentCount Number of video components in video stream
        %   Specify the number of video components in the video stream as 1, 2,
        %   3 or 4. This number corresponds to the number of video component
        %   outputs. This property is applicable when the VideoFormat property
        %   is 'Custom'. The default value of this property is 3.
        VideoComponentCount;

        %VideoComponentOrder How to arrange video components in binary file
        %   Specify how to arrange the components in the binary file. This
        %   property must be set to a vector of length N. If the
        %   BitstreamFormat property is set to 'Planar', N must be equal to the
        %   value of the VideoComponentCount property; otherwise, N must be
        %   equal to or greater than the value of the VideoComponentCount
        %   property. This property is applicable when the VideoFormat property
        %   is 'Custom'. The default value of this property is [1 2 3].
        VideoComponentOrder;

        %VideoComponentSizes Size of output matrix
        %   Specify the size of the output matrix. This property must be set to
        %   an N-by-2 array, where N is the value of the VideoComponentCount
        %   property. Each row of the matrix corresponds to the size of that
        %   video component, with the first element denoting the number of rows
        %   and the second element denoting the number of columns. This
        %   property is applicable when the VideoFormat property is 'Custom'
        %   and the BitstreamFormat property is 'Planar'. The default value of
        %   this property is [120 160; 60 80; 60 80].
        VideoComponentSizes;

        %VideoFormat Format of binary video data
        %   Specify the format of the binary video data as one of [{'Four
        %   character codes'} | 'Custom'].
        VideoFormat;

    end
end
