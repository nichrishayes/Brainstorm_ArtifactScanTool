function artifactscantool_plot_layout(layout, varargin)

% FT_PLOT_LAYOUT plots a two-dimensional channel layout
%
% Use as
%   ft_plot_layout(layout, ...)
% where the layout is a FieldTrip structure obtained from FT_PREPARE_LAYOUT.
%
% Additional options should be specified in key-value pairs and can be
%   'chanindx'    = list of channels to plot (default is all)
%   'point'       = yes/no
%   'box'         = yes/no
%   'label'       = yes/no
%   'labeloffset' = offset of label from point (default = 0)
%   'labelrotate' = scalar, vector with rotation angle (in degrees) per label (default = 0)
%   'labelalignh' = string, or cell-array specifying the horizontal alignment of the text (default = 'center')
%   'labelalignv' = string, or cell-array specifying the vertical alignment of the text (default = 'middle')
%   'mask'        = yes/no
%   'outline'     = yes/no
%   'verbose'     = yes/no
%   'pointsymbol' = string with symbol (e.g. 'o') - all three point options need to be used together
%   'pointcolor'  = string with color (e.g. 'k')
%   'pointsize'   = number indicating size (e.g. 8)
%   'fontcolor'   = string, color specification (default = 'k')
%   'fontsize'    = number, sets the size of the text (default = 10)
%   'fontunits'   =
%   'fontname'    =
%   'fontweight'  =
%   'interpreter' = string, 'none', 'tex' or 'latex'
%
% It is possible to plot the object in a local pseudo-axis (c.f. subplot), which is specfied as follows
%   'hpos'        = horizontal position of the lower left corner of the local axes
%   'vpos'        = vertical position of the lower left corner of the local axes
%   'width'       = width of the local axes
%   'height'      = height of the local axes
%
% See also FT_PREPARE_LAYOUT, FT_PLOT_TOPO

% Copyright (C) 2009, Robert Oostenveld
%
% This file is part of FieldTrip, see http://www.fieldtriptoolbox.org
% for the documentation and details.
%
%    FieldTrip is free software: you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation, either version 3 of the License, or
%    (at your option) any later version.
%
%    FieldTrip is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%
%    You should have received a copy of the GNU General Public License
%    along with FieldTrip. If not, see <http://www.gnu.org/licenses/>.
%
% $Id$

ws = warning('on', 'MATLAB:divideByZero');

% get the optional input arguments
chanindx     = bst_ast_getopt(varargin, 'chanindx',     []);
hpos         = bst_ast_getopt(varargin, 'hpos',         0);
vpos         = bst_ast_getopt(varargin, 'vpos',         0);
width        = bst_ast_getopt(varargin, 'width',        []);
height       = bst_ast_getopt(varargin, 'height',       []);
point        = bst_ast_getopt(varargin, 'point',        true);
box          = bst_ast_getopt(varargin, 'box',          true);
label        = bst_ast_getopt(varargin, 'label',        true);
labeloffset  = bst_ast_getopt(varargin, 'labeloffset',  0);
labelxoffset = bst_ast_getopt(varargin, 'labelxoffset', labeloffset);
labelyoffset = bst_ast_getopt(varargin, 'labelyoffset', labeloffset*1.5);
mask         = bst_ast_getopt(varargin, 'mask',         true);
outline      = bst_ast_getopt(varargin, 'outline',      true);
verbose      = bst_ast_getopt(varargin, 'verbose',      false);
pointsymbol  = bst_ast_getopt(varargin, 'pointsymbol');
pointcolor   = bst_ast_getopt(varargin, 'pointcolor');
pointsize    = bst_ast_getopt(varargin, 'pointsize');

% these have to do with the font
fontcolor   = bst_ast_getopt(varargin, 'fontcolor', 'k'); % default is black
fontsize    = bst_ast_getopt(varargin, 'fontsize',   get(0, 'defaulttextfontsize'));
fontname    = bst_ast_getopt(varargin, 'fontname',   get(0, 'defaulttextfontname'));
fontweight  = bst_ast_getopt(varargin, 'fontweight', get(0, 'defaulttextfontweight'));
fontunits   = bst_ast_getopt(varargin, 'fontunits',  get(0, 'defaulttextfontunits'));
% these have to do with the font
interpreter  = bst_ast_getopt(varargin, 'interpreter', 'tex'); % none, tex or latex

% some stuff related to some refined label plotting
labelrotate   = bst_ast_getopt(varargin, 'labelrotate',  0);
labelalignh   = bst_ast_getopt(varargin, 'labelalignh',  'center');
labelalignv   = bst_ast_getopt(varargin, 'labelalignv',  'middle');
labelcolor    = bst_ast_getopt(varargin, 'labelcolor', 'k');

% convert between true/false/yes/no etc. statements
point   = bst_ast_istrue(point);
box     = bst_ast_istrue(box);
label   = bst_ast_istrue(label);
mask    = bst_ast_istrue(mask);
outline = bst_ast_istrue(outline);
verbose = bst_ast_istrue(verbose);

% color management
if ischar(pointcolor) && exist([pointcolor '.m'], 'file')
  pointcolor = eval(pointcolor);
end

if ~(point || box || label || mask || outline)
  % there is nothing to be plotted
  return;
end

% everything is added to the current figure
holdflag = ishold;
if ~holdflag
  hold on
end

% make a selection of the channels
if ~isempty(chanindx)
  layout.pos    = layout.pos(chanindx,:);
  layout.width  = layout.width(chanindx);
  layout.height = layout.height(chanindx);
  layout.label  = layout.label(chanindx);
end

% the units can be arbitrary (e.g. relative or pixels), so we need to compute the right scaling factor and offset
% create a matrix with all coordinates from positions, mask, and outline
allCoords = layout.pos;
if isfield(layout, 'mask') && ~isempty(layout.mask)
  for k = 1:numel(layout.mask)
    allCoords = [allCoords; layout.mask{k}];
  end
end
if isfield(layout, 'outline') &&~isempty(layout.outline)
  for k = 1:numel(layout.outline)
    allCoords = [allCoords; layout.outline{k}];
  end
end

naturalWidth = (max(allCoords(:,1))-min(allCoords(:,1)));
naturalHeight = (max(allCoords(:,2))-min(allCoords(:,2)));

if isempty(width) && isempty(height)
  xScaling = 1;
  yScaling = 1;
elseif isempty(width) && ~isempty(height)
  % height specified, auto-compute width while maintaining aspect ratio
  yScaling = height/naturalHeight;
  xScaling = yScaling;
elseif ~isempty(width) && isempty(height)
  % width specified, auto-compute height while maintaining aspect ratio
  xScaling = width/naturalWidth;
  yScaling = xScaling;
else
  % both width and height specified
  xScaling = width/naturalWidth;
  yScaling = height/naturalHeight;
end

X      = layout.pos(:,1)*xScaling + hpos;
Y      = layout.pos(:,2)*yScaling + vpos;
Width  = layout.width*xScaling;
Height = layout.height*yScaling;
Lbl    = layout.label;

if point
  if ~isempty(pointsymbol) && ~isempty(pointcolor) && ~isempty(pointsize) % if they're all non-empty, don't use the default
    plot(X, Y, 'marker', pointsymbol, 'color', pointcolor, 'markersize', pointsize, 'linestyle', 'none');
  else
    plot(X, Y, 'marker', '.', 'color', 'b', 'linestyle', 'none');
    plot(X, Y, 'marker', 'o', 'color', 'y', 'linestyle', 'none');
  end
end

if label
  % the MATLAB text function fails if the position for the string is specified in single precision
  X = double(X);
  Y = double(Y);

  % check whether fancy label plotting is needed, this requires a for loop,
  % otherwise print text in a single shot
  if numel(labelrotate)==1
    text(X+labelxoffset, Y+labelyoffset, Lbl , 'interpreter', interpreter, 'horizontalalignment', labelalignh, 'verticalalignment', labelalignv, 'color', fontcolor, 'fontunits', fontunits, 'fontsize', fontsize, 'fontname', fontname, 'fontweight', fontweight);
  else
    n = numel(Lbl);
    if ~iscell(labelalignh)
      labelalignh = repmat({labelalignh},[n 1]);
    end
    if ~iscell(labelalignv)
      labelalignv = repmat({labelalignv},[n 1]);
    end
    if numel(Lbl)~=numel(labelrotate)||numel(Lbl)~=numel(labelalignh)||numel(Lbl)~=numel(labelalignv)
      error('there is something wrong with the input arguments');
    end
    for k = 1:numel(Lbl)
      h = text(X(k)+labelxoffset, Y(k)+labelyoffset, Lbl{k}, 'interpreter', interpreter, 'horizontalalignment', labelalignh{k}, 'verticalalignment', labelalignv{k}, 'rotation', labelrotate(k), 'color', fontcolor, 'fontunits', fontunits, 'fontsize', fontsize, 'fontname', fontname, 'fontweight', fontweight);
    end
  end
end

if box
  line([X-Width/2 X+Width/2 X+Width/2 X-Width/2 X-Width/2]',[Y-Height/2 Y-Height/2 Y+Height/2 Y+Height/2 Y-Height/2]', 'color', [0 0 0]);
end

if outline && isfield(layout, 'outline')
  if verbose
    fprintf('solid lines indicate the outline, e.g. head shape or sulci\n');
  end
  for i=1:length(layout.outline)
    if ~isempty(layout.outline{i})
      X = layout.outline{i}(:,1)*xScaling + hpos;
      Y = layout.outline{i}(:,2)*yScaling + vpos;
      h = line(X, Y);
      set(h, 'color', 'k');
      set(h, 'linewidth', 2);
    end
  end
end

if mask && isfield(layout, 'mask')
  if verbose
    fprintf('dashed lines indicate the mask for topograpic interpolation\n');
  end
  for i=1:length(layout.mask)
    if ~isempty(layout.mask{i})
      X = layout.mask{i}(:,1)*xScaling + hpos;
      Y = layout.mask{i}(:,2)*yScaling + vpos;
      % the polygon representing the mask should be closed
      X(end+1) = X(1);
      Y(end+1) = Y(1);
      h = line(X, Y);
      set(h, 'color', 'k');
      set(h, 'linewidth', 1.5);
      set(h, 'linestyle', ':');
    end
  end
end

axis auto
axis equal
axis off

if ~holdflag
  hold off
end

warning(ws); %revert to original state