close all
clear all
clc

Nx=256;
Ny=128;
Nz=1;%% 3 layers to do a 2D simulation 
SIZE=[Nx Ny Nz];

simul.dx=50e-9;% Cell size in the X direction
simul.dy=50e-9;% Cell size in the Y direction
simul.dz=25e-9;% Cell size in the Z direction
simul.pad=1;% Pad in the X and Y direction so that the size is divisible by 16

simul.x=Nx*simul.dx;%% Approximate total simulation size in the X direction
simul.y=Ny*simul.dy;%% Approximate total simulation size in the Y direction
simul.z=Nz*simul.dz;%% Approximate total simulation size in the Z direction
[LinearGrid,simul]=CreateConstantGrid(simul); %% Create a constant Grid


fine.dx='end'; %% Width of the finer grid in de X directions (In amount of cells in the coarse grid) 
fine.dy=10;%% Width of the finer grid in de Y directions (In amount of cells in the coarse grid) 
fine.dz='end'; %% Width of the finer grid in de Z directions (In amount of cells in the coarse grid) 
fine.x=1;              % Start postion in the X direction of the finer gridding box( 1 Because we will use symmetry)
fine.y=Ny/2-fine.dy/2; % Start postion in the Y direction of the finer gridding box
fine.z=1; % Start postion in the Z direction of the finer gridding box

fine.dxmin=simul.dx/1; %% Fine grid cell size in the X direction
fine.dymin=simul.dy/16; %% Fine grid cell size in the Y direction
fine.dzmin=simul.dz/1; %% Fine grid cell size in the Z direction
fine.pad=1;%% Pad make sure size of the grid is divisble by 16 in the X and Y dimention
fine.padtype='symetric'; %% Add equal amount of cells on the left and on the right when doeing the padding
FINE{1}=fine; %% Add a the fine zone FINE object array(More than one can be added)

[LinearGrid,middle]=encap(LinearGrid,FINE); %% Create the fine grid 
                                            % middle.x, middle.y and middle.z correspond the indexes of the the center of the finely 
                                            % zone in the new grid, for
                                            % convenience to define other structeres later                                           

LinearGrid.info.zz=1;
LinearGrid.grid.z=LinearGrid.grid.z(1);     
c=3e8;% Speed of light
dt=0.9*1/(c*sqrt(1/(fine.dxmin^2)+(1/fine.dymin^2)+(1/fine.dzmin)^2)); % Timestep using a courant factor of 0.9
nsteps=10000;% Number of timesteps
LinearGrid.info.dt=dt; % Set the timestep
LinearGrid.info.tt=nsteps; %Set the number of timesteps

lambda= 1500e-9;
omegaTM=(2*pi*3e8)/lambda;

%% Termination to simulate TE or TM modes
% TM Modes (Ez Hx Hy are supported)---> Terminate Z with PEC;
% LinearGrid=SetAllBorders(LinearGrid,'000010',1,'perfectlayerzone','PEC');
% LinearGrid=SetAllBorders(LinearGrid,'111100',1,'perfectlayerzone','PMC');
% TE Modes (Hz Ex Ey are supported)---> Terminate Z with PMC;
LinearGrid=SetAllBorders(LinearGrid,'001101',1,'perfectlayerzone','PMC');
LinearGrid=SetAllBorders(LinearGrid,'110000',1,'perfectlayerzone','PEC');



%% Set Matarials

Air.name='Air';
Air.epsilon=1;
Air.sigma=0;
Air.ambient=1;
LinearGrid=AddMat(LinearGrid,Air);


%% Add CPML
%% Termination

cpml.dx=10;
cpml.dy=10;
cpml.dz=0;
cpml.m=4;
cpml.xpos=1;
cpml.xneg=1;
cpml.ypos=1;
cpml.yneg=1;
cpml.zpos=0;
cpml.zneg=0;
cpml.amax=0.2000;
cpml.kmax=1;
cpml.smax=210000;



LinearGrid=AddCPML(LinearGrid,cpml);

%% Set sources.
source.dx='end';
source.dy=0;
source.dz='end';
source.x=1;
source.y=40;
source.z=1;
source.omega=omegaTM;
source.mut=nsteps/4;
source.sigmat=nsteps/10;
%source.Ez=1; %TM
source.Hz=1;%TE 
source.type='constant';
LinearGrid=DefineSpecialSource(LinearGrid,source);
%% Add Perfect Protector
%LinearGrid=AddPerfectConductor(LinearGrid,1,source.y+5,source.z,source.x,5,'end',{'Hz'});


B=2.5*omegaTM/(2*pi); %desired bandwidth
output.x=1;
output.y=1;
output.z=1;
output.dx='end';
output.dy='end';
output.dz=0;
output.deltaT=floor(1/(2*B*dt));%% number of timesteps;
output.name='MIM2DOut';
output.foutstart=omegaTM*0.7/(2*pi);
output.foutstop=omegaTM*1.3/(2*pi);%% So we get all the frequencies.
output.field=[{'Ex'},{'Ey'},{'Ez'},{'Hx'},{'Hy'},{'Hz'}];

output.deltafmin=omegaTM/(2*pi*50);
output.average=0;
LinearGrid=AddOutput(LinearGrid,output);
output.name='MIM2DOut2';
output.average=1;
output.field=[{'Ex'},{'Ey'},{'Ez'},{'Hx'},{'Hy'},{'Hz'}];

LinearGrid=AddOutput(LinearGrid,output);
%% Where to simulate
%% Section 7: Simulate1!
SimulInfo.WorkPlace = '/home/pwahl/CUDA_SIMULATIONS/TestCaseResults/'; %% Where to work
SimulInfo.SimulatorExec='/home/pwahl/MyCode/obj/fdtd'; %% Place where the fdtd program is located
SimulInfo.infile='/home/pwahl/CUDA_SIMULATIONS/TestCaseResults/MIM2D'; %% Name of the input HDF5 file
SimulInfo.outfile='/home/pwahl/CUDA_SIMULATIONS/TestCaseResults/'; %Place where to output the HDF5 file
[debugout] = LocalSimulate(LinearGrid, SimulInfo);


%% Copy Back



topology.field='topology';
topology.x='all';
topology.y='all';
topology.z=1;
topology.data=1;
%topology.gridfield='Hz';
topology.gridfield='Ey'
[topologydata,posdata]=PlotData(topology,LinearGrid,[SimulInfo.WorkPlace 'MIM2DOutFFT']);
%shading interp

%%
full=topology;
full.x='all';
full.y='all';
full.z=1;
full.plottype='normal';
full.field='Hz_abs';
full.noplot=0;
full.data=frequency2index([SimulInfo.WorkPlace 'MIM2DOutFFT'],omegaTM/(2*pi));
PlotData(full,LinearGrid,[SimulInfo.WorkPlace 'MIM2DOutFFT']);
shading interp


line=full;
line.x=Nx/2;
line.field='Hz_phase'
line.noplot=1;
[data1,pos1]=PlotData(line,LinearGrid,[SimulInfo.WorkPlace 'MIM2DOutFFT']);

%% Check Averaging

line=full;
line.x=Nx/2;
line.field='Ey_real'
line.noplot=0;
[datac1,pos1]=PlotData(line,LinearGrid,[SimulInfo.WorkPlace 'MIM2DOutFFT']);
[datac2,pos1]=PlotData(line,LinearGrid,[SimulInfo.WorkPlace 'MIM2DOut2FFT']);
dataavg=zeros(size(datac1));
dataavg(2:end)=(datac1(2:end)+datac1(1:end-1))/2;

%dataavg=[datac1(1); dataavg];
figure

plot(pos1.x,datac1)
subplot(1,2,1)
hold on

plot(pos1.x,datac2,'y*');
plot(pos1.x,dataavg,'ko');

subplot(1,2,2)
plot(pos1.x,dataavg-datac2,'ko');

%% Check averaging

check=full;
check.field='Hz'
check.data=15;
check.noplot=0;
[datac1,pos1]=PlotData(check,LinearGrid,[SimulInfo.WorkPlace 'MIM2DOut']);
[datac2,pos1]=PlotData(check,LinearGrid,[SimulInfo.WorkPlace 'MIM2DOut2']);
%% Check averargoing2
dataavg=zeros(size(datac1));
dataavg(2:end,2:end)=(datac1(1:end-1,1:end-1)+datac1(2:end,1:end-1)+datac1(1:end-1,2:end)+datac1(2:end,2:end))/4;
err=(datac2-dataavg);
pcolor(err(2:end,2:end))

%% Line 

line.y=Ny/2;
line.x='all';
line.noplot=0;
line.field='Ex_phase'
[dataEx,pos1]=PlotData(line,LinearGrid,[SimulInfo.WorkPlace 'MIM2DOut2FFT']);
line.field='Hz_phase'
[dataHz,pos1]=PlotData(line,LinearGrid,[SimulInfo.WorkPlace 'MIM2DOut2FFT']);

figure
plot(pos1.x,dataEx);
hold on
plot(pos1.x,dataHz-pi,'y*');
hold off
%% Simulate 2
% SimulInfo.SimulatorExec='/home/pwahl/CUDA_SIMULATIONS/workspace/obj/fdtd';
% [debugout] = LocalSimulate(LinearGrid, SimulInfo);
% [data2,pos2]=PlotData(line,LinearGrid,[SimulInfo.WorkPlace 'MIM2DOutFFT']);
% 
% 
% % %%
% %  dataT=Extract([SimulInfo.WorkPlace 'MIM2DOut'], 'Ez',4);
% %  MyLittlePlotOut(dataT)  
% 
% 
% %%
% 
% plot(pos1.x,data1,'b*');
% hold on
% plot(pos2.x,data2,'yo')
% legend('New','Old')
% figure
% plot(pos2.x,data2-data1)
