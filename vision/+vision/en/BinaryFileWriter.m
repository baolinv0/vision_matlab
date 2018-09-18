classdef BinaryFileWriter< matlab.system.SFunSystem
%BinaryFileWriter Write binary video data to files
%   -----------------------------------------------------------------------
%   The vision.BinaryFileWriter will be removed in a future release. Use
%   the vision.VideoFileWriter system Object with equivalent functionality
%   instead.
%   -----------------------------------------------------------------------
%
%   HBFW = vision.BinaryFileWriter returns a System object, HBFW, that
%   writes binary video data to a file in the specified format.
%
%   HBFW = vision.BinaryFileWriter('PropertyName', PropertyValue, ...)
%   returns a binary file writer System object, HBFW, with each specified
%   property set to the specified value.
%
%   HBFW = vision.BinaryFileWriter(FILE, 'PropertyName', PropertyValue,
%   ...) returns a binary file writer System object, HBFW, with the
%   Filename property set to FILE and other specified properties set to the
%   specified values.
%
%   Step method syntax:
%
%   step(HBFW, Y, Cb, Cr) writes one frame of video to the specified output
%   file. Y, Cb, Cr represent the luma (Y) and chroma (Cb and Cr)
%   components of a video stream. This option is available when the
%   VideoFormat property is 'Four character codes'.
%
%   step(HBFW, Y) writes video component Y to the output file when the
%   VideoFormat property is 'Custom' and the VideoComponentCount property
%   is 1.
%
%   step(HBFW, Y, Cb) writes video components Y and Cb to the output file
%   when the VideoFormat property is 'Custom' and the VideoComponentCount
%   property is 2.
%
%   step(HBFW, Y, Cb, Cr) writes video components Y, Cb and Cr to the
%   output file when the VideoFormat property is 'Custom' and the
%   VideoComponentCount property is 3.
%
%   step(HBFW, Y, Cb, Cr, Alpha) writes video components Y, Cb, Cr and
%   Alpha to the output file when the VideoFormat property is 'Custom' and
%   the VideoComponentCount property is 4.
%
%   System objects may be called directly like a function instead of using
%   the step method. For example, step(obj, x) and obj(x) are equivalent.
%
%   BinaryFileWriter methods:
%
%   step     - See above description for use of this method
%   release  - Allow property value and input characteristics changes, and
%              release binary file writer resources
%   clone    - Create binary file writer object with same property values
%   isLocked - Locked status (logical)
%
%   BinaryFileWriter properties:
%
%   Filename                 - Name of binary file to write to
%   VideoFormat              - Format of binary video data
%   FourCharacterCode        - Four Character Code video format
%   BitstreamFormat          - Format of data as planar or packed
%   VideoComponentCount      - Number of video components in video stream
%   VideoComponentBitsSource - How to specify the size of video components
%   VideoComponentBits       - Bit size of video components
%   VideoComponentOrder      - How to arrange video components in binary
%                              file
%   InterlacedVideo          - Whether data stream represents interlaced
%                              video
%   LineOrder                - How to fill binary file
%   SignedData               - Whether input data is signed
%   ByteOrder                - Byte ordering as little endian or big endian
%
%   % EXAMPLE: Write video to a binary video file
%       filename = fullfile(tempdir,'output.bin');
%       hbfr = vision.BinaryFileReader;
%       hbfw = vision.BinaryFileWriter(filename);
%       while ~isDone(hbfr)
%           [y,cb,cr] = step(hbfr);
%           step(hbfw, y, cb, cr);
%       end
%       release(hbfr); % close the input file
%       release(hbfw); % close the output file
%
%   See also vision.VideoFileWriter, vision.BinaryFileReader. 

 
%   Copyright 2008-2016 The MathWorks, Inc.

    methods
        function out=BinaryFileWriter
            %BinaryFileWriter Write binary video data to files
            %   -----------------------------------------------------------------------
            %   The vision.BinaryFileWriter will be removed in a future release. Use
            %   the vision.VideoFileWriter system Object with equivalent functionality
            %   instead.
            %   -----------------------------------------------------------------------
            %
            %   HBFW = vision.BinaryFileWriter returns a System object, HBFW, that
            %   writes binary video data to a file in the specified format.
            %
            %   HBFW = vision.BinaryFileWriter('PropertyName', PropertyValue, ...)
            %   returns a binary file writer System object, HBFW, with each specified
            %   property set to the specified value.
            %
            %   HBFW = vision.BinaryFileWriter(FILE, 'PropertyName', PropertyValue,
            %   ...) returns a binary file writer System object, HBFW, with the
            %   Filename property set to FILE and other specified properties set to the
            %   specified values.
            %
            %   Step method syntax:
            %
            %   step(HBFW, Y, Cb, Cr) writes one frame of video to the specified output
            %   file. Y, Cb, Cr represent the luma (Y) and chroma (Cb and Cr)
            %   components of a video stream. This option is available when the
            %   VideoFormat property is 'Four character codes'.
            %
            %   step(HBFW, Y) writes video component Y to the output file when the
            %   VideoFormat property is 'Custom' and the VideoComponentCount property
            %   is 1.
            %
            %   step(HBFW, Y, Cb) writes video components Y and Cb to the output file
            %   when the VideoFormat property is 'Custom' and the VideoComponentCount
            %   property is 2.
            %
            %   step(HBFW, Y, Cb, Cr) writes video components Y, Cb and Cr to the
            %   output file when the VideoFormat property is 'Custom' and the
            %   VideoComponentCount property is 3.
            %
            %   step(HBFW, Y, Cb, Cr, Alpha) writes video components Y, Cb, Cr and
            %   Alpha to the output file when the VideoFormat property is 'Custom' and
            %   the VideoComponentCount property is 4.
            %
            %   System objects may be called directly like a function instead of using
            %   the step method. For example, step(obj, x) and obj(x) are equivalent.
            %
            %   BinaryFileWriter methods:
            %
            %   step     - See above description for use of this method
            %   release  - Allow property value and input characteristics changes, and
            %              release binary file writer resources
            %   clone    - Create binary file writer object with same property values
            %   isLocked - Locked status (logical)
            %
            %   BinaryFileWriter properties:
            %
            %   Filename                 - Name of binary file to write to
            %   VideoFormat              - Format of binary video data
            %   FourCharacterCode        - Four Character Code video format
            %   BitstreamFormat          - Format of data as planar or packed
            %   VideoComponentCount      - Number of video components in video stream
            %   VideoComponentBitsSource - How to specify the size of video components
            %   VideoComponentBits       - Bit size of video components
            %   VideoComponentOrder      - How to arrange video components in binary
            %                              file
            %   InterlacedVideo          - Whether data stream represents interlaced
            %                              video
            %   LineOrder                - How to fill binary file
            %   SignedData               - Whether input data is signed
            %   ByteOrder                - Byte ordering as little endian or big endian
            %
            %   % EXAMPLE: Write video to a binary video file
            %       filename = fullfile(tempdir,'output.bin');
            %       hbfr = vision.BinaryFileReader;
            %       hbfw = vision.BinaryFileWriter(filename);
            %       while ~isDone(hbfr)
            %           [y,cb,cr] = step(hbfr);
            %           step(hbfw, y, cb, cr);
            %       end
            %       release(hbfr); % close the input file
            %       release(hbfw); % close the output file
            %
            %   See also vision.VideoFileWriter, vision.BinaryFileReader. 
        end

        function checkAndAdjustVideoComponentOrder(in) %#ok<MANU>
        end

        function isCustomFormat(in) %#ok<MANU>
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

        %Filename Name of binary file to write to
        %  Specify the name of the binary file as a string. The default value
        %  of this property is the file 'output.bin'.
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
        %   the video frame. Otherwise, the System object first fills the
        %   binary file with the last row of the video frame.
        LineOrder;

        %SignedData Whether input data is signed    
        %   Set this property to true if the input data is signed. This
        %   property is applicable when the VideoFormat property is 'Custom'.
        %   The default value of this property is false.
        SignedData;

        %VideoComponentBits Bit size of video components
        %   Specify the bit size of video components using a vector of length
        %   N, where N is the value of the VideoComponentCount property. This
        %   property is applicable when the VideoComponentBitsSource property
        %   is 'Property'. The default value of this property is [8
        %   8 8].
        VideoComponentBits;

        %VideoComponentBitsSource How to specify the size of video components
        %   Indicate how to specify the size of video components as one of
        %   [{'Auto'} | 'Property']. If this property is set to 'Auto', each
        %   component will have the same number of bits as the input data type.
        %   Otherwise, the number of bits for each video component is specified
        %   using the VideoComponentBits property. This property is applicable
        %   when the VideoFormat property is 'Custom'.
        VideoComponentBitsSource;

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

        %VideoFormat Format of binary video data
        %   Specify the format of the binary video data as one of [{'Four
        %   character codes'} | 'Custom'].
        VideoFormat;

    end
end
