%% This function gets the numerical propagation constant from a calibration
%% simulation as it usually differs slightly from the mode solving.
%% Fc is the complex field along the propagation direction
%% pos is what comes out of the PlotData. 
%% pos.x should be the grid. pos.y the corresponding frequencies
%% beta.value is the complex propagation constant with F(z)=F(0)exp(-i*beta*z)
%% beta.freq is the frequencies at which the betas are calculated.

function [beta]=GetBeta(Fc,pos)


[dataphase]=angle(Fc);
[dataabs]=abs(Fc);

% We first find how wavelength cycli there are we pick the one the last to
% do the measurement of the phase velocity 

for cnt=(1:length(pos.y))
    [peaks,loc]=findpeaks(dataphase(:,cnt));  
    x1=loc(length(peaks)-2);
    x2=loc(length(peaks)-1)-10; 
    hold off
    d=pos.x(x2)-pos.x(x1);
    deltaphi=abs(dataphase(x2,cnt)-dataphase(x1,cnt));
    lcal(cnt)=2*pi/deltaphi*d;
      
    
end
% Absorption all the way to the end with a safe boundary for the cmpls
    x1=loc(6);
    x2=length(pos.x)-40;
    dc=pos.x(x2)-pos.x(x1);
    rc=dataabs(x2,:)./dataabs(x1,:);
    imbeta=log(rc)./dc;
    rbeta=2*pi./lcal;
    beta.value=rbeta+1i*imbeta;
    beta.freq=pos.y;
    figure
    hold on
    plot(pos.x,dataabs(:,10))
    plot(pos.x(x1),dataabs(x1,10),'y*')
    plot(pos.x(x2),dataabs(x2,10),'k*')
    
end
    