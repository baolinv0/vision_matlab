function h_MarkerInserter = createMarkerInserter_cg(inDTypeIdx, markerIdx, rgb, position, color)
   
% Marker inserter object needs to be created for the following
% parameters:
% input data type: double,single,uint8,uint16,int16 (5 options)
% markers: circle, x-mark, plus, star, square (5 options)
% 
% Naming of persistent variables:
% h(inDTypeIdx=1:5)(markerIdx=1:5)

%#codegen
%#ok<*EMCLS>
%#ok<*EMCA>

% circle
persistent h11  h21  h31  h41  h51
% x-mark
persistent h12  h22  h32  h42  h52
% plus
persistent h13  h23  h33  h43  h53
% star
persistent h14  h24  h34  h44  h54
% square
persistent h15  h25  h35  h45  h55

% h(inDTypeIdx)(markerIdx)
if (markerIdx == 1) % circle
  switch inDTypeIdx
      % h(inDTypeIdx=1:5)(markerIdx=1)
      case 1 % double
          if isempty(h11), h11 = vision.MarkerInserter('Shape', 'Circle', 'BorderColorSource','Input port'); h11.setup(rgb, position, color); end
          h_MarkerInserter = h11;
      case 2 % single
          if isempty(h21), h21 = vision.MarkerInserter('Shape', 'Circle', 'BorderColorSource','Input port'); h21.setup(rgb, position, color); end
          h_MarkerInserter = h21;
      case 3 % uint8
          if isempty(h31), h31 = vision.MarkerInserter('Shape', 'Circle', 'BorderColorSource','Input port'); h31.setup(rgb, position, color); end
          h_MarkerInserter = h31;
      case 4 % uint16
          if isempty(h41), h41 = vision.MarkerInserter('Shape', 'Circle', 'BorderColorSource','Input port'); h41.setup(rgb, position, color); end
          h_MarkerInserter = h41;
      case 5 % int16
          if isempty(h51), h51 = vision.MarkerInserter('Shape', 'Circle', 'BorderColorSource','Input port'); h51.setup(rgb, position, color); end
          h_MarkerInserter = h51;
  end
elseif (markerIdx == 2) % x-mark
  switch inDTypeIdx
      % h(inDTypeIdx=1:5)(markerIdx=2)
      case 1 % double
          if isempty(h12), h12 = vision.MarkerInserter('Shape', 'X-mark', 'BorderColorSource','Input port'); h12.setup(rgb, position, color); end
          h_MarkerInserter = h12;
      case 2 % single
          if isempty(h22), h22 = vision.MarkerInserter('Shape', 'X-mark', 'BorderColorSource','Input port'); h22.setup(rgb, position, color); end
          h_MarkerInserter = h22;
      case 3 % uint8
          if isempty(h32), h32 = vision.MarkerInserter('Shape', 'X-mark', 'BorderColorSource','Input port'); h32.setup(rgb, position, color); end
          h_MarkerInserter = h32;
      case 4 % uint16
          if isempty(h42), h42 = vision.MarkerInserter('Shape', 'X-mark', 'BorderColorSource','Input port'); h42.setup(rgb, position, color); end
          h_MarkerInserter = h42;
      case 5 % int16
          if isempty(h52), h52 = vision.MarkerInserter('Shape', 'X-mark', 'BorderColorSource','Input port'); h52.setup(rgb, position, color); end
          h_MarkerInserter = h52;
  end
elseif (markerIdx == 3) % plus
  switch inDTypeIdx
      % h(inDTypeIdx=1:5)(markerIdx=3)
      case 1 % double
          if isempty(h13), h13 = vision.MarkerInserter('Shape', 'Plus', 'BorderColorSource','Input port'); h13.setup(rgb, position, color); end
          h_MarkerInserter = h13;
      case 2 % single
          if isempty(h23), h23 = vision.MarkerInserter('Shape', 'Plus', 'BorderColorSource','Input port'); h23.setup(rgb, position, color); end
          h_MarkerInserter = h23;
      case 3 % uint8
          if isempty(h33), h33 = vision.MarkerInserter('Shape', 'Plus', 'BorderColorSource','Input port'); h33.setup(rgb, position, color); end
          h_MarkerInserter = h33;
      case 4 % uint16
          if isempty(h43), h43 = vision.MarkerInserter('Shape', 'Plus', 'BorderColorSource','Input port'); h43.setup(rgb, position, color); end
          h_MarkerInserter = h43;
      case 5 % int16
          if isempty(h53), h53 = vision.MarkerInserter('Shape', 'Plus', 'BorderColorSource','Input port'); h53.setup(rgb, position, color); end
          h_MarkerInserter = h53;
  end  
elseif (markerIdx == 4) % star
  switch inDTypeIdx
      % h(inDTypeIdx=1:5)(markerIdx=4)
      case 1 % double
          if isempty(h14), h14 = vision.MarkerInserter('Shape', 'Star', 'BorderColorSource','Input port'); h14.setup(rgb, position, color); end
          h_MarkerInserter = h14;
      case 2 % single
          if isempty(h24), h24 = vision.MarkerInserter('Shape', 'Star', 'BorderColorSource','Input port'); h24.setup(rgb, position, color); end
          h_MarkerInserter = h24;
      case 3 % uint8
          if isempty(h34), h34 = vision.MarkerInserter('Shape', 'Star', 'BorderColorSource','Input port'); h34.setup(rgb, position, color); end
          h_MarkerInserter = h34;
      case 4 % uint16
          if isempty(h44), h44 = vision.MarkerInserter('Shape', 'Star', 'BorderColorSource','Input port'); h44.setup(rgb, position, color); end
          h_MarkerInserter = h44;
      case 5 % int16
          if isempty(h54), h54 = vision.MarkerInserter('Shape', 'Star', 'BorderColorSource','Input port'); h54.setup(rgb, position, color); end
          h_MarkerInserter = h54;
  end  
else % if (markerIdx == 5) % square
  switch inDTypeIdx
      % h(inDTypeIdx=1:5)(markerIdx=5)
      case 1 % double
          if isempty(h15), h15 = vision.MarkerInserter('Shape', 'Square', 'BorderColorSource','Input port'); h15.setup(rgb, position, color); end
          h_MarkerInserter = h15;
      case 2 % single
          if isempty(h25), h25 = vision.MarkerInserter('Shape', 'Square', 'BorderColorSource','Input port'); h25.setup(rgb, position, color); end
          h_MarkerInserter = h25;
      case 3 % uint8
          if isempty(h35), h35 = vision.MarkerInserter('Shape', 'Square', 'BorderColorSource','Input port'); h35.setup(rgb, position, color); end
          h_MarkerInserter = h35;
      case 4 % uint16
          if isempty(h45), h45 = vision.MarkerInserter('Shape', 'Square', 'BorderColorSource','Input port'); h45.setup(rgb, position, color); end
          h_MarkerInserter = h45;
      case 5 % int16
          if isempty(h55), h55 = vision.MarkerInserter('Shape', 'Square', 'BorderColorSource','Input port'); h55.setup(rgb, position, color); end
          h_MarkerInserter = h55;
  end  
end