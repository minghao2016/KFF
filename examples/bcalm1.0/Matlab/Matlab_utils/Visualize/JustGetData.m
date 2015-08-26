
%% Gets the data using the information in mplot 
%% Returns the data the updated mplot and the POSITION of the axis


function [data,mplot,POSITION]=JustGetData(mplot,hdf5_file)

global grid;
global directions;
global delta
global LIMIT;

%define names
directions=[{'x'},{'y'},{'z'}];
grids=[{'gridX'},{'gridY'},{'gridZ'}];

%define structures
GRID=struct('gridX',[],'gridY',[],'gridZ',[]);%% Used to store the information from the grid
LIMIT=struct('x',[],'y',[],'z',[]);%% x,y,z directions correspond to directions in the plot. They will be assigned directions on axis.
POSITION=struct('x',[],'y',[],'z',[]);%% x,y,z directions correspond to directions in the plot. They will be assigned to real dimentions

start=(hdf5read(hdf5_file,'start'));
delta=(hdf5read(hdf5_file,'delta'));
Datainfo.start=(hdf5read(hdf5_file,'startData'));
Datainfo.stop=(hdf5read(hdf5_file,'stopData'));
Datainfo.delta=(hdf5read(hdf5_file,'deltaData'));

Datainfo.name=(hdf5read(hdf5_file,'nameData'));
Datainfo.name=Datainfo.name.Data;

if ~isfield(mplot,'fieldname')
    mplot.fieldname=mplot.field;
    
end

mplot.mtitle= [mplot.fieldname ' ' ];
mplot.mtitle = regexprep(mplot.mtitle, '_', '\\_');

if ~isfield(mplot,'gridfield')
    plotm.gridfield='Center'; %% By default we plot everything in the center of the cell.
end




for (i=(1:length(grids)))
    temp=(hdf5read(hdf5_file,grids{i}));
    temp=getGrid(i,temp,mplot.gridfield);
    GRID=setfield(GRID,grids{i},temp);


end




%% Go over all directions and check if an output is specified.
for i=(1:length(directions))
    if ~isfield(mplot,directions(i))
        error(sprint('Specify what we need to do with the direction %s',direction{i}));
    end
end

%% Looking what needs to be put on axises. We start looking in the
%% directions.

axiscount=1;
mplot.allcount=0;%%accounts the amount of directions that go over the whole parameter space.
for i=(1:length(directions))
    if ischar(getfield(mplot,directions{i}))
        switch getfield(mplot,directions {i})


            case 'all'

                tempplot=getfield(GRID,grids{i});

                LIMIT=setfield(LIMIT,directions{i},(1:delta(i)+1));
               
                mplot.allcount=mplot.allcount+1;
                (start(i)+1:start(i)+delta(i)+1);
               
                POSITION=setfield(POSITION,directions{mplot.allcount},tempplot(start(i)+1:start(i)+delta(i)+1));

                %%plot=setfield(plot,directions{i},tempplot(start(i)+1:start(i)+delta(i)+1));
                mplot.names{mplot.allcount}=[directions{i} ' (m)'];
                axiscount=axiscount+1;


            otherwise
                error(['Unknown field in the ' directions{i} 'direction' ]);


        end

    end

    if isfloat(getfield(mplot,directions{i}))
        LIMIT=setfield(LIMIT,directions{i},getfield(mplot,directions{i}));
        axiscount=axiscount+1;
        mplot.mtitle=[mplot.mtitle directions{i} '=' num2str(getfield(mplot,directions{i})) ' '];

    end
end

%% Reading the data


if (strcmp(mplot.field,'topology')||strcmp(mplot.field,'mattype')||strcmp(mplot.field,'property'))
    topologylike=1;
else
    topologylike=0;
end



if strcmp(mplot.field,'topology')
    [mattype,dimworked]=extract(hdf5_file,'mattype');
    dim=size(mattype);
    [property,dimworked]=extract(hdf5_file,'property');
    try 
    [amat,dimworked]=extract(hdf5_file,'amat');
    catch
    amat=uint32(INTMAX('uint32')); %% No anisotropy in this simulation, so we have backwards compatibility.
    end
    [data,cell]=processtopology(mplot,mattype,property,amat);
    size(data)
    mplot.cell=cell;

else
    [data,dimworked]=extract(hdf5_file,mplot.field);
    dim=size(data);
    cell=[];
end




if ischar(getfield(mplot,'data'))
    if strcmp(getfield(mplot,'data'),'all')
        LIMIT.data=(1:dim(end));
        mplot.allcount=mplot.allcount+1;
        mplot.names{mplot.allcount}=[Datainfo.name];
        POSITION=setfield(POSITION,directions{mplot.allcount},(Datainfo.start:Datainfo.delta:Datainfo.stop));
        axiscount=axiscount+1;
    else
        error('Unknown field for data: Enter either the index or all')
    end
end

if isfloat (getfield(mplot,'data'))

    if mplot.data<=dim(end)
        LIMIT.data=(getfield(mplot,'data'));
        mplot.mtitle=[mplot.mtitle Datainfo.name '=' num2str(getfield(mplot,'data')) ' '];
    else
        error('Index data out of bounds')
    end

end


%% For topology plot the LIMIT.data should be the dimworked direction.

if topologylike
    if ischar(getfield(mplot,directions{dimworked}))
        switch getfield(mplot,directions {dimworked})

            case 'all'
                tempplot=getfield(GRID,grids{i});
                LIMIT=setfield(LIMIT,'data',(1:delta(dimworked)+1));

            otherwise
                error(['Unknown field in the ' directions{i} 'direction' ]);
        end
    end
    if isfloat(getfield(mplot,directions{dimworked}))
        LIMIT.data=(getfield(mplot,directions{dimworked}));
        LIMIT.data=1;
    end
end


%% Extracting the data

switch dimworked
    case 4
        data=data(LIMIT.x,LIMIT.y,LIMIT.z,LIMIT.data);
    case 3
%               size(data)
%         size(POSITION.x)
%         size(POSITION.y)
%         size(POSITION.z)
%               size(data)
%         size(LIMIT.x)
%         size(LIMIT.y)
%         size(LIMIT.z)
try
                LIMIT.x;
        LIMIT.y;
        LIMIT.data;
        size(data);
        data=data(LIMIT.x,LIMIT.y,LIMIT.data);

catch
     data=data(LIMIT.y,LIMIT.z,LIMIT.data);
      warning('Something might be wrong y=z=all')  
end
    case 2

        data=data(LIMIT.x,LIMIT.data);

    case 1
        data=data(LIMIT.data);

end
data=squeeze(data);



%% Decalibrate data

if isfield(mplot,'calfile')
  
    mplotcal=rmfield(mplot,'calfile');
    [dataCal,mplotcal,posCal]=JustGetData(mplotcal,mplot.calfile);%% get the data from the calfile
    data=(data-dataCal);
 
end

end