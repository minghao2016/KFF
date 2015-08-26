close all
clear all
clc

%% We are implementing a waveguide structure bordered by PEC.
%% Ez is exited. We attempt to find

Nx=128;
Ny=32;
Nz=16;
SIZE=[Nx Ny Nz];

simul.dx=50e-9;% Cell size in the X direction
simul.dy=25e-9;% Cell size in the Y direction
simul.dz=25e-9;% Cell size in the Z direction
simul.pad=1;% Pad in the X and Y direction so that the size is divisible by 16

simul.x=Nx*simul.dx;%% Approximate total simulation size in the X direction
simul.y=Ny*simul.dy;%% Approximate total simulation size in the Y direction
simul.z=Nz*simul.dz;%% Approximate total simulation size in the Z direction
[LinearGrid,simul]=CreateConstantGrid(simul); %% Create a constant Grid

c=3e8;% Speed of light
dt=0.9*1/(c*sqrt(1/(simul.dx^2)+(1/simul.dy^2)+(1/simul.dz)^2)); % Timestep using a courant factor of 0.9
nsteps=10000;% Number of timesteps
LinearGrid.info.dt=dt; % Set the timestep
LinearGrid.info.tt=nsteps; %Set the number of timesteps

lambda= 1500e-9;
omegaTM=(2*pi*3e8)/lambda;



%% Parameters of the waveguide.

% % TE Modes
% a=index2distance(LinearGrid,Ny-1,'y') %% Because of the perfect layer the last cell does not count in the distance.
% b=index2distance(LinearGrid,Nz-1,'z')

% TMmodes
a=index2distance(LinearGrid,Ny,'y')
b=index2distance(LinearGrid,Nz,'z')
for ny=(0:5)
    for nz=(0:5)
        omegamode(ny+1,nz+1)=c*sqrt((ny*pi/a)^2+(nz*pi/b)^2);
    end
end


ny=1;
nz=1;
omegaTM=c*sqrt((ny*pi/a)^2+(nz*pi/b)^2);



%% Set Perfectlayers.
LinearGrid=SetAllBorders(LinearGrid,'001111',1,'perfectlayerzone','PEC');
%% Add CPMLs
%% Termination

cpml.dx=10;
cpml.dy=10;
cpml.dz=10;
cpml.m=4;
cpml.xpos=1;
cpml.xneg=1;
cpml.ypos=0;
cpml.yneg=0;
cpml.zpos=0;
cpml.zneg=0;
cpml.amax=0.2000;
cpml.kmax=1;
cpml.smax=210000;



LinearGrid=AddCPML(LinearGrid,cpml);
%% Set Matarials
Air.name='Air';
Air.epsilon=1;
Air.sigma=0;
Air.ambient=1;
LinearGrid=AddMat(LinearGrid,Air);

%% Set sources.


source.x=17;
source.y=1;
source.z=1;
source.dx=0;
source.dy=Ny-1;
source.dz=Nz-1;
source.ny=ny;
source.nz=nz;
source.omega=omegaTM;
source.mut=4000;
source.sigmat=1000;
source.Ez=1;
source.sigma=200e-9;
source.type='gaussian';
sliceout=8;
LinearGrid=DefineSpecialSource(LinearGrid,source);


%% Define New outputs

B=2.5*omegaTM/(2*pi); %desired bandwidt
output.x=1;
output.y=1;
output.z=8;
output.dx='end';
output.dy='end';
output.dz=0;
output.deltaT=100;%% number of timesteps;
output.name='PECWaveguide';
output.deltaT=floor(1/(2*B*dt));%% number of timesteps;
output.foutstart=omegaTM*0.7/(2*pi);
output.foutstop=omegaTM*1.3/(2*pi);%% So we get all the frequencies.
output.field=[{'Ex'},{'Hx'}];
LinearGrid=AddOutput(LinearGrid,output);

modeout=output;
modeout.x=100;
modeout.y=1;
modeout.z=1;
modeout.deltaT=20;
modeout.dx=1;
modeout.dy='end';
modeout.dz='end';
modeout.name='PECModeOut';
LinearGrid=AddOutput(LinearGrid,modeout);


modeoutz=output;
modeoutz.x=1;
modeoutz.y=Ny/2;
modeoutz.z=Nz/2;
modeoutz.deltaT=5;
modeoutz.dx='end';
modeoutz.dy=0;
modeoutz.dz=0;
modeoutz.name='PECModeOutz';
LinearGrid=AddOutput(LinearGrid,modeoutz);

%% Section 7: Simulate!
SimulInfo.WorkPlace = '/home/pwahl/CUDA_SIMULATIONS/TestCaseResults/'; %% Where to work
SimulInfo.SimulatorExec='/home/pwahl/CUDA_SIMULATIONS/workspace/obj/fdtd'; %% Place where the fdtd program is located
SimulInfo.infile='/home/pwahl/CUDA_SIMULATIONS/TestCaseResults/PECWG'; %% Name of the input HDF5 file
SimulInfo.outfile='/home/pwahl/CUDA_SIMULATIONS/TestCaseResults/'; %Place where to output the HDF5 file
[debugout] = LocalSimulate(LinearGrid, SimulInfo);

%% Return and Extract
topology.field='topology';
topology.x='all';
topology.y='all';
topology.z=1;
topology.data=0;
topology.gridfield='Ez'
PlotData(topology,LinearGrid,[SimulInfo.outfile 'PECWaveguide']);

plot0.gridfield='Ex';
plot0.field='Ex_abs';
plot0.z=Nz/2;
plot0.x=1;
plot0.y='all';
plot0.noplot=1;
plot0.data=frequency2index([SimulInfo.outfile 'PECModeOutFFT'],omegaTM/(2*pi));
[data,pos]=PlotData(plot0,LinearGrid,[SimulInfo.outfile 'PECModeOutFFT']);


figure
hold on
plot(pos.x,data,'y')
plot(pos.x,abs(sin(ny*pi/a*(pos.x-pos.x(1))))*max(data),'*'); %% TM Mode
%plot(pos.x,abs(cos(ny*pi/a*(pos.x)))*max(data),'*');

Xfft=fft(data(1:end));
Xfft(1)=0;
[MAX,index]=max(abs(Xfft));
kz=index*2*pi/(length(data)*simul.dx)
kztheoretical=imag(sqrt((ny*pi/a)^2+(nz*pi/b)^2)-omegaTM/c^2);






















