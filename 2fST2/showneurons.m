function varargout = showneurons(varargin)
global Linespec ShowneuronsInLag
% SHOWNEURONS M-file for showneurons.fig
%      SHOWNEURONS, by itself, creates a new SHOWNEURONS or raises the existing
%      singleton*.
%
%      H = SHOWNEURONS returns the handle to a new SHOWNEURONS or the handle to
%      the existing singleton*.
%
%      SHOWNEURONS('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SHOWNEURONS.M with the given input arguments.
%
%      SHOWNEURONS('Property','Value',...) creates a new SHOWNEURONS or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before showneurons_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to showneurons_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help showneurons

% Last Modified by GUIDE v2.5 01-Aug-2003 13:12:46

% Begin initialization code - DO NOT EDIT
Linespec{1} = 'r';
Linespec{2} = 'g';
Linespec{3} = 'b';
Linespec{4} = 'c';
Linespec{5} = 'm';
Linespec{6} = 'y';
Linespec{7} = 'k';
Linespec{8} = 'r-.';

ShowneuronsInLag = 1;



gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @showneurons_OpeningFcn, ...
    'gui_OutputFcn',  @showneurons_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin & isstr(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before showneurons is made visible.
function showneurons_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to showneurons (see VARARGIN)

global ShowneuronsLags ShowneuronsLayers ShowneuronsNeurons Linespec ShowneuronsStorage  ShowneuronsConfig

Linespec{1} = 'r';
Linespec{2} = 'g';
Linespec{3} = 'b';
Linespec{4} = 'c';
Linespec{5} = 'm';
Linespec{6} = 'y';
Linespec{7} = 'k';
Linespec{8} = 'r-.';

ShowneuronsLayers = zeros(1,8);
ShowneuronsNeurons = zeros(1,8);
ShowneuronsLags = zeros(1,8);

ShowneuronsLayers(1) = 1;
ShowneuronsNeurons(1) = 1;
ShowneuronsLags(1) = 1;

%thse variables control the saving of UI configurations

ShowneuronsStorage = zeros(9,3,8);
a = fopen('Showneuronsconfig.mat','r');
if ( a > 0)
    fclose(a);
    load('Showneuronsconfig');
end

ShowneuronsConfig = 1;

if exist('ShowNeuronsStorage', 'var')
    ShowneuronsLags(1:8) = reshape(ShowneuronsStorage(ShowneuronsConfig,1,1:8),[8,1]);
    ShowneuronsLayers(1:8) = reshape(ShowneuronsStorage(ShowneuronsConfig,2,1:8),[8,1]);
    ShowneuronsNeurons(1:8) = reshape(ShowneuronsStorage(ShowneuronsConfig,3,1:8),[8,1]);
end

h = get(hObject,'Parent');
h2 = findobj(h,'Tag','edit1');
set(h2,'String',num2str(ShowneuronsLags(1)));
h2 = findobj(h,'Tag','edit2');
set(h2,'String',num2str(ShowneuronsLayers(1)));
h2 = findobj(h,'Tag','edit4');
set(h2,'String',num2str(ShowneuronsNeurons(1)));
for(i = 2:8);
    ss = sprintf('edit%d',i*3-1);
    h2 = findobj(h,'Tag',ss);
    set(h2,'String',num2str(ShowneuronsLags(i)));
    ss = sprintf('edit%d',i*3);
    h2 = findobj(h,'Tag',ss);
    set(h2,'String',num2str(ShowneuronsLayers(i)));
    ss = sprintf('edit%d',i*3+1);
    h2 = findobj(h,'Tag',ss);
    set(h2,'String',num2str(ShowneuronsNeurons(i)));
end


% Choose default command line output for showneurons
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);


% UIWAIT makes showneurons wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = showneurons_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes during object creation, after setting all properties.
function edit1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
global ShowneuronsLags ShowneuronsLayers ShowneuronsNeurons Linespec



if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end

set(hObject,'BackgroundColor',Linespec{1});




function edit1_Callback(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit1 as text
%        str2double(get(hObject,'String')) returns contents of edit1 as a double

global ShowneuronsLags ShowneuronsLayers ShowneuronsNeurons
a = get(hObject,'String');
ShowneuronsLags(1) = eval(a);
imageit





% --- Executes during object creation, after setting all properties.
function edit2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end




function edit2_Callback(hObject, eventdata, handles)
% hObject    handle to edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit2 as text
%        str2double(get(hObject,'String')) returns contents of edit2 as a double

global ShowneuronsLags ShowneuronsLayers ShowneuronsNeurons
a = get(hObject,'String');
ShowneuronsLayers(1) = eval(a);
imageit




% --- Executes during object creation, after setting all properties.
function edit4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function edit4_Callback(hObject, eventdata, handles)
% hObject    handle to edit4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit4 as text
%        str2double(get(hObject,'String')) returns contents of edit4 as a double

global ShowneuronsLags ShowneuronsLayers ShowneuronsNeurons
a = get(hObject,'String');
ShowneuronsNeurons(1) = eval(a);
imageit



% --- Executes during object creation, after setting all properties.
function edit5_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
global Linespec
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end

set(hObject,'BackgroundColor',Linespec{2});


function edit5_Callback(hObject, eventdata, handles)
% hObject    handle to edit5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit5 as text
%        str2double(get(hObject,'String')) returns contents of edit5 as a double
global ShowneuronsLags ShowneuronsLayers ShowneuronsNeurons
a = get(hObject,'String');
ShowneuronsLags(2) = eval(a);
imageit


% --- Executes during object creation, after setting all properties.
function edit6_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function edit6_Callback(hObject, eventdata, handles)
% hObject    handle to edit6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit6 as text
%        str2double(get(hObject,'String')) returns contents of edit6 as a double

global ShowneuronsLags ShowneuronsLayers ShowneuronsNeurons
a = get(hObject,'String');
ShowneuronsLayers(2) = eval(a);
imageit

% --- Executes during object creation, after setting all properties.
function edit7_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function edit7_Callback(hObject, eventdata, handles)
% hObject    handle to edit7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit7 as text
%        str2double(get(hObject,'String')) returns contents of edit7 as a double

global ShowneuronsLags ShowneuronsLayers ShowneuronsNeurons
a = get(hObject,'String');
ShowneuronsNeurons(2) = eval(a);
imageit

% --- Executes during object creation, after setting all properties.
function edit8_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
global ShowneuronsLags ShowneuronsLayers ShowneuronsNeurons Linespec
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end
set(hObject,'BackgroundColor',Linespec{3});



function edit8_Callback(hObject, eventdata, handles)
% hObject    handle to edit8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit8 as text
%        str2double(get(hObject,'String')) returns contents of edit8 as a double
global ShowneuronsLags ShowneuronsLayers ShowneuronsNeurons
a = get(hObject,'String');
ShowneuronsLags(3) = eval(a);
imageit




% --- Executes during object creation, after setting all properties.
function edit9_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function edit9_Callback(hObject, eventdata, handles)
% hObject    handle to edit9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit9 as text
%        str2double(get(hObject,'String')) returns contents of edit9 as a double

global ShowneuronsLags ShowneuronsLayers ShowneuronsNeurons
a = get(hObject,'String');
ShowneuronsLayers(3) = eval(a);
imageit

% --- Executes during object creation, after setting all properties.
function edit10_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function edit10_Callback(hObject, eventdata, handles)
% hObject    handle to edit10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit10 as text
%        str2double(get(hObject,'String')) returns contents of edit10 as a double

global ShowneuronsLags ShowneuronsLayers ShowneuronsNeurons
a = get(hObject,'String');
ShowneuronsNeurons(3) = eval(a);
imageit

% --- Executes during object creation, after setting all properties.
function edit11_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit11 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
global ShowneuronsLags ShowneuronsLayers ShowneuronsNeurons Linespec
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end
set(hObject,'BackgroundColor',Linespec{4});



function edit11_Callback(hObject, eventdata, handles)
% hObject    handle to edit11 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit11 as text
%        str2double(get(hObject,'String')) returns contents of edit11 as a double

global ShowneuronsLags ShowneuronsLayers ShowneuronsNeurons
a = get(hObject,'String');
ShowneuronsLags(4) = eval(a);
imageit


% --- Executes during object creation, after setting all properties.
function edit12_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit12 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function edit12_Callback(hObject, eventdata, handles)
% hObject    handle to edit12 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit12 as text
%        str2double(get(hObject,'String')) returns contents of edit12 as a double
global ShowneuronsLags ShowneuronsLayers ShowneuronsNeurons
a = get(hObject,'String');
ShowneuronsLayers(4) = eval(a);
imageit


% --- Executes during object creation, after setting all properties.
function edit13_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit13 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function edit13_Callback(hObject, eventdata, handles)
% hObject    handle to edit13 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit13 as text
%        str2double(get(hObject,'String')) returns contents of edit13 as a double
global ShowneuronsLags ShowneuronsLayers ShowneuronsNeurons
a = get(hObject,'String');
ShowneuronsNeurons(4) = eval(a);
imageit


% --- Executes during object creation, after setting all properties.
function edit14_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit14 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
global ShowneuronsLags ShowneuronsLayers ShowneuronsNeurons Linespec
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end
set(hObject,'BackgroundColor',Linespec{5});



function edit14_Callback(hObject, eventdata, handles)
% hObject    handle to edit14 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit14 as text
%        str2double(get(hObject,'String')) returns contents of edit14 as a double
global ShowneuronsLags ShowneuronsLayers ShowneuronsNeurons
a = get(hObject,'String');
ShowneuronsLags(5) = eval(a);
imageit

% --- Executes during object creation, after setting all properties.
function edit15_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit15 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function edit15_Callback(hObject, eventdata, handles)
% hObject    handle to edit15 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit15 as text
%        str2double(get(hObject,'String')) returns contents of edit15 as a double
global ShowneuronsLags ShowneuronsLayers ShowneuronsNeurons
a = get(hObject,'String');
ShowneuronsLayers(5) = eval(a);
imageit


% --- Executes during object creation, after setting all properties.
function edit16_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit16 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function edit16_Callback(hObject, eventdata, handles)
% hObject    handle to edit16 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit16 as text
%        str2double(get(hObject,'String')) returns contents of edit16 as a double
global ShowneuronsLags ShowneuronsLayers ShowneuronsNeurons
a = get(hObject,'String');
ShowneuronsNeurons(5) = eval(a);
imageit


% --- Executes during object creation, after setting all properties.
function edit17_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit17 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
global ShowneuronsLags ShowneuronsLayers ShowneuronsNeurons Linespec
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end
set(hObject,'BackgroundColor',Linespec{6});



function edit17_Callback(hObject, eventdata, handles)
% hObject    handle to edit17 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit17 as text
%        str2double(get(hObject,'String')) returns contents of edit17 as a double
global ShowneuronsLags ShowneuronsLayers ShowneuronsNeurons
a = get(hObject,'String');
ShowneuronsLags(6) = eval(a);
imageit


% --- Executes during object creation, after setting all properties.
function edit18_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit18 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function edit18_Callback(hObject, eventdata, handles)
% hObject    handle to edit18 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit18 as text
%        str2double(get(hObject,'String')) returns contents of edit18 as a double
global ShowneuronsLags ShowneuronsLayers ShowneuronsNeurons
a = get(hObject,'String');
ShowneuronsLayers(6) = eval(a);
imageit


% --- Executes during object creation, after setting all properties.
function edit19_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit19 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function edit19_Callback(hObject, eventdata, handles)
% hObject    handle to edit19 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit19 as text
%        str2double(get(hObject,'String')) returns contents of edit19 as a double
global ShowneuronsLags ShowneuronsLayers ShowneuronsNeurons
a = get(hObject,'String');
ShowneuronsNeurons(6) = eval(a);
imageit


% --- Executes during object creation, after setting all properties.
function edit20_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit20 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.

global ShowneuronsLags ShowneuronsLayers ShowneuronsNeurons Linespec
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end
set(hObject,'BackgroundColor',Linespec{7});



function edit20_Callback(hObject, eventdata, handles)
% hObject    handle to edit20 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit20 as text
%        str2double(get(hObject,'String')) returns contents of edit20 as a double
global ShowneuronsLags ShowneuronsLayers ShowneuronsNeurons
a = get(hObject,'String');
ShowneuronsLags(7) = eval(a);
imageit


% --- Executes during object creation, after setting all properties.
function edit21_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit21 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function edit21_Callback(hObject, eventdata, handles)
% hObject    handle to edit21 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit21 as text
%        str2double(get(hObject,'String')) returns contents of edit21 as a double
global ShowneuronsLags ShowneuronsLayers ShowneuronsNeurons
a = get(hObject,'String');
ShowneuronsLayers(7) = eval(a);
imageit


% --- Executes during object creation, after setting all properties.
function edit22_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit22 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function edit22_Callback(hObject, eventdata, handles)
% hObject    handle to edit22 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit22 as text
%        str2double(get(hObject,'String')) returns contents of edit22 as a double
global ShowneuronsLags ShowneuronsLayers ShowneuronsNeurons
a = get(hObject,'String');
ShowneuronsNeurons(7) = eval(a);
imageit


% --- Executes during object creation, after setting all properties.
function edit23_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit23 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.

global ShowneuronsLags ShowneuronsLayers ShowneuronsNeurons Linespec
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end
set(hObject,'BackgroundColor',Linespec{8});



function edit23_Callback(hObject, eventdata, handles)
% hObject    handle to edit23 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit23 as text
%        str2double(get(hObject,'String')) returns contents of edit23 as a double
global ShowneuronsLags ShowneuronsLayers ShowneuronsNeurons
a = get(hObject,'String');
ShowneuronsLags(8) = eval(a);
imageit



% --- Executes during object creation, after setting all properties.
function edit24_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit24 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function edit24_Callback(hObject, eventdata, handles)
% hObject    handle to edit24 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit24 as text
%        str2double(get(hObject,'String')) returns contents of edit24 as a double
global ShowneuronsLags ShowneuronsLayers ShowneuronsNeurons
a = get(hObject,'String');
ShowneuronsLayers(8) = eval(a);
imageit


% --- Executes during object creation, after setting all properties.
function edit25_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit25 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function edit25_Callback(hObject, eventdata, handles)
% hObject    handle to edit25 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit25 as text
%        str2double(get(hObject,'String')) returns contents of edit25 as a double

global ShowneuronsLags ShowneuronsLayers ShowneuronsNeurons
a = get(hObject,'String');
ShowneuronsNeurons(8) = eval(a);
imageit





% --- Executes during object creation, after setting all properties.
function edit26_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit26 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function edit26_Callback(hObject, eventdata, handles)
% hObject    handle to edit26 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit26 as text
%        str2double(get(hObject,'String')) returns contents of edit26 as a double


global ShowneuronsLags ShowneuronsLayers ShowneuronsInLag
a = get(hObject,'String');
ShowneuronsInLag = eval(a);
imageit






% --- Executes during object creation, after setting all properties.
function listbox1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end

set(hObject,'String', {'MPHistory', 'OutHistory', 'InHistory', 'BiasHistory'});


% --- Executes on selection change in listbox1.
function listbox1_Callback(hObject, eventdata, handles)
% hObject    handle to listbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns listbox1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox1

global MPHistory OutHistory InHistory BiasHistory History

cellarray = {'MPHistory', 'OutHistory', 'InHistory', 'BiasHistory'};
evalstring = ['History = ',cellarray{get(hObject,'Value')},';'];
eval(evalstring);
imageit;










function imageit

%This function plots all the traces onto a figure in showneurons

global History ShowneuronsLags ShowneuronsLayers ShowneuronsNeurons Linespec  InHistory NUMLAYERS ShowneuronsInLag  Weightparams HebbHistory
global BinderHistory

%History contains the neuronal activity to be plotted
a= size(History);
h = get(gcbo,'Parent');
h3 = findobj(h,'Tag','axes1');
%
axes(h3);

%plot the first line

set(gca,'NextPlot','replace')
x = ShowneuronsLags(1);
y = ShowneuronsLayers(1);
z = ShowneuronsNeurons(1);

    if x > 0 && y > 0 && z > 0
if( y ==6 || y == 7)  % 6 and 7 don't reflect layers 6 and 7, but rather the binders
    plot(BinderHistory(x,:,y-5,z),Linespec{1});
elseif  (y == 21 || y == 22)
    plot(BinderHistory(x,:,y-18,z),Linespec{1});
else
    plot(History(x,:,y,z),Linespec{1});
end
set(gca,'NextPlot','add')
    end
    
%and the rest
for(i = 2:8);
    x = ShowneuronsLags(i);
    y = ShowneuronsLayers(i);
    z = ShowneuronsNeurons(i);
    if x > 0 && y > 0 && z > 0
    if( y ==6 || y == 7)
        plot(BinderHistory(x,:,y-5,z),Linespec{i});
    elseif  (y == 21 || y == 22)
        plot(BinderHistory(x,:,y-18,z),Linespec{i});
    else
        plot(History(x,:,y,z),Linespec{i});
    end

    %dump the output to a file
    a = fopen(sprintf('sn%d.xl',i),'w');
    if( y ==6 || y == 7)
        fprintf(a,'%g\n',BinderHistory(x,:,y-5,z));
    elseif  (y == 21 || y == 22)
        fprintf(a,'%g\n',BinderHistory(x,:,y-18,z));
    else
        fprintf(a,'%g\n',History(x,:,y,z));
    end

    fprintf(a,'0\n');
    fclose(a);
    end

end



set(gca,'XLim',[0 550]);
%set(gca,'YLim',[0 1]);
set(h3,'Tag','axes1')



%following code controls the bottom axes of the Figure.

%Not Used any longer: Use these variables for reporting something else

h3 = findobj(h,'Tag','axes2');
axes(h3)
set(gca,'NextPlot','replace')
plot(HebbHistory(ShowneuronsInLag,:,1,1),Linespec{1});
set(gca,'NextPlot','add')
plot(HebbHistory(ShowneuronsInLag,:,1,2),Linespec{2});
plot(HebbHistory(ShowneuronsInLag,:,2,1),Linespec{3});
plot(HebbHistory(ShowneuronsInLag,:,2,2),Linespec{4});
set(gca,'XLim',[0 550]);
set(h3,'Tag','axes2')


% --- Executes during object creation, after setting all properties.
function listbox2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end

set(hObject,'String',{'Layer 15','Layer 17','Layer 18','Layer 20','Layer 21','Layer 22','blasterTFL Item off 100ms','SingleTarg Item','50ms items dists'});










% --- Executes on selection change in listbox2.
function listbox2_Callback(hObject, eventdata, handles)
% hObject    handle to listbox2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns listbox2 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox2
global ShowneuronsConfig

ShowneuronsConfig = get(hObject,'Value')

% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%LOAD
global ShowneuronsLags ShowneuronsLayers ShowneuronsNeurons ShowneuronsConfig ShowneuronsStorage

'loading'
ShowneuronsLags(1:8) = reshape(ShowneuronsStorage(ShowneuronsConfig,1,1:8),[8,1]);
ShowneuronsLayers(1:8) = reshape(ShowneuronsStorage(ShowneuronsConfig,2,1:8),[8,1]);
ShowneuronsNeurons(1:8) = reshape(ShowneuronsStorage(ShowneuronsConfig,3,1:8),[8,1]);

h = get(hObject,'Parent');
h2 = findobj(h,'Tag','edit1');
set(h2,'String',num2str(ShowneuronsLags(1)));
h2 = findobj(h,'Tag','edit2');
set(h2,'String',num2str(ShowneuronsLayers(1)));
h2 = findobj(h,'Tag','edit4');
set(h2,'String',num2str(ShowneuronsNeurons(1)));
for(i = 2:8);
    ss = sprintf('edit%d',i*3-1);
    h2 = findobj(h,'Tag',ss);
    set(h2,'String',num2str(ShowneuronsLags(i)));
    ss = sprintf('edit%d',i*3);
    h2 = findobj(h,'Tag',ss);
    set(h2,'String',num2str(ShowneuronsLayers(i)));
    ss = sprintf('edit%d',i*3+1);
    h2 = findobj(h,'Tag',ss);
    set(h2,'String',num2str(ShowneuronsNeurons(i)));
end


imageit

zoom on




% --- Executes on button press in pushbutton2.
function pushbutton2_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%SAVE

global ShowneuronsLags ShowneuronsLayers ShowneuronsNeurons ShowneuronsConfig ShowneuronsStorage


'Storing'
ShowneuronsConfig
ShowneuronsStorage(ShowneuronsConfig,1,1:8) = reshape(ShowneuronsLags(1:8),[1,1,8]);
ShowneuronsStorage(ShowneuronsConfig,2,1:8) = reshape(ShowneuronsLayers(1:8),[1,1,8]);
ShowneuronsStorage(ShowneuronsConfig,3,1:8) = reshape(ShowneuronsNeurons(1:8),[1,1,8]);

save('Showneuronsconfig','ShowneuronsStorage');

