function output = F_subset_TROPOMI(inp)
% subset NASA OMNO2, output consistent format like F_subset_IASI.m
% updated from F_download_subset_OMNO2.m by Kang Sun on 2017/07/13
% updated by Lorena Castro to subset TROPOMI data

sfs = filesep;
olddir = pwd;

ntrack = 450; % TROPOMI

Startdate = inp.Startdate;
Enddate = inp.Enddate;
MinLat = inp.MinLat;
MinLon = inp.MinLon;
MaxLat = inp.MaxLat;
MaxLon = inp.MaxLon;

% grey area, L2 pixel center cannot be there, but pixel boundaries can
MarginLat = 0.5;
MarginLon = 0.5;

% max cloud fraction and SZA, VZA, QA and min and max values for NO2
MaxCF = inp.MaxCF;
MaxSZA = inp.MaxSZA;
MaxVZA = inp.MaxVZA;
MinQA = inp.MinQA;
MaxNO2 = inp.MaxNO2;
MinNO2 = inp.MinNO2;

L2dir = inp.L2dir;

if ~isfield(inp,'usextrack')
    usextrack = 1:450;
else
	usextrack = inp.usextrack;
end

swathname = '';

% variables to read from OMI L2 files
varname = {'latitude','longitude','time_utc','nitrogendioxide_tropospheric_column','qa_value', 'nitrogendioxide_tropospheric_column_precision'};

geovarname = {'solar_zenith_angle','viewing_zenith_angle','latitude_bounds','longitude_bounds'};

detailsres_varname = {'cloud_fraction_crb_nitrogendioxide_window'};

TAI93ref = datenum('Jan-01-1993');

day_array = (datenum(Startdate):1:datenum(Enddate))';
datevec_array = datevec(day_array);

%Jan01_array = datevec_array;
%Jan01_array(:,2:end) = 0;
%doy_array = day_array-datenum(Jan01_array);
%year_array = datevec_array(:,1);

nday = length(day_array);

lonc = single([]);
latc = lonc;
lonr = lonc;latr = lonc;
qa_value = lonc;
cloudfrac = lonc;
sza = lonc;
vza = lonc;

ift = lonc;

utc = double([]);
colno2 = lonc;
colno2error = lonc;



for iday = 1:nday
    day = mat2str(datevec_array(iday,1:3));
    day_pattern = datestr(day,'yyyymmdd');
    
    % search files per day (considering that ALL the files are in the same directory)
    pat = strcat('S5P_*__NO2____',day_pattern,'*');
    he5fn = dir(fullfile(L2dir, pat));
   
    
    if isempty(he5fn);
		warning([day_pattern,' contains no HE5 files!']);
		continue;
    end;
    for ifile = 1:length(he5fn)
        
        fn = [L2dir,he5fn(ifile).name];
        
        % open the he5 file, massaging the data
        datavar = F_read_he5_TROPOMI(fn,swathname,varname,geovarname, detailsres_varname);
        xtrackmask = false(size(datavar.latitude));
        xtrackmask(usextrack,:) = true;
        xtrack_N = repmat((1:ntrack)',[1,size(datavar.latitude,2)]);
        
        % conditions related with MinQA, MaxVZA, MaxNO2 and MinNO2 were added for TROPOMI subset
        validmask = datavar.latitude >= MinLat-MarginLat & datavar.latitude <= MaxLat+MarginLat & ...
            datavar.longitude >= MinLon-MarginLon & datavar.longitude <= MaxLon+MarginLon & ...
        	datavar.qa_value > MinQA & ...
            datavar.cloud_fraction_crb_nitrogendioxide_window <= MaxCF & ...
            datavar.solar_zenith_angle <= MaxSZA & ...
            datavar.viewing_zenith_angle <= MaxVZA & ...
            datavar.nitrogendioxide_tropospheric_column <= MaxNO2 & ...
            datavar.nitrogendioxide_tropospheric_column >= MinNO2 & ...
            xtrackmask;
        
        if sum(validmask(:)) > 0
        	[d,name,ext] = fileparts(fn);
            disp(['You have ',sprintf('%5d',sum(validmask(:))),' valid L2 pixels on the file ',name,ext,'.']);
        end
        
        % next 2 lines were updated for TROPOMI subset
        %tempVCD = datavar.nitrogendioxide_tropospheric_column.data(validmask);	%updated
        %tempVCD_unc = datavar.nitrogendioxide_tropospheric_column_precision.data(validmask); %updated
        tempVCD = datavar.nitrogendioxide_tropospheric_column(validmask);
        tempVCD_unc = datavar.nitrogendioxide_tropospheric_column_precision(validmask);
        
        
        %tempAMF = datavar.AmfTrop.data(validmask); 
        
        tempxtrack_N = xtrack_N(validmask);
        
       	%next 6 lines were added to deal with date-time format in TROPOMI
        %xTime_string = num2str(datavar.time_utc);
        %xTime_string = num2str(datavar.time_utc);
        xTime_string = string(datavar.time_utc);
        xTime_string = string(datavar.time_utc);
        xTime_string = strrep(xTime_string, 'T', ' '); 
        xTime_string = strrep(xTime_string, 'Z', '');
        xTime_aux = datetime(xTime_string,'InputFormat','yyyy-MM-dd HH:mm:ss.SSSSSS');
        xTime_aux = datenum(xTime_aux);
        xTime = repmat(xTime_aux',[ntrack,1]);
        
        % next line it's no needed due to TROPOMI time sds is already in UTC (by Lorena Castro)
        %%%tempUTC = double(xTime(validmask))/86400+TAI93ref;
        
        tempUTC = xTime(validmask);
        
        corner_data_size = size(datavar.latitude_bounds);

% next lines were commented by Lorena Castro due to these are no applied to TROPOMI data
%        if corner_data_size(3) == 4
%            Lat_lowerleft = squeeze(datavar.latitude_bounds(:,:,1));
%            Lat_lowerright = squeeze(datavar.latitude_bounds(:,:,2));
%            Lat_upperleft = squeeze(datavar.latitude_bounds(:,:,4));
%            Lat_upperright = squeeze(datavar.latitude_bounds(:,:,3));
%            
%            Lon_lowerleft = squeeze(datavar.longitude_bounds(:,:,1));
%            Lon_lowerright = squeeze(datavar.longitude_bounds(:,:,2));
%            Lon_upperleft = squeeze(datavar.longitude_bounds(:,:,4));
%            Lon_upperright = squeeze(datavar.longitude_bounds(:,:,3));
%        elseif corner_data_size(1) == 4

        Lat_lowerleft = squeeze(datavar.latitude_bounds(1,:,:));
        Lat_lowerright = squeeze(datavar.latitude_bounds(2,:,:));
        Lat_upperleft = squeeze(datavar.latitude_bounds(4,:,:));
        Lat_upperright = squeeze(datavar.latitude_bounds(3,:,:));
            
        Lon_lowerleft = squeeze(datavar.longitude_bounds(1,:,:));
        Lon_lowerright = squeeze(datavar.longitude_bounds(2,:,:));
        Lon_upperleft = squeeze(datavar.longitude_bounds(4,:,:));
        Lon_upperright = squeeze(datavar.longitude_bounds(3,:,:));
%        end
        tempLatC = datavar.latitude(validmask);
        tempLonC = datavar.longitude(validmask);
        
        tempLat_lowerleft = Lat_lowerleft(validmask);
        tempLat_lowerright = Lat_lowerright(validmask);
        tempLat_upperleft = Lat_upperleft(validmask);
        tempLat_upperright = Lat_upperright(validmask);
        
        tempLon_lowerleft = Lon_lowerleft(validmask);
        tempLon_lowerright = Lon_lowerright(validmask);
        tempLon_upperleft = Lon_upperleft(validmask);
        tempLon_upperright = Lon_upperright(validmask);
        
        tempQA = datavar.qa_value(validmask);
        tempCF = datavar.cloud_fraction_crb_nitrogendioxide_window(validmask);

        tempSZA = datavar.solar_zenith_angle(validmask);
        tempVZA = datavar.viewing_zenith_angle(validmask);
        
                        
        lonc = cat(1,lonc,single(tempLonC(:)));
        latc = cat(1,latc,single(tempLatC(:)));
        templonr = [tempLon_lowerleft(:),tempLon_upperleft(:),...
                    tempLon_upperright(:),tempLon_lowerright(:)];
        lonr = cat(1,lonr,single(templonr));
        templatr = [tempLat_lowerleft(:),tempLat_upperleft(:),...
                    tempLat_upperright(:),tempLat_lowerright(:)];
        latr = cat(1,latr,single(templatr));
        
        qa_value = cat(1,qa_value,single(tempQA(:)));
        cloudfrac = cat(1,cloudfrac,single(tempCF(:)));
        
        sza = cat(1,sza,single(tempSZA(:)));
        vza = cat(1,vza,single(tempVZA(:)));
        
        ift = cat(1,ift,single(tempxtrack_N(:)));
        utc = cat(1,utc,double(tempUTC(:)));
        
        colno2 = cat(1,colno2,single(tempVCD(:)));
        colno2error = cat(1,colno2error,single(tempVCD_unc(:)));
        
        
    end
end

output.lonc = lonc;
output.lonr = lonr;
output.latc = latc;
output.latr = latr;

output.qa_value = qa_value;
output.cloudfrac = cloudfrac;

output.sza = sza;
output.vza = vza;

output.ift = ift;
output.utc = utc;

output.colno2 = colno2;
output.colno2error = colno2error;

cd(olddir)
