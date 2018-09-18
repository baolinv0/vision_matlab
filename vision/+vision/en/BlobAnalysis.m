classdef BlobAnalysis< matlab.system.SFunSystem
%BlobAnalysis Properties of connected regions
%   HBLOB = vision.BlobAnalysis returns a blob analysis System object,
%   HBLOB, used to compute statistics for connected regions in a binary
%   image.
%
%   HBLOB = vision.BlobAnalysis('PropertyName', PropertyValue, ...) returns
%   a blob analysis object, HBLOB, with each specified property set to the
%   specified value.
%
%   Step method syntax:
%
%   The step method computes and returns statistics of the input binary
%   image depending on the property values specified. Each option is
%   described individually below. The different options can be used
%   simultaneously. The order of the returned values when there are
%   multiple outputs are in the order they are described.
%
%   AREA = step(HBLOB, BW) computes the AREA of the blobs found in input
%   binary image BW when the AreaOutputPort property is set to true.
%
%   [..., CENTROID] = step(HBLOB, BW) computes the CENTROID of the blobs
%   found in input binary image BW when the CentroidOutputPort property is
%   set to true.
%
%   [..., BBOX] = step(HBLOB, BW) computes the bounding box BBOX of the
%   blobs found in input binary image BW when the BoundingBoxOutputPort
%   property is set to true.
%
%   [..., MAJORAXIS] = step(HBLOB, BW) computes the major axis length
%   MAJORAXIS of the blobs found in input binary image BW when the
%   MajorAxisLengthOutputPort property is set to true.
%
%   [..., MINORAXIS] = step(HBLOB, BW) computes the minor axis length
%   MINORAXIS of the blobs found in input binary image BW when the
%   MinorAxisLengthOutputPort property is set to true.
%
%   [..., ORIENTATION] = step(HBLOB, BW) computes the ORIENTATION of the
%   blobs found in input binary image BW when the OrientationOutputPort
%   property is set to true.
%
%   [..., ECCENTRICITY] = step(HBLOB, BW) computes the ECCENTRICITY of the
%   blobs found in input binary image BW when the EccentricityOutputPort
%   property is set to true.
%
%   [..., EQDIASQ] = step(HBLOB, BW) computes the equivalent diameter
%   squared EQDIASQ of the blobs found in input binary image BW when the
%   EquivalentDiameterSquaredOutputPort property is set to true.
%
%   [..., EXTENT] = step(HBLOB, BW) computes the EXTENT of the blobs found
%   in input binary image BW when the ExtentOutputPort property is set to
%   true.
%
%   [..., PERIMETER] = step(HBLOB, BW) computes the PERIMETER of the blobs
%   found in input binary image BW when the PerimeterOutputPort property is
%   set to true.
%
%   [..., LABEL] = step(HBLOB, BW) returns a label matrix LABEL of the
%   blobs found in input binary image BW when the LabelMatrixOutputPort
%   property is set to true.
%
%   Example usage when multiple statistics are calculated: 
%   [AREA, CENTROID, BBOX] = step(HBLOB, BW) returns the area, centroid and
%   the bounding box of the blobs, when the AreaOutputPort,
%   CentroidOutputPort and BoundingBoxOutputPort properties are set to
%   true.
%
%   System objects may be called directly like a function instead of using
%   the step method. For example, y = step(obj, x) and y = obj(x) are
%   equivalent.
%
%   BlobAnalysis methods:
%
%   step     - See above description for use of this method
%   release  - Allow property value and input characteristics changes
%   clone    - Create blob analysis object with same property values
%   isLocked - Locked status (logical)
%
%   BlobAnalysis properties:
%
%   AreaOutputPort                      - Enables blob area output
%   CentroidOutputPort                  - Enables coordinates of blob
%                                         centroids output
%   BoundingBoxOutputPort               - Enables coordinates of bounding
%                                         boxes output
%   MajorAxisLengthOutputPort           - Enables output vector whose
%                                         values represent lengths of
%                                         ellipses' major axes
%   MinorAxisLengthOutputPort           - Enables output vector whose
%                                         values represent lengths of the
%                                         ellipses' minor axes
%   OrientationOutputPort               - Enables output vector whose
%                                         values represent angles between
%                                         ellipses' major axes and x-axis
%   EccentricityOutputPort              - Enables output vector whose
%                                         values represent ellipses'
%                                         eccentricities
%   EquivalentDiameterSquaredOutputPort - Enables output vector whose
%                                         values represent equivalent
%                                         diameters squared
%   ExtentOutputPort                    - Enables output vector whose
%                                         values represent results of
%                                         dividing blob areas by bounding
%                                         box areas
%   PerimeterOutputPort                 - Enables output vector whose
%                                         values represent estimates of
%                                         blob perimeter lengths
%   OutputDataType                      - Output data type of statistics
%   Connectivity                        - Which pixels are connected to
%                                         each other
%   LabelMatrixOutputPort               - Enables label matrix output
%   MaximumCount                        - Maximum number of labeled regions
%                                         in each input image
%   MinimumBlobArea                     - Minimum blob area in pixels
%   MaximumBlobArea                     - Maximum blob area in pixels
%   ExcludeBorderBlobs                  - Exclude blobs that contain at
%                                         least one border pixel
%
%   This System object supports fixed-point operations when the
%   OutputDataType property is set to 'Fixed point'. For more information,
%   type vision.BlobAnalysis.helpFixedPoint.
%
%   % EXAMPLE: Find the centroid of a blob.
%      hblob = vision.BlobAnalysis;
%      hblob.AreaOutputPort = false;
%      hblob.BoundingBoxOutputPort = false;
%      img = logical([0 0 0 0 0 0; ...
%                     0 1 1 1 1 0; ...
%                     0 1 1 1 1 0; ...
%                     0 1 1 1 1 0; ...
%                     0 0 0 0 0 0]);
%      centroid = step(hblob, img)   % [x y] coordinates of the centroid
%
%   See also vision.ConnectedComponentLabeler, vision.BlobAnalysis.helpFixedPoint.

 
%   Copyright 2004-2016 The MathWorks, Inc.

    methods
        function out=BlobAnalysis
            %BlobAnalysis Properties of connected regions
            %   HBLOB = vision.BlobAnalysis returns a blob analysis System object,
            %   HBLOB, used to compute statistics for connected regions in a binary
            %   image.
            %
            %   HBLOB = vision.BlobAnalysis('PropertyName', PropertyValue, ...) returns
            %   a blob analysis object, HBLOB, with each specified property set to the
            %   specified value.
            %
            %   Step method syntax:
            %
            %   The step method computes and returns statistics of the input binary
            %   image depending on the property values specified. Each option is
            %   described individually below. The different options can be used
            %   simultaneously. The order of the returned values when there are
            %   multiple outputs are in the order they are described.
            %
            %   AREA = step(HBLOB, BW) computes the AREA of the blobs found in input
            %   binary image BW when the AreaOutputPort property is set to true.
            %
            %   [..., CENTROID] = step(HBLOB, BW) computes the CENTROID of the blobs
            %   found in input binary image BW when the CentroidOutputPort property is
            %   set to true.
            %
            %   [..., BBOX] = step(HBLOB, BW) computes the bounding box BBOX of the
            %   blobs found in input binary image BW when the BoundingBoxOutputPort
            %   property is set to true.
            %
            %   [..., MAJORAXIS] = step(HBLOB, BW) computes the major axis length
            %   MAJORAXIS of the blobs found in input binary image BW when the
            %   MajorAxisLengthOutputPort property is set to true.
            %
            %   [..., MINORAXIS] = step(HBLOB, BW) computes the minor axis length
            %   MINORAXIS of the blobs found in input binary image BW when the
            %   MinorAxisLengthOutputPort property is set to true.
            %
            %   [..., ORIENTATION] = step(HBLOB, BW) computes the ORIENTATION of the
            %   blobs found in input binary image BW when the OrientationOutputPort
            %   property is set to true.
            %
            %   [..., ECCENTRICITY] = step(HBLOB, BW) computes the ECCENTRICITY of the
            %   blobs found in input binary image BW when the EccentricityOutputPort
            %   property is set to true.
            %
            %   [..., EQDIASQ] = step(HBLOB, BW) computes the equivalent diameter
            %   squared EQDIASQ of the blobs found in input binary image BW when the
            %   EquivalentDiameterSquaredOutputPort property is set to true.
            %
            %   [..., EXTENT] = step(HBLOB, BW) computes the EXTENT of the blobs found
            %   in input binary image BW when the ExtentOutputPort property is set to
            %   true.
            %
            %   [..., PERIMETER] = step(HBLOB, BW) computes the PERIMETER of the blobs
            %   found in input binary image BW when the PerimeterOutputPort property is
            %   set to true.
            %
            %   [..., LABEL] = step(HBLOB, BW) returns a label matrix LABEL of the
            %   blobs found in input binary image BW when the LabelMatrixOutputPort
            %   property is set to true.
            %
            %   Example usage when multiple statistics are calculated: 
            %   [AREA, CENTROID, BBOX] = step(HBLOB, BW) returns the area, centroid and
            %   the bounding box of the blobs, when the AreaOutputPort,
            %   CentroidOutputPort and BoundingBoxOutputPort properties are set to
            %   true.
            %
            %   System objects may be called directly like a function instead of using
            %   the step method. For example, y = step(obj, x) and y = obj(x) are
            %   equivalent.
            %
            %   BlobAnalysis methods:
            %
            %   step     - See above description for use of this method
            %   release  - Allow property value and input characteristics changes
            %   clone    - Create blob analysis object with same property values
            %   isLocked - Locked status (logical)
            %
            %   BlobAnalysis properties:
            %
            %   AreaOutputPort                      - Enables blob area output
            %   CentroidOutputPort                  - Enables coordinates of blob
            %                                         centroids output
            %   BoundingBoxOutputPort               - Enables coordinates of bounding
            %                                         boxes output
            %   MajorAxisLengthOutputPort           - Enables output vector whose
            %                                         values represent lengths of
            %                                         ellipses' major axes
            %   MinorAxisLengthOutputPort           - Enables output vector whose
            %                                         values represent lengths of the
            %                                         ellipses' minor axes
            %   OrientationOutputPort               - Enables output vector whose
            %                                         values represent angles between
            %                                         ellipses' major axes and x-axis
            %   EccentricityOutputPort              - Enables output vector whose
            %                                         values represent ellipses'
            %                                         eccentricities
            %   EquivalentDiameterSquaredOutputPort - Enables output vector whose
            %                                         values represent equivalent
            %                                         diameters squared
            %   ExtentOutputPort                    - Enables output vector whose
            %                                         values represent results of
            %                                         dividing blob areas by bounding
            %                                         box areas
            %   PerimeterOutputPort                 - Enables output vector whose
            %                                         values represent estimates of
            %                                         blob perimeter lengths
            %   OutputDataType                      - Output data type of statistics
            %   Connectivity                        - Which pixels are connected to
            %                                         each other
            %   LabelMatrixOutputPort               - Enables label matrix output
            %   MaximumCount                        - Maximum number of labeled regions
            %                                         in each input image
            %   MinimumBlobArea                     - Minimum blob area in pixels
            %   MaximumBlobArea                     - Maximum blob area in pixels
            %   ExcludeBorderBlobs                  - Exclude blobs that contain at
            %                                         least one border pixel
            %
            %   This System object supports fixed-point operations when the
            %   OutputDataType property is set to 'Fixed point'. For more information,
            %   type vision.BlobAnalysis.helpFixedPoint.
            %
            %   % EXAMPLE: Find the centroid of a blob.
            %      hblob = vision.BlobAnalysis;
            %      hblob.AreaOutputPort = false;
            %      hblob.BoundingBoxOutputPort = false;
            %      img = logical([0 0 0 0 0 0; ...
            %                     0 1 1 1 1 0; ...
            %                     0 1 1 1 1 0; ...
            %                     0 1 1 1 1 0; ...
            %                     0 0 0 0 0 0]);
            %      centroid = step(hblob, img)   % [x y] coordinates of the centroid
            %
            %   See also vision.ConnectedComponentLabeler, vision.BlobAnalysis.helpFixedPoint.
        end

        function helpFixedPoint(in) %#ok<MANU>
            %helpFixedPoint Display vision.BlobAnalysis System object fixed-point information
            %   vision.BlobAnalysis.helpFixedPoint displays information about
            %   fixed-point properties and operations of the vision.BlobAnalysis
            %   System object.
        end

        function isInactivePropertyImpl(in) %#ok<MANU>
        end

    end
    methods (Abstract)
    end
    properties
        %AccumulatorDataType Accumulator word- and fraction-length designations
        %   This property is constant and is set to 'Custom'. This property is
        %   applicable when the OutputDataType property is 'Fixed point'.
        AccumulatorDataType;

        %AreaOutputPort Return blob area
        %   Set this property to true to output the area of the blobs. The
        %   default value of this property is true.
        AreaOutputPort;

        %BoundingBoxOutputPort Return coordinates of bounding boxes
        %   Set this property to true to output the coordinates of the bounding
        %   boxes. The default value of this property is true.
        BoundingBoxOutputPort;

        %CentroidDataType Centroid word- and fraction-length designations
        %   Specify the centroid output's fixed-point data type as one of
        %   ['Same as accumulator' | {'Custom'}]. This property is applicable
        %   when the OutputDataType property is 'Fixed point' and the
        %   CentroidOutputPort property is true.
        CentroidDataType;

        %CentroidOutputPort Return coordinates of blob centroids
        %   Set this property to true to output the coordinates of the centroid
        %   of the blobs. The default value of this property is true.
        CentroidOutputPort;

        %Connectivity Which pixels are connected to each other
        %   Specify connectivity of pixels as one of 4 or 8.
        Connectivity;

        %CustomAccumulatorDataType Accumulator word and fraction lengths
        %   Specify the accumulator fixed-point type as an auto-signed, scaled
        %   numerictype object. This property is applicable when the
        %   OutputDataType property is 'Fixed point'. The default value of this
        %   property is numerictype([],32,0).
        %
        %   See also numerictype.
        CustomAccumulatorDataType;

        %CustomCentroidDataType Centroid word and fraction lengths
        %   Specify the centroid output's fixed-point type as an auto-signed,
        %   scaled numerictype object. This property is applicable when the
        %   OutputDataType property is 'Fixed point', the CentroidDataType
        %   property is 'Custom' and the CentroidOutputPort property is true.
        %   The default value of this property is numerictype([],32,16).
        %
        %   See also numerictype.
        CustomCentroidDataType;

        %CustomEquivalentDiameterSquaredDataType Equivalent diameter squared
        %                                        word and fraction lengths 
        %   Specify the equivalent diameters squared output's fixed-point type
        %   as an auto-signed, scaled numerictype object. This property is
        %   applicable when the OutputDataType property is 'Fixed point', the
        %   EquivalentDiameterSquaredDataType property is 'Custom' and the
        %   EquivalentDiameterSquaredOutputPort property is true. The default
        %   value of this property is numerictype([],32,16).
        %
        %   See also numerictype.
        CustomEquivalentDiameterSquaredDataType;

        %CustomExtentDataType Extent word and fraction lengths
        %   Specify the extent output's fixed-point type as an auto-signed,
        %   scaled numerictype object. This property is applicable when the
        %   OutputDataType property is 'Fixed point', the ExtentDataType
        %   property is 'Custom' and the ExtentOutputPort property is true. The
        %   default value of this property is numerictype([],16,14).
        %
        %   See also numerictype.
        CustomExtentDataType;

        %CustomPerimeterDataType Perimeter word and fraction lengths
        %   Specify the perimeter output's fixed-point type as an auto-signed,
        %   scaled numerictype object. This property is applicable when the
        %   OutputDataType property is 'Fixed point', the PerimeterDataType
        %   property is 'Custom' and the PerimeterOutputPort property is true.
        %   The default value of this property is numerictype([],32,16).
        %
        %   See also numerictype.
        CustomPerimeterDataType;

        %CustomProductDataType Product word and fraction lengths
        %   Specify the product fixed-point type as an auto-signed, scaled
        %   numerictype object. This property is applicable when the
        %   OutputDataType property is 'Fixed point' and the
        %   EquivalentDiameterSquaredOutputPort property is true. The default
        %   value of this property is numerictype([],32,16).
        %
        %   See also numerictype.
        CustomProductDataType;

        %EccentricityOutputPort Return vector whose values represent ellipses'
        %                       eccentricities 
        %   Set this property to true to output a vector whose values represent
        %   the eccentricities of the ellipses that have the same second
        %   moments as the region. This property is available when the
        %   OutputDataType property is 'double' or 'single'. The default value
        %   of this property is false.
        EccentricityOutputPort;

        %EquivalentDiameterSquaredDataType Equivalent diameter squared word-
        %                                  and fraction-length designations 
        %   Specify the equivalent diameters squared output's fixed-point data
        %   type as one of ['Same as accumulator' | {'Same as product'} |
        %   'Custom']. This property is applicable when the OutputDataType
        %   property is 'Fixed point' and the
        %   EquivalentDiameterSquaredOutputPort property is true.
        EquivalentDiameterSquaredDataType;

        %EquivalentDiameterSquaredOutputPort Return vector whose values
        %                                    represent equivalent diameters
        %                                    squared 
        %   Set this property to true to output a vector whose values represent
        %   the equivalent diameters squared. The default value of this
        %   property is false.
        EquivalentDiameterSquaredOutputPort;

        %ExcludeBorderBlobs Exclude blobs that contain at least one border
        %                   pixel
        %   Set this property to true if you do not want to label blobs that
        %   contain at least one border pixel. The default value is false.
        ExcludeBorderBlobs;

        %ExtentDataType Extent word- and fraction-length designations
        %   Specify the extent output's fixed-point data type as one of ['Same
        %   as accumulator' | {'Custom'}]. This property is applicable when the
        %   OutputDataType property is 'Fixed point' and the ExtentOutputPort
        %   property is true.
        ExtentDataType;

        %ExtentOutputPort Return vector whose values represent results of
        %                 dividing blob areas by bounding box areas 
        %   Set this property to true to output a vector whose values represent
        %   the results of dividing the areas of the blobs by the area of their
        %   bounding boxes. The default value of this property is false.
        ExtentOutputPort;

        %LabelMatrixOutputPort Return label matrix
        %   Set this property to true to output the label matrix. The default
        %   value is false.
        LabelMatrixOutputPort;

        %MajorAxisLengthOutputPort Return vector whose values represent lengths
        %                          of ellipses' major axes 
        %   Set this property to true to output a vector whose values represent
        %   the lengths of the major axes of the ellipses that have the same
        %   normalized second central moments as the labeled regions. This
        %   property is available when the OutputDataType property is 'double'
        %   or 'single'. The default value of this property is false.
        MajorAxisLengthOutputPort;

        %MaximumBlobArea Maximum blob area in pixels
        %   Specify the maximum blob area in pixels. The default is
        %   intmax('uint32').  This property is tunable.
        MaximumBlobArea;

        %MaximumCount Maximum number of labeled regions in each input image
        %   Specify the maximum number of blobs in the input image as a
        %   positive scalar integer. The default value is 50.
        MaximumCount;

        %MinimumBlobArea Minimum blob area in pixels
        %   Specify the minimum blob area in pixels. The default is 0. This
        %   property is tunable.
        MinimumBlobArea;

        %MinorAxisLengthOutputPort Return vector whose values represent lengths
        %                          of ellipses' minor axes 
        %   Set this property to true to output a vector whose values represent
        %   the lengths of the minor axes of the ellipses that have the same
        %   normalized second central moments as the labeled regions. This
        %   property is available when the OutputDataType property is 'double'
        %   or 'single'. The default value of this property is false.
        MinorAxisLengthOutputPort;

        %OrientationOutputPort Return vector whose values represent angles
        %                      between ellipses' major axes and x-axis 
        %   Set this property to true to output a vector whose values represent
        %   the angles between the major axes of the ellipses and the x-axis.
        %   This property is available when the OutputDataType property is
        %   'double' or 'single'. The default value of this property is false.
        OrientationOutputPort;

        %OutputDataType Output data type of statistics
        %   Specify the data type of the output statistics as one of
        %   [{'double'} | 'single' | 'Fixed point']. Area and Bounding box
        %   outputs are always of data type int32. Major axis length, Minor
        %   axis length, Orientation and Eccentricity are not available when
        %   this property is set to 'Fixed point'.
        OutputDataType;

        %OverflowAction Overflow action for fixed-point operations
        %   Specify the overflow action as one of [{'Wrap'} | 'Saturate']. This
        %   property is applicable when the OutputDataType property is 'Fixed
        %   point'.
        OverflowAction;

        %PerimeterDataType Perimeter word- and fraction-length designations
        %   Specify the perimeter output's fixed-point data type as one of
        %   ['Same as accumulator' | {'Custom'}]. This property is applicable
        %   when the OutputDataType property is 'Fixed point' and the
        %   PerimeterOutputPort property is true.
        PerimeterDataType;

        %PerimeterOutputPort Return vector whose values represent estimates of
        %                    blob perimeter lengths 
        %   Set this property to true to output a vector whose values represent
        %   estimates of the perimeter lengths, in pixels, of each blob. The
        %   default value of this property is false.
        PerimeterOutputPort;

        %ProductDataType Product word- and fraction-length designations
        %   This property is constant and is set to 'Custom'. This property is
        %   applicable when the OutputDataType property is 'Fixed point' and
        %   the EquivalentDiameterSquaredOutputPort property is true.
        ProductDataType;

        %RoundingMethod Rounding method for fixed-point operations
        %   Specify the rounding method as one of ['Ceiling' | 'Convergent' |
        %   {'Floor'} | 'Nearest' | 'Round', |'Simplest' | 'Zero']. This
        %   property is applicable when the OutputDataType property is 'Fixed
        %   point'.
        RoundingMethod;

    end
end
