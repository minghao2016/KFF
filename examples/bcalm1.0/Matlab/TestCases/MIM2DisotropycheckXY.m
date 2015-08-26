clear all
close all


Nx=64;
Ny=64;
Nz=64;%% 3 layers to do a 2D simulation 




simul.dx=50e-9;% Cell size in the X direction
simul.dy=5e-9;% Cell size in the Y direction
simul.dz=25e-9;% Cell size in the Z direction
simul.pad=1;% Pad in the X and Y direction so that the size is divisible by 16

simul.x=Nx*simul.dx;%% Approximate total simulation size in the X direction
simul.y=Ny*simul.dy;%% Approximate total simulation size in the Y direction
simul.z=Nz*simul.dz;%% Approximate total simulation size in the Z direction
[LinearGrid,simul]=CreateConstantGrid(simul); %% Create a constant Grid

c=3e8;% Speed of light
dt=0.9*1/(c*sqrt(1/(simul.dx^2)+(1/simul.dy^2)+(1/simul.dz)^2)); % Timestep using a courant factor of 0.9
nsteps=1000;% Number of timesteps
LinearGrid.info.dt=dt; % Set the timestep
LinearGrid.info.tt=nsteps; %Set the number of timesteps

lambda= 1500e-9;
omegaTM=(2*pi*3e8)/lambda;

%% Termination to simulate TE or TM modes

%% TM Modes (Ez Hx Hy are supported)---> Terminate Z with PEC;
%%LinearGrid=SetAllBorders(LinearGrid,'000011',1,'perfectlayerzone','PEC');
%%LinearGrid=SetAllBorders(LinearGrid,'001100',1,'perfectlayerzone','PMC');
%% TE Modes (Hz Ex Ey are supported)---> Terminate Z with PMC;
LinearGrid=SetAllBorders(LinearGrid,'001111',1,'perfectlayerzone','PMC');
LinearGrid=SetAllBorders(LinearGrid,'110000',1,'perfectlayerzone','PEC');

%% Set Matarials
wpm=[1.014076882e16,6.861574653e15,1.832181311e15];
wm=[0,2.046174861e10,8.225155873e14];
gammam=0*[0,4.390839341e14,3.52118567e15];

wpm=[1.014076882e16];
wm=[0];
gammam=0*[0];



lambdatest=(1200e-9:10e-9:2000e-9);
omegatest=(2*pi*3e8)./lambdatest;
E=1.05457148e-34*omegatest/1.60217646e-19;
epsr=ones(1,length(omegatest));
eps0=8.854187817E-12;
mu0=4*pi*1e-7;
sumgamma=0;
 for m=(1:length(wpm))
    
   epsr=epsr+ (wpm(m))^2./(wm(m)^2-omegatest.^2+i*omegatest*gammam(m));

		alpha(m) = (2-wm(m)^2*dt^2)/(1+dt*gammam(m)/2);
		zeta(m)  = (dt*gammam(m)/2 - 1) / (dt*gammam(m)/2 + 1);
		gamma(m) = (wpm(m)*wpm(m)*eps0*dt*dt) / (dt*gammam(m)/2 + 1);
        sumgamma=gamma(m)+sumgamma;
     
 end

 C1=(sumgamma/2)/(2*eps0+sumgamma/2);
 C2=2*eps0/(2*eps0+sumgamma/2);
 C3=2*dt/(2*eps0+sumgamma/2);

figure
hold on
plot(lambdatest,real(epsr),'k*');
plot(lambdatest,imag(epsr),'r*');


Au.poles=[wpm',wm',gammam'];
Au.name='Au';
Au.epsilon=1;
LinearGrid=AddMat(LinearGrid,Au);

Air.name='Air';
Air.epsilon=1;
Air.sigma=0;
Air.ambient=1;
LinearGrid=AddMat(LinearGrid,Air);

d=50e-9;


%%




Auzone.name='Au';
Auzone.y=1;
Auzone.dy=Ny/2-floor(d/simul.dy);
Auzone.x=1;
Auzone.dx='end';
Auzone.z=1;
Auzone.dz='end';
LinearGrid=AddMatZone2(LinearGrid,Auzone);
Auzone.y=Ny-Auzone.dy;

LinearGrid=AddMatZone2(LinearGrid,Auzone);




%% Add CPML
%% Termination

cpml.dx=10;
cpml.dy=10;
cpml.dz=10;
cpml.m=4;
cpml.xpos=1;
cpml.xneg=1;
cpml.ypos=1;
cpml.yneg=1;
cpml.zpos=1;
cpml.zneg=1;
cpml.amax=0.2000;
cpml.kmax=1;
cpml.smax=210000;



LinearGrid=AddCPML(LinearGrid,cpml);


%% Set sources.
source.dx=0;
source.dy=0;
source.dz='end';
source.x=25;
source.y=Ny/2;
source.z=1;
source.omega=omegaTM*dt;
source.mut=nsteps/4;
source.sigmat=nsteps/10;
%%source.Ez=1; %TM
source.Hz=1;%TE 

source.type='constant';
LinearGrid=DefineSpecialSource(LinearGrid,source);
%% Add Perfect Protector
%LinearGrid=AddPerfectConductor(LinearGrid,1,source.y+5,source.z,source.x,5,'end',{'Hz'});


B=2.5*omegaTM/(2*pi); %desired bandwidth
output.x=1;
output.y=1;
output.z=Nz/2;
output.dx='end';
output.dy='end';
output.dz=0;
output.average=1;
output.deltaT=floor(1/(2*B*dt));%% number of timesteps;
output.name='inclined_slab';
output.foutstart=omegaTM*0.7/(2*pi);
output.foutstop=omegaTM*1.3/(2*pi);%% So we get all the frequencies.
output.field=[{'Hz'}];
LinearGrid=AddOutput(LinearGrid,output);

%% Section 7: Simulate!
SimulInfo.WorkPlace = '/home/pwahl/CUDA_SIMULATIONS/TestCaseResults/'; %% Where to work
SimulInfo.SimulatorExec='/home/pwahl/CUDA_SIMULATIONS/workspace/obj/fdtd'; %% Place where the fdtd program is located
SimulInfo.SimulatorExec='/home/pwahl/MyCode/obj/fdtd';
SimulInfo.infile='/home/pwahl/CUDA_SIMULATIONS/TestCaseResults/MIM2DIsotropy'; %% Name of the input HDF5 file
SimulInfo.outfile='/home/pwahl/CUDA_SIMULATIONS/TestCaseResults/'; %Place where to output the HDF5 file
[debugout] = LocalSimulate(LinearGrid, SimulInfo);
%% Plots

topology.field='topology';
topology.x='all';
topology.y='all';
topology.z=1;
topology.data=0;
topology.gridfield='Hz';
%topology.gridfield='Ez'
%[topologydata,posdata]=PlotData(topology,LinearGrid,[SimulInfo.outfile 'inclined_slabFFT']);
%shading interp


full=topology;
full.x='all';
full.y='all';
full.z=1;
full.plottype='normal';
full.field='Hz_real';
full.noplot=0;
full.data=frequency2index([SimulInfo.outfile 'inclined_slabFFT'],omegaTM/(2*pi));
PlotData(full,LinearGrid,[SimulInfo.outfile 'inclined_slabFFT']);
shading interp

line=full;
line.y=Ny/2;
PlotData(line,LinearGrid,[SimulInfo.outfile 'inclined_slabFFT']);




test=topology;
test.field='Hz_abs';
test.x=2*Nx/4;
test.y='all';
test.z=1;
test.plottype='normal';
test.noplot=0;
test.data=frequency2index([SimulInfo.outfile 'inclined_slabFFT'],omegaTM/(2*pi));
[testdata,pos]=PlotData(test,LinearGrid,[SimulInfo.outfile 'inclined_slabFFT']);


sourcecheck=test;
sourcecheck.x=source.x;
sourcecheck.y=source.y
sourcecheck.z=1;
sourcecheck.dx=0;
sourcecheck.dy=0;
sourcecheck.dz=0;
sourcecheck.data='all';
PlotData(sourcecheck,LinearGrid,[SimulInfo.outfile 'inclined_slabFFT']);


%% Theory for the TM0 mode


% Get the permittivity

omegath=omegaTM;
k0th=omegath/c;
index=find(omegatest>omegath,1,'last');
epsmth=epsr(index)*eps0;
epsith=1*eps0;

% Dimentions of the guide
a=d;

% Solving the dispertion relation numerically.
fh=@(ki) tanh(ki*a)^2-(ki^2+omegath^2*mu0*(epsith-epsmth))*epsith^2/(epsmth^2*ki^2);
[kis]=fzero(fh,k0th);

kms=sqrt(kis^2+(omegath^2*mu0*(epsith-epsmth)));
kzs=sqrt(kis^2+omegath^2*mu0*epsith);
lzs=2*pi/kzs;


fhhyp=@(ki,km) km^2-ki^2-omegath^2*mu0*(epsith-epsmth);
fhtanh=@(ki,km) tanh(ki*a)+(km/epsmth)/(ki/epsith);


%% Get a Y axis centered in the middle of the guide;

yaxis=pos.x-pos.x(Ny/2);

%% Filling in the Values.
for j=(1:Ny)
    
    y=yaxis(j);
    
    if abs(y)>a
        psi(j)=exp(-kms*(abs(y)-a));
    else
        psi(j)=cosh(kis*y)/cosh(kis*a);
    end

end

figure
hold on
plot(pos.x,testdata/max(testdata))
plot(pos.x,psi,'y*')
hold off













