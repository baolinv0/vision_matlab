function h_ShapeInserter = createShapeInserter_cg( ...
    inDTypeIdx, shapeIdx, fillShape, smoothEdges, rgb, position, color)
   
% This function creates System Object (TM) based on input arguments

% Shape inserter object needs to be created for the following
% parameters:
% input data type: double,single,uint8,uint16,int16 (5 options)
% shape: Rectangle, Line, Polygon, Circle (4 options)
% Fill: yes, no (2 options)
% Anti-aliasing: yes, no (2 options)

% Naming of persistent variables:
% h(inDTypeIdx=1:5)(shapeIdx=1:4)(fillIdx=1:2)(smoothIdx=1:2)

%#codegen
%#ok<*EMCLS>
%#ok<*EMCA>

% rectangle
persistent h1111  h2111  h3111  h4111  h5111
persistent h1121  h2121  h3121  h4121  h5121
% line
persistent h1211  h2211  h3211  h4211  h5211
persistent h1212  h2212  h3212  h4212  h5212
% circle
persistent h1311  h2311  h3311  h4311  h5311
persistent h1321  h2321  h3321  h4321  h5321
%
persistent h1312  h2312  h3312  h4312  h5312
persistent h1322  h2322  h3322  h4322  h5322
% polyline
persistent h1411  h2411  h3411  h4411  h5411
persistent h1421  h2421  h3421  h4421  h5421
%
persistent h1412  h2412  h3412  h4412  h5412
persistent h1422  h2422  h3422  h4422  h5422


if (fillShape)
    colorSourcePropName = 'FillColorSource';
else
    colorSourcePropName = 'BorderColorSource';
end

[IDX_RECTANGLE, IDX_CIRCLE, IDX_LINE] = deal(1,2,3);

% h(inDTypeIdx)(shapeIdx)(fillIdx)(smoothIdx)
if (shapeIdx == IDX_RECTANGLE)
  % Rectangles have no antialiasing property
  if (~fillShape)
      switch inDTypeIdx
          % h(inDTypeIdx=1:5)(shapeIdx=1)(fillIdx=1)(smoothIdx: no affect, set it 1)
          case 1 % double
              if isempty(h1111), h1111  = vision.ShapeInserter('Shape', 'Rectangles', 'Fill', fillShape, colorSourcePropName,'Input port', 'useFltptMath4IntImage', 1); h1111.setup(rgb, position, color); end
              h_ShapeInserter = h1111;
          case 2 % single
              if isempty(h2111), h2111  = vision.ShapeInserter('Shape', 'Rectangles', 'Fill', fillShape, colorSourcePropName,'Input port', 'useFltptMath4IntImage', 1); h2111.setup(rgb, position, color); end
              h_ShapeInserter = h2111;
          case 3 % uint8
              if isempty(h3111), h3111  = vision.ShapeInserter('Shape', 'Rectangles', 'Fill', fillShape, colorSourcePropName,'Input port', 'useFltptMath4IntImage', 1); h3111.setup(rgb, position, color); end
              h_ShapeInserter = h3111;
          case 4 % uint16
              if isempty(h4111), h4111  = vision.ShapeInserter('Shape', 'Rectangles', 'Fill', fillShape, colorSourcePropName,'Input port', 'useFltptMath4IntImage', 1); h4111.setup(rgb, position, color); end
              h_ShapeInserter = h4111;
          case 5 % int16
              if isempty(h5111), h5111  = vision.ShapeInserter('Shape', 'Rectangles', 'Fill', fillShape, colorSourcePropName,'Input port', 'useFltptMath4IntImage', 1); h5111.setup(rgb, position, color); end
              h_ShapeInserter = h5111;
      end
  else
      switch inDTypeIdx
          % h(inDTypeIdx=1:5)(shapeIdx=1)(fillIdx=2)(smoothIdx: no affect, set it 1)
          case 1 % double
              if isempty(h1121), h1121  = vision.ShapeInserter('Shape', 'Rectangles', 'Fill', fillShape, colorSourcePropName,'Input port', 'useFltptMath4IntImage', 1); h1121.setup(rgb, position, color); end
              h_ShapeInserter = h1121;
          case 2 % single
              if isempty(h2121), h2121  = vision.ShapeInserter('Shape', 'Rectangles', 'Fill', fillShape, colorSourcePropName,'Input port', 'useFltptMath4IntImage', 1); h2121.setup(rgb, position, color); end
              h_ShapeInserter = h2121;
          case 3 % uint8
              if isempty(h3121), h3121  = vision.ShapeInserter('Shape', 'Rectangles', 'Fill', fillShape, colorSourcePropName,'Input port', 'useFltptMath4IntImage', 1); h3121.setup(rgb, position, color); end
              h_ShapeInserter = h3121;
          case 4 % uint16
              if isempty(h4121), h4121  = vision.ShapeInserter('Shape', 'Rectangles', 'Fill', fillShape, colorSourcePropName,'Input port', 'useFltptMath4IntImage', 1); h4121.setup(rgb, position, color); end
              h_ShapeInserter = h4121;
          case 5 % int16
              if isempty(h5121), h5121  = vision.ShapeInserter('Shape', 'Rectangles', 'Fill', fillShape, colorSourcePropName,'Input port', 'useFltptMath4IntImage', 1); h5121.setup(rgb, position, color); end
              h_ShapeInserter = h5121;
      end          
  end
elseif (shapeIdx == IDX_LINE)
  % Lines have no fillShape property
  % Lines have antialiasing (smoothEdges) property
  if (~smoothEdges)
      switch inDTypeIdx
          % h(inDTypeIdx=1:5)(shapeIdx=2)(fillIdx: no affect, set it 1)(smoothIdx=1)
          case 1 % double
              if isempty(h1211), h1211  = vision.ShapeInserter('Shape', 'Lines', 'BorderColorSource','Input port','Antialiasing',smoothEdges, 'useFltptMath4IntImage', 1); h1211.setup(rgb, position, color); end
              h_ShapeInserter = h1211;
          case 2 % single
              if isempty(h2211), h2211  = vision.ShapeInserter('Shape', 'Lines', 'BorderColorSource','Input port','Antialiasing',smoothEdges, 'useFltptMath4IntImage', 1); h2211.setup(rgb, position, color); end
              h_ShapeInserter = h2211;
          case 3 % uint8
              if isempty(h3211), h3211  = vision.ShapeInserter('Shape', 'Lines', 'BorderColorSource','Input port','Antialiasing',smoothEdges, 'useFltptMath4IntImage', 1); h3211.setup(rgb, position, color); end
              h_ShapeInserter = h3211;
          case 4 % uint16
              if isempty(h4211), h4211  = vision.ShapeInserter('Shape', 'Lines', 'BorderColorSource','Input port','Antialiasing',smoothEdges, 'useFltptMath4IntImage', 1); h4211.setup(rgb, position, color); end
              h_ShapeInserter = h4211;
          case 5 % int16
              if isempty(h5211), h5211  = vision.ShapeInserter('Shape', 'Lines', 'BorderColorSource','Input port','Antialiasing',smoothEdges, 'useFltptMath4IntImage', 1); h5211.setup(rgb, position, color); end
              h_ShapeInserter = h5211;
      end
  else
      switch inDTypeIdx
          % h(inDTypeIdx=1:5)(shapeIdx=2)(fillIdx: no affect, set it 1)(smoothIdx=2)
          case 1 % double
              if isempty(h1212), h1212  = vision.ShapeInserter('Shape', 'Lines', 'BorderColorSource','Input port','Antialiasing',smoothEdges, 'useFltptMath4IntImage', 1); h1212.setup(rgb, position, color); end
              h_ShapeInserter = h1212;
          case 2 % single
              if isempty(h2212), h2212  = vision.ShapeInserter('Shape', 'Lines', 'BorderColorSource','Input port','Antialiasing',smoothEdges, 'useFltptMath4IntImage', 1); h2212.setup(rgb, position, color); end
              h_ShapeInserter = h2212;
          case 3 % uint8
              if isempty(h3212), h3212  = vision.ShapeInserter('Shape', 'Lines', 'BorderColorSource','Input port','Antialiasing',smoothEdges, 'useFltptMath4IntImage', 1); h3212.setup(rgb, position, color); end
              h_ShapeInserter = h3212;
          case 4 % uint16
              if isempty(h4212), h4212  = vision.ShapeInserter('Shape', 'Lines', 'BorderColorSource','Input port','Antialiasing',smoothEdges, 'useFltptMath4IntImage', 1); h4212.setup(rgb, position, color); end
              h_ShapeInserter = h4212;
          case 5 % int16
              if isempty(h5212), h5212  = vision.ShapeInserter('Shape', 'Lines', 'BorderColorSource','Input port','Antialiasing',smoothEdges, 'useFltptMath4IntImage', 1); h5212.setup(rgb, position, color); end
              h_ShapeInserter = h5212;
      end         
  end       
elseif (shapeIdx == IDX_CIRCLE)
  % Rectangles have no antialiasing property
  if (~smoothEdges)
      if (~fillShape)
          switch inDTypeIdx
              % h(inDTypeIdx=1:5)(shapeIdx=3)(fillIdx=1)(smoothIdx=1)
              case 1 % double
                  if isempty(h1311), h1311  = vision.ShapeInserter('Shape', 'Circles', 'Fill', fillShape, colorSourcePropName,'Input port', 'Antialiasing', smoothEdges, 'useFltptMath4IntImage', 1); h1311.setup(rgb, position, color); end
                  h_ShapeInserter = h1311;
              case 2 % single
                  if isempty(h2311), h2311  = vision.ShapeInserter('Shape', 'Circles', 'Fill', fillShape, colorSourcePropName,'Input port', 'Antialiasing', smoothEdges, 'useFltptMath4IntImage', 1); h2311.setup(rgb, position, color); end
                  h_ShapeInserter = h2311;
              case 3 % uint8
                  if isempty(h3311), h3311  = vision.ShapeInserter('Shape', 'Circles', 'Fill', fillShape, colorSourcePropName,'Input port', 'Antialiasing', smoothEdges, 'useFltptMath4IntImage', 1); h3311.setup(rgb, position, color); end
                  h_ShapeInserter = h3311;
              case 4 % uint16
                  if isempty(h4311), h4311  = vision.ShapeInserter('Shape', 'Circles', 'Fill', fillShape, colorSourcePropName,'Input port', 'Antialiasing', smoothEdges, 'useFltptMath4IntImage', 1); h4311.setup(rgb, position, color); end
                  h_ShapeInserter = h4311;
              case 5 % int16
                  if isempty(h5311), h5311  = vision.ShapeInserter('Shape', 'Circles', 'Fill', fillShape, colorSourcePropName,'Input port', 'Antialiasing', smoothEdges, 'useFltptMath4IntImage', 1); h5311.setup(rgb, position, color); end
                  h_ShapeInserter = h5311;
          end
      else
          switch inDTypeIdx
              % h(inDTypeIdx=1:5)(shapeIdx=3)(fillIdx=2)(smoothIdx=1)
              case 1 % double
                  if isempty(h1321), h1321  = vision.ShapeInserter('Shape', 'Circles', 'Fill', fillShape, colorSourcePropName,'Input port', 'Antialiasing', smoothEdges, 'useFltptMath4IntImage', 1); h1321.setup(rgb, position, color); end
                  h_ShapeInserter = h1321;
              case 2 % single
                  if isempty(h2321), h2321  = vision.ShapeInserter('Shape', 'Circles', 'Fill', fillShape, colorSourcePropName,'Input port', 'Antialiasing', smoothEdges, 'useFltptMath4IntImage', 1); h2321.setup(rgb, position, color); end
                  h_ShapeInserter = h2321;
              case 3 % uint8
                  if isempty(h3321), h3321  = vision.ShapeInserter('Shape', 'Circles', 'Fill', fillShape, colorSourcePropName,'Input port', 'Antialiasing', smoothEdges, 'useFltptMath4IntImage', 1); h3321.setup(rgb, position, color); end
                  h_ShapeInserter = h3321;
              case 4 % uint16
                  if isempty(h4321), h4321  = vision.ShapeInserter('Shape', 'Circles', 'Fill', fillShape, colorSourcePropName,'Input port', 'Antialiasing', smoothEdges, 'useFltptMath4IntImage', 1); h4321.setup(rgb, position, color); end
                  h_ShapeInserter = h4321;
              case 5 % int16
                  if isempty(h5321), h5321  = vision.ShapeInserter('Shape', 'Circles', 'Fill', fillShape, colorSourcePropName,'Input port', 'Antialiasing', smoothEdges, 'useFltptMath4IntImage', 1); h5321.setup(rgb, position, color); end
                  h_ShapeInserter = h5321;
          end    
      end
  else
      if (~fillShape)
          switch inDTypeIdx
              % h(inDTypeIdx=1:5)(shapeIdx=3)(fillIdx=1)(smoothIdx=2)
              case 1 % double
                  if isempty(h1312), h1312  = vision.ShapeInserter('Shape', 'Circles', 'Fill', fillShape, colorSourcePropName,'Input port', 'Antialiasing', smoothEdges, 'useFltptMath4IntImage', 1); h1312.setup(rgb, position, color); end
                  h_ShapeInserter = h1312;
              case 2 % single
                  if isempty(h2312), h2312  = vision.ShapeInserter('Shape', 'Circles', 'Fill', fillShape, colorSourcePropName,'Input port', 'Antialiasing', smoothEdges, 'useFltptMath4IntImage', 1); h2312.setup(rgb, position, color); end
                  h_ShapeInserter = h2312;
              case 3 % uint8
                  if isempty(h3312), h3312  = vision.ShapeInserter('Shape', 'Circles', 'Fill', fillShape, colorSourcePropName,'Input port', 'Antialiasing', smoothEdges, 'useFltptMath4IntImage', 1); h3312.setup(rgb, position, color); end
                  h_ShapeInserter = h3312;
              case 4 % uint16
                  if isempty(h4312), h4312  = vision.ShapeInserter('Shape', 'Circles', 'Fill', fillShape, colorSourcePropName,'Input port', 'Antialiasing', smoothEdges, 'useFltptMath4IntImage', 1); h4312.setup(rgb, position, color); end
                  h_ShapeInserter = h4312;
              case 5 % int16
                  if isempty(h5312), h5312  = vision.ShapeInserter('Shape', 'Circles', 'Fill', fillShape, colorSourcePropName,'Input port', 'Antialiasing', smoothEdges, 'useFltptMath4IntImage', 1); h5312.setup(rgb, position, color); end
                  h_ShapeInserter = h5312;
          end
      else
          switch inDTypeIdx
              % h(inDTypeIdx=1:5)(shapeIdx=3)(fillIdx=2)(smoothIdx=2)
              case 1 % double
                  if isempty(h1322), h1322  = vision.ShapeInserter('Shape', 'Circles', 'Fill', fillShape, colorSourcePropName,'Input port', 'Antialiasing', smoothEdges, 'useFltptMath4IntImage', 1); h1322.setup(rgb, position, color); end
                  h_ShapeInserter = h1322;
              case 2 % single
                  if isempty(h2322), h2322  = vision.ShapeInserter('Shape', 'Circles', 'Fill', fillShape, colorSourcePropName,'Input port', 'Antialiasing', smoothEdges, 'useFltptMath4IntImage', 1); h2322.setup(rgb, position, color); end
                  h_ShapeInserter = h2322;
              case 3 % uint8
                  if isempty(h3322), h3322  = vision.ShapeInserter('Shape', 'Circles', 'Fill', fillShape, colorSourcePropName,'Input port', 'Antialiasing', smoothEdges, 'useFltptMath4IntImage', 1); h3322.setup(rgb, position, color); end
                  h_ShapeInserter = h3322;
              case 4 % uint16
                  if isempty(h4322), h4322  = vision.ShapeInserter('Shape', 'Circles', 'Fill', fillShape, colorSourcePropName,'Input port', 'Antialiasing', smoothEdges, 'useFltptMath4IntImage', 1); h4322.setup(rgb, position, color); end
                  h_ShapeInserter = h4322;
              case 5 % int16
                  if isempty(h5322), h5322  = vision.ShapeInserter('Shape', 'Circles', 'Fill', fillShape, colorSourcePropName,'Input port', 'Antialiasing', smoothEdges, 'useFltptMath4IntImage', 1); h5322.setup(rgb, position, color); end
                  h_ShapeInserter = h5322;
          end    
      end          
  end
else % if (shapeIdx == IDX_POLYGON)
  % Rectangles have no antialiasing property
  if (~smoothEdges)
      if (~fillShape)
          switch inDTypeIdx
              % h(inDTypeIdx=1:5)(shapeIdx=4)(fillIdx=1)(smoothIdx=1)
              case 1 % double
                  if isempty(h1411), h1411  = vision.ShapeInserter('Shape', 'Polygons', 'Fill', fillShape, colorSourcePropName,'Input port', 'Antialiasing', smoothEdges, 'useFltptMath4IntImage', 1); h1411.setup(rgb, position, color); end
                  h_ShapeInserter = h1411;
              case 2 % single
                  if isempty(h2411), h2411  = vision.ShapeInserter('Shape', 'Polygons', 'Fill', fillShape, colorSourcePropName,'Input port', 'Antialiasing', smoothEdges, 'useFltptMath4IntImage', 1); h2411.setup(rgb, position, color); end
                  h_ShapeInserter = h2411;
              case 3 % uint8
                  if isempty(h3411), h3411  = vision.ShapeInserter('Shape', 'Polygons', 'Fill', fillShape, colorSourcePropName,'Input port', 'Antialiasing', smoothEdges, 'useFltptMath4IntImage', 1); h3411.setup(rgb, position, color); end
                  h_ShapeInserter = h3411;
              case 4 % uint16
                  if isempty(h4411), h4411  = vision.ShapeInserter('Shape', 'Polygons', 'Fill', fillShape, colorSourcePropName,'Input port', 'Antialiasing', smoothEdges, 'useFltptMath4IntImage', 1); h4411.setup(rgb, position, color); end
                  h_ShapeInserter = h4411;
              case 5 % int16
                  if isempty(h5411), h5411  = vision.ShapeInserter('Shape', 'Polygons', 'Fill', fillShape, colorSourcePropName,'Input port', 'Antialiasing', smoothEdges, 'useFltptMath4IntImage', 1); h5411.setup(rgb, position, color); end
                  h_ShapeInserter = h5411;
          end
      else
          switch inDTypeIdx
              % h(inDTypeIdx=1:5)(shapeIdx=4)(fillIdx=2)(smoothIdx=1)
              case 1 % double
                  if isempty(h1421), h1421  = vision.ShapeInserter('Shape', 'Polygons', 'Fill', fillShape, colorSourcePropName,'Input port', 'Antialiasing', smoothEdges, 'useFltptMath4IntImage', 1); h1421.setup(rgb, position, color); end
                  h_ShapeInserter = h1421;
              case 2 % single
                  if isempty(h2421), h2421  = vision.ShapeInserter('Shape', 'Polygons', 'Fill', fillShape, colorSourcePropName,'Input port', 'Antialiasing', smoothEdges, 'useFltptMath4IntImage', 1); h2421.setup(rgb, position, color); end
                  h_ShapeInserter = h2421;
              case 3 % uint8
                  if isempty(h3421), h3421  = vision.ShapeInserter('Shape', 'Polygons', 'Fill', fillShape, colorSourcePropName,'Input port', 'Antialiasing', smoothEdges, 'useFltptMath4IntImage', 1); h3421.setup(rgb, position, color); end
                  h_ShapeInserter = h3421;
              case 4 % uint16
                  if isempty(h4421), h4421  = vision.ShapeInserter('Shape', 'Polygons', 'Fill', fillShape, colorSourcePropName,'Input port', 'Antialiasing', smoothEdges, 'useFltptMath4IntImage', 1); h4421.setup(rgb, position, color); end
                  h_ShapeInserter = h4421;
              case 5 % int16
                  if isempty(h5421), h5421  = vision.ShapeInserter('Shape', 'Polygons', 'Fill', fillShape, colorSourcePropName,'Input port', 'Antialiasing', smoothEdges, 'useFltptMath4IntImage', 1); h5421.setup(rgb, position, color); end
                  h_ShapeInserter = h5421;
          end    
      end
  else
      if (~fillShape)
          switch inDTypeIdx
              % h(inDTypeIdx=1:5)(shapeIdx=4)(fillIdx=1)(smoothIdx=2)
              case 1 % double
                  if isempty(h1412), h1412  = vision.ShapeInserter('Shape', 'Polygons', 'Fill', fillShape, colorSourcePropName,'Input port', 'Antialiasing', smoothEdges, 'useFltptMath4IntImage', 1); h1412.setup(rgb, position, color); end
                  h_ShapeInserter = h1412;
              case 2 % single
                  if isempty(h2412), h2412  = vision.ShapeInserter('Shape', 'Polygons', 'Fill', fillShape, colorSourcePropName,'Input port', 'Antialiasing', smoothEdges, 'useFltptMath4IntImage', 1); h2412.setup(rgb, position, color); end
                  h_ShapeInserter = h2412;
              case 3 % uint8
                  if isempty(h3412), h3412  = vision.ShapeInserter('Shape', 'Polygons', 'Fill', fillShape, colorSourcePropName,'Input port', 'Antialiasing', smoothEdges, 'useFltptMath4IntImage', 1); h3412.setup(rgb, position, color); end
                  h_ShapeInserter = h3412;
              case 4 % uint16
                  if isempty(h4412), h4412  = vision.ShapeInserter('Shape', 'Polygons', 'Fill', fillShape, colorSourcePropName,'Input port', 'Antialiasing', smoothEdges, 'useFltptMath4IntImage', 1); h4412.setup(rgb, position, color); end
                  h_ShapeInserter = h4412;
              case 5 % int16
                  if isempty(h5412), h5412  = vision.ShapeInserter('Shape', 'Polygons', 'Fill', fillShape, colorSourcePropName,'Input port', 'Antialiasing', smoothEdges, 'useFltptMath4IntImage', 1); h5412.setup(rgb, position, color); end
                  h_ShapeInserter = h5412;
          end
      else
          switch inDTypeIdx
              % h(inDTypeIdx=1:5)(shapeIdx=4)(fillIdx=2)(smoothIdx=2)
              case 1 % double
                  if isempty(h1422), h1422  = vision.ShapeInserter('Shape', 'Polygons', 'Fill', fillShape, colorSourcePropName,'Input port', 'Antialiasing', smoothEdges, 'useFltptMath4IntImage', 1); h1422.setup(rgb, position, color); end
                  h_ShapeInserter = h1422;
              case 2 % single
                  if isempty(h2422), h2422  = vision.ShapeInserter('Shape', 'Polygons', 'Fill', fillShape, colorSourcePropName,'Input port', 'Antialiasing', smoothEdges, 'useFltptMath4IntImage', 1); h2422.setup(rgb, position, color); end
                  h_ShapeInserter = h2422;
              case 3 % uint8
                  if isempty(h3422), h3422  = vision.ShapeInserter('Shape', 'Polygons', 'Fill', fillShape, colorSourcePropName,'Input port', 'Antialiasing', smoothEdges, 'useFltptMath4IntImage', 1); h3422.setup(rgb, position, color); end
                  h_ShapeInserter = h3422;
              case 4 % uint16
                  if isempty(h4422), h4422  = vision.ShapeInserter('Shape', 'Polygons', 'Fill', fillShape, colorSourcePropName,'Input port', 'Antialiasing', smoothEdges, 'useFltptMath4IntImage', 1); h4422.setup(rgb, position, color); end
                  h_ShapeInserter = h4422;
              case 5 % int16
                  if isempty(h5422), h5422  = vision.ShapeInserter('Shape', 'Polygons', 'Fill', fillShape, colorSourcePropName,'Input port', 'Antialiasing', smoothEdges, 'useFltptMath4IntImage', 1); h5422.setup(rgb, position, color); end
                  h_ShapeInserter = h5422;
          end    
      end          
  end
end
