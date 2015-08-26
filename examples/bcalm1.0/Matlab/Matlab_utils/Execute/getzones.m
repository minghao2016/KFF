%% Creates a Zone File readable by our C program.
%% It is basically an array with on each row with respectively
% -index of the material in deps in the C program
% -x in the C program
% -y in the C program
% -z in the C program
% -dx in the C program
% -dy in the C program
% -dz in the C program

function zones=getzones(g,type)

if strcmp(type,'dielzone')%% Explort the dielzones

    for zone =1:length(g.dielzone) %% Go over all zones
        type=gettypeindex(g.dielzone(zone).type);
        for mat=1:length(g.deps)%% Go over all materials
            if strcmp(g.dielzone(zone).name,g.deps(mat).name)
                zones(:,zone)=[mat-1,g.dielzone(zone).x-1,g.dielzone(zone).y-1,g.dielzone(zone).z-1,...
                    g.dielzone(zone).dx,g.dielzone(zone).dy,g.dielzone(zone).dz, type];
            end
        end
    end
end
%% Perfectlayerzones

if strcmp(type,'perfectlayerzone')
    for zone =1:length(g.perfectlayerzone) %% Go over all zones

        zones(:,zone)=[g.perfectlayerzone(zone).layerindex,g.perfectlayerzone(zone).x-1,g.perfectlayerzone(zone).y-1,g.perfectlayerzone(zone).z-1,...
            g.perfectlayerzone(zone).dx,g.perfectlayerzone(zone).dy,g.perfectlayerzone(zone).dz];

    end

end


%% CMPLzones

if strcmp(type,'cpmlzone')
    for zone =1:length(g.cpmlzone) %% Go over all zones

        zones(1:7,zone)=[g.cpmlzone(zone).cpmlindex,g.cpmlzone(zone).x-1,g.cpmlzone(zone).y-1,g.cpmlzone(zone).z-1,...
            g.cpmlzone(zone).dx,g.cpmlzone(zone).dy,g.cpmlzone(zone).dz];
        zones(8,zone)=g.cpmlzone(zone).m;
        zones(9,zone)=[g.cpmlzone(zone).smax];
        zones(10,zone)=[g.cpmlzone(zone).kmax] ;
        zones(11,zone)=[g.cpmlzone(zone).amax];
        zones(12,zone)=g.cpmlzone(zone).border;
        if strcmp(g.cpmlzone(zone).type,'PEC')
            zones(13,zone)=0;
        elseif strcmp(g.cpmlzone(zone).type,'PMC')
            zones(13,zone)=1;
        elseif strcmp(g.cpmlzone(zone).type,'NOTERM')
            zones(13,zone)=2;
        else
            error('Type of CPML number %d is not defined',zone);
        end

    end

end


if strcmp(type,'lorentz')  %% lorentz material
    for mat =1:length(g.lorentz)

        tempzone=zeros(1,3+g.info.mp*3);% 4 parameters needed per pole.
        tempzone(1)=g.lorentz(mat).epsilon;
        tempzone(2)=g.lorentz(mat).sigma;
        tempzone(3)=g.lorentz(mat).NP;

        for cnt=(0:g.lorentz(mat).NP-1)
            tempzone(4+cnt*3:4+(cnt+1)*3-1)=g.lorentz(mat).poles(cnt+1,:);
        end

        zones(:,mat)=tempzone;
    end
end







%% Lorentzzone

if strcmp(type,'lorentzzone')%% Explort the dielzones
    if (length(g.lorentzzone)==0)
        zones=[];
    end

    for zone =1:length(g.lorentzzone) %% Go over all zones

        for mat=1:length(g.lorentz)%% Go over all materials

            if strcmp(g.lorentzzone(zone).name,g.lorentz(mat).name)
                zones(:,zone)=[mat-1,g.lorentzzone(zone).x-1,g.lorentzzone(zone).y-1,g.lorentzzone(zone).z-1,...
                    g.lorentzzone(zone).dx,g.lorentzzone(zone).dy,g.lorentzzone(zone).dz];

            end

        end
    end

end


%% Outputzones
if strcmp(type,'outputzones')  %% lorentz material
    fields=[{'Ex'},{'Ey'},{'Ez'},{'Hx'},{'Hy'},{'Hz'}];
    
   
    
    

    for zone=1:length(g.outputzones)
         %% Set deltaFmin to foutstop if not specified. This way the
         %% deltaFmin is set by the number of timesteps.
        
        
     
            if (~isfield(g.outputzones(zone),'deltafmin')||((length(g.outputzones(zone).deltafmin)==0)))
                g.outputzones(zone).deltafmin=g.outputzones(zone).foutstop;
              
            end
        
      
        
        fieldzone=zeros(1,6);
        for cnt=(1:6)
            for cnt2=(1:length(g.outputzones(zone).field))

                if strcmp(g.outputzones(zone).field(cnt2),fields(cnt))
                    fieldzone(cnt)=1;

                end

            end
        end



        
        zones(:,zone)=[g.outputzones(zone).x-1,g.outputzones(zone).y-1,g.outputzones(zone).z-1,...
            g.outputzones(zone).dx,g.outputzones(zone).dy,g.outputzones(zone).dz,g.outputzones(zone).deltaT,...
            g.outputzones(zone).foutstart,g.outputzones(zone).foutstop,fieldzone ,g.outputzones(zone).deltafmin,g.outputzones(zone).average];
        

    end
end

if strcmp(type,'outputzonesname')  %% lorentz material
    zones=[];
    for zone=1:length(g.outputzones)
        zones=[zones g.outputzones(zone).name];

        for i=1:(zone*1024-length(zones))
            zones=[zones '?']; %padding strings with question marks
        end
    end
end



end

