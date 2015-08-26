clear all
close all
clc
SD=[(0:50:400)]*1e-9;
AL=[(100:20:240)]*1e-9;
neg=0;
addpath(genpath('/home/pwahl/CUDA_SIMULATIONS/workspace/Matlab'));
SimulInfoM.WorkPlace = '/media/BARRACUDA/Simulations/FullWaveGuideAntenna/';
SimulInfoM.SimulatorExec='/home/pwahl/CUDA_SIMULATIONS/workspace/obj/fdtd';
SimulInfoM.SimulatorExec='/home/pwahl/MyCode/obj/fdtd';
SimulInfoM.outfile='/media/BARRACUDA/Simulations/FullWaveGuideAntenna/Results/';
SimulInfoM.CalFile='/media/BARRACUDA/Simulations/FullWaveGuideAntenna/Results/Cal/';
SimulInfoM.Indir=['/media/BARRACUDA/Simulations/FullWaveGuideAntenna/Infile/'];
SimulInfoM.debugfile=[SimulInfoM.outfile 'debugout.txt'];
SimulInfoM.PrintStep=2000;
SimulInfoM.Matfiles=['/media/BARRACUDA/Simulations/FullWaveGuideAntenna/Infile/Matfile/'];
SimulInfoM.Pics='/media/BARRACUDA/Simulations/FullWaveGuideAntenna/Results/Pics/';

% fid =fopen([SimulInfoM.Indir 'CAL_BATCH'],'a');
% fid =fopen([SimulInfoM.Indir 'AL_VARIATION_FAT'],'a');
fid =fopen([SimulInfoM.Indir 'ALVAR'],'w'); %% File where the will serve 



%% Section 1: Create the coarse grid
%First we create a coarse grid in which a finer grid will be embedded.

simul.x=2.5e-6;%% Approximate total simulation size
simul.y=4e-6; %% Size of the coarse grid
simul.z=4e-6; %% Size of the coarse grid

simul.dx=80e-9;% Cell size of the coarse grid in the X direction
simul.dy=80e-9;% Cell size of the coarse grid in the Y direction
simul.dz=80e-9;% Cell size of the coarse grid in the Z direction
simul.pad=1;
[Grid,simul]=CreateConstantGrid(simul);

Nx=Grid.info.xx;
Ny=Grid.info.yy;
Nz=Grid.info.zz;
%% Section 2: Set the number of steps
nsteps=10000; %% Number of steps
Grid.calibrate=0; %% Not a calibration simulation
Grid.Ex=1; %% Source is in the Ex direction, Will be used later
Grid.Ey=0; %% Source is in the Ey direciion, Will be used later
lambda=850e-9; %% Wavelength

%% Section 3: Define a the finer grid;

fine.dx=6; %% Width of the finer grid in de X directions (In amount of cells in the coarse grid) 
fine.dy=10;%% Width of the finer grid in de Y directions (In amount of cells in the coarse grid) 
fine.dz=4; %% Width of the finer grid in de Z directions (In amount of cells in the coarse grid) 
fine.uponly.x=1; %% This zone starts in a small grid and goes up to a finer grid in the X direction 
                 % This Done because symmetry will be used on the left side
                 %
fine.x=1;              % Start postion in the X direction of the finer gridding box( 1 Because we will use symmetry)
fine.y=Ny/2-fine.dy/2; % Start postion in the Y direction of the finer gridding box
fine.z=floor(Nz/2-fine.dz/2); % Start postion in the Z direction of the finer gridding box

fine.dxmin=simul.dx/32; %% Fine grid cell size in the X direction
fine.dymin=simul.dy/16; %% Fine grid cell size in the Y direction
fine.dzmin=simul.dz/32; %% Fine grid cell size in the Z direction
fine.pad=1;%% Pad make sure size of the grid is divisble by 16 in the X and Y dimention
fine.padtype='symetric'; %% Add equal amount of cells on the left and on the right when doeing the padding
FINE{1}=fine; %% Add a the fine zone FINE object array(More than one can be added)

[Grid,middle]=encap(Grid,FINE); %% Create the fine grid 
                                            % middle.x, middle.y and middle.z correspond the indexes of the the center of the finely 
                                            % zone in the new grid, for convenience to define other structeres later                                           
                                  
%% Section 4  Set the number of timesteps 
c=3e8; %% Speed of light
dt=0.9*1/(c*sqrt(1/(fine.dxmin^2)+(1/fine.dymin^2)+(1/fine.dzmin)^2)); %% Calculate the timestep based on the smallest grid element
Grid.info.dt=dt; % Define the time increment
Grid.info.tt=nsteps; % Define the amount of timesteps
Nx=Grid.info.xx; 
Ny=Grid.info.yy;
Nz=Grid.info.zz;


%% Section 5 Termination by PEC or PMC for symmetric boundary conditions
Grid=SetAllBorders(Grid,'0000011',1,'perfectlayerzone','PMC'); %% Add a PMC wall in the Z direction.
if Grid.Ex==1
Grid=SetAllBorders(Grid,'100000',1,'perfectlayerzone','PEC'); %% Add a PEC wall on the left size in the X direction. For symmentry in TE modes
end

if Grid.Ey==1
   Grid=SetAllBorders(Grid,'100000',1,'perfectlayerzone','PMC'); %% ADD a PMC waal on the left size in the X directopm. For anitsymmetry in TE Modes.
end
%% Section 6 Defining Materials 

Air.name='Air';
Air.epsilon=1;
Air.sigma=0;
Air.ambient=1;
Grid=AddMat(Grid,Air);
% gold
wpm=[4.386227824e15,1.008519648e15,7.251716026e15,1.332784755e16]; %lorentz parameters
wm=[0,1.874386332e15,3.534954035e15,0]; %lorentz parameters
gammam=[1.565488534e15 8.109675964e14 0 ,0]; % loretentz parameters
Au.poles=[wpm',wm',gammam']; %% Defining the poles
Au.name='Au';
Au.epsilon=1;
Grid=AddMat(Grid,Au);

Oxide.name='Oxide'
Oxide.epsilon=1.44^2; %% Refractive index of oxide
Grid=AddMat(Grid,Oxide); % Defining oxide
%% Section 7  CPML Termination
cpml.dx=10;% Width of the CPML in the x direction (#cells)
cpml.dy=10;% Width of the CPML in the y direction (#cells)
cpml.dz=10;% Width of the CPML in the z direction (#cells)
cpml.xpos=1;% Add a CPML on the right X direction
cpml.xneg=0;% No CPML on the left X direction
cpml.ypos=1;% Add a CPML on the right Y direction
cpml.yneg=1;% Add a CPML on the left Y direction
cpml.zpos=1;% Add a CPML on the right Z direction
cpml.zneg=1;% Add a CPML on the right Z direction

cpml.m=4; %CPML specific don't really need to change
cpml.amax=0.2000; %CPML specific don't really need to change
cpml.kmax=4;%CPML specific don't really need to change
cpml.smax=210000;%CPML specific don't really need to change
Grid=AddCPML(Grid,cpml); %% Add the CPML
%% Section 8 Set sources Gaussian Beam
nstepssource=10000;
omegaTM=(2*pi*3e8)/lambda;
source.x=1;% Pos of the waist of the Gaussian Beam  (# cells)
source.y=middle(1).y;% Pos of the waist of the Gaussian Beam  (# cells)
source.z=middle(1).z;% Pos of the waist of the Gaussian Beam  (# cells)
source.dx=0;%% Insignificant when defining a Gaussian Beam
source.dy=0;%% Insignificant when defining a Gaussian Beam
source.dz=0;%% Insignificant when defining a Gaussian Beam
source.omega=omegaTM; %Angular frequency of the exitation in (Hz)
source.mut=nstepssource/4;% Mu of the temporal gaussian envelope (in timesteps)
source.sigmat=nstepssource/10; %Sigma of the temporal gaussian envelope (in timesteps)
source.Ex=Grid.Ex;%Amplitude of the exitation of the Ex field;
source.Ey=Grid.Ey;%Amplitude of the exitation of the Ey field;
source.facez=Nz-11;%%  From wich face are we exiting
source.type='gaussianbeam';%% Set the type to gaussianbeam
source.n=1;% Index of the material between the source and the waist
source.w0=1*lambda;% Size of the waist of the gaussian beam
source.phi=0;%Angle Kvector of the Gaussian beam to and the Z axis
source.tetha=0; % Angle between the projection of the K vector of the gaussian beam on the XY plane and the X axis
Grid=DefineSpecialSource(Grid,source); %% Add the source
     
        for al=5
        
%% Structure Parameters;

Antenna.thick=80e-9;
Antenna.width=100e-9;
Antenna.length=AL(al);
Antenna.stubwidth=0;
Antenna.stubdistance=0;

%% Guide

Guide.metalwidth=100e-9;
Guide.width=100e-9;
Guide.distance=0;
     
%% Set the tags: to have filenames that contain the structure parameters.        
if ~Grid.calibrate
tag=sprintf('SDVSD%.2eSW%.2eAL%.2eAW%.2eATH%.2eGMW%.2eGW%.2eGD%.2e',Antenna.stubdistance,Antenna.stubwidth,Antenna.length,Antenna.width,Antenna.thick,Guide.metalwidth,Guide.width,Guide.distance);
else
tag=['Cal'];
SimulInfoM.outfile=SimulInfoM.CalFile;
end

% add the exitation to the tag
if Grid.Ex==1;
    tag=[tag '_Ex'];
end


if Grid.Ey==1;
    tag=[tag '_Ey'];
end
 
%%  Delete the zones that are modified within the for loop.       
if isfield(Grid,'outputzones')        
Grid=rmfield(Grid,'outputzones');      
end 
if isfield(Grid,'lorentzzone')        
Grid=rmfield(Grid,'lorentzzone');      
end
if isfield(Grid,'dielzone')        
Grid=rmfield(Grid,'dielzone');      
end

%% Define New outputs
B=2*omegaTM/(2*pi);%desired bandwidth
output.x=1;
output.y=1;
output.z=middle.z;
output.dx='end';
output.dy='end';
output.dz=0;
output.deltaT=floor(1/(2*B*dt));%% number of timesteps;
output.name=['In_Plane' tag];
output.foutstart=0.7*omegaTM/(2*pi);
output.foutstop=1.3*omegaTM/(2*pi);%% So we get all the frequencies.
output.field=[{'Ex'},{'Ey'},{'Ez'},{'Hx'},{'Hy'},{'Hz'}];
output.deltafmin=omegaTM/(2*100*pi);
Grid=AddOutput(Grid,output);

output2=output;
output2.name=['Cross_Plane' tag];
output2.x=1;
output2.dx='end';
output2.y=middle(1).y;
output2.dy=0;
output2.z=1;
output2.dz='end';
Grid=AddOutput(Grid,output2);
output3=output2;
output3.name=['Cross_Waveguide' tag];
output3.y=Ny-12;
Grid=AddOutput(Grid,output3);      
        


 %% Adding the Materials
%% Metal;
%Antenna
Me.calibrate=1;
Me.dx=floor(Antenna.length/fine.dxmin)-1;
Me.dy=floor(Antenna.width/fine.dymin)-1;
Me.dz=floor(Antenna.thick/fine.dzmin)-1;
Me.x=floor(Guide.width/(2*(fine.dxmin)));
Me.y=middle(1).y+floor((Antenna.stubdistance)/(2*fine.dymin))-Me.dy;
Me.z=middle(1).z-floor(Antenna.thick/(2*fine.dzmin));
Me.name='Au';
Grid=AddMatZone(Grid,Me);
%Stub
Stub=Me;
Stub.dx=Me.x;
Stub.x=1;
 
Stub.dy=floor(Antenna.stubwidth/fine.dymin)-1;
Stub.y=middle(1).y-floor((Antenna.stubdistance/(2*fine.dymin))+Stub.dy);
if Stub.dy>0
 Grid=AddMatZone(Grid,Stub);
end
 
 %Guide.
 
GZ=Me;
GZ.x=floor(Guide.width/(2*(fine.dxmin)));
GZ.dx=floor(Guide.metalwidth/fine.dxmin)-1;
%GZ.dx='end'
GZ.y=1;
GZ.dy='end';
Grid=AddMatZone(Grid,GZ);
% Oxide
Ox.x=1;
Ox.y=1;
Ox.z=1;
Ox.name='Oxide';
Ox.dx='end';
Ox.dy='end';
Ox.dz=Me.z-2;
Grid=AddMatZone(Grid,Ox);

SimulInfoM.infile=[SimulInfoM.Indir 'In' tag]

runcmd = sprintf('\n\t %s -f %d -i %s -o %s -F -T', ...
    SimulInfoM.SimulatorExec, ...
    SimulInfoM.PrintStep, ...
    SimulInfoM.infile, ...
    SimulInfoM.outfile);


%fprintf(fid,runcmd);
hdf_export(SimulInfoM.infile,Grid);
system(runcmd);

%Saving Matlab file

save([SimulInfoM.Matfiles tag 'SingleAntenna.mat' ],'Grid','Me','Stub','GZ');
% 
    end

%close the file
 fclose(fid) 
 %% Plotting the topologies 

% In Plane
full.x='all';
full.y='all';
full.z=1;
full.plottype='normal';
full.field='topology';
full.noplot=0;
full.sym.x=1; %% Force symetry in X
full.gridfield='Ey'
full.data=1;
PlotData(full,Grid,[SimulInfoM.outfile 'In_Plane' tag 'FFT']);
%Cross Section
full2=full;
full2.x='all';
full2.y=1;
full2.z='all';
PlotData(full2,Grid,[SimulInfoM.outfile 'Cross_Plane' tag 'FFT']);

%% Plotting the fields

full.field='Ex_real';
full.data=frequency2index([SimulInfoM.outfile 'In_Plane' tag 'FFT'],omegaTM/(2*pi));
 PlotData(full,Grid,[SimulInfoM.outfile 'In_Plane' tag 'FFT']);
 shading interp
full2.field='Ex_abs';
full2.plottype='normal'
full2.data=frequency2index([SimulInfoM.outfile 'Cross_Plane' tag 'FFT'],omegaTM/(2*pi));
PlotData(full2,Grid,[SimulInfoM.outfile 'Cross_Plane' tag 'FFT']);
shading interp

full2.field='Py_abs';
full2.plottype='normal'
full2.data=frequency2index([SimulInfoM.outfile 'Cross_Waveguide' tag 'FFT'],omegaTM/(2*pi));
PlotData(full2,Grid,[SimulInfoM.outfile 'Cross_Waveguide' tag 'FFT']);
shading interp

full2.field='Ex_abs';
full2.plottype='normal'
full2.data=frequency2index([SimulInfoM.outfile 'Cross_Waveguide' tag 'FFT'],omegaTM/(2*pi));
PlotData(full2,Grid,[SimulInfoM.outfile 'Cross_Waveguide' tag 'FFT']);
shading interp

% 
%  dataT=Extract([SimulInfoM.outfile 'In_Plane' tag], 'Ex',4);
%  MyLittlePlotOut(dataT)  




