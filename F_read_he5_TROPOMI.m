function datavar = F_read_he5_TROPOMI(filename,swathname,varname,geovarname, detailsres_varname)
	if isempty(swathname)
		swathname = '';
	end
	swn = ['PRODUCT/'];
	
	% varname = {'latitude','longitude','time_utc','nitrogendioxide_tropospheric_column','qa_value', 'nitrogendioxide_tropospheric_column_precision'};
	% geovarname = {'solar_zenith_angle','viewing_zenith_angle','latitude_bounds','longitude_bounds'};
	% detailsres_varname = {'cloud_fraction_crb_nitrogendioxide_window'};
	
	file_id = H5F.open (filename, 'H5F_ACC_RDONLY', 'H5P_DEFAULT');

	for i = 1:length(geovarname)
		DATAFIELD_NAME = [swn,'SUPPORT_DATA/GEOLOCATIONS/',geovarname{i}];
		data_id=H5D.open(file_id, DATAFIELD_NAME);
		%     ATTRIBUTE = 'Title';
		%     attr_id = H5A.open_name (data_id, ATTRIBUTE);
		%     long_name=H5A.read (attr_id, 'H5ML_DEFAULT');
		datavar.(geovarname{i})=H5D.read(data_id,'H5T_NATIVE_DOUBLE', 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT');
	
	end

	for i = 1:length(detailsres_varname)
		DATAFIELD_NAME = [swn,'SUPPORT_DATA/DETAILED_RESULTS/',detailsres_varname{i}];
		data_id=H5D.open(file_id, DATAFIELD_NAME);
		%     ATTRIBUTE = 'Title';
		%     attr_id = H5A.open_name (data_id, ATTRIBUTE);
		%     long_name=H5A.read (attr_id, 'H5ML_DEFAULT');
		datavar.(detailsres_varname{i})=H5D.read(data_id,'H5T_NATIVE_DOUBLE', 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT');
   
	end

	for i = 1:length(varname)
		% Open the dataset.
		DATAFIELD_NAME = [swn,varname{i}];
	
		data_id = H5D.open (file_id, DATAFIELD_NAME);
		% Read attributes.
	
	%    try
	%        ATTRIBUTE = 'Offset';
	%        attr_id = H5A.open_name (data_id, ATTRIBUTE);
	%        datavar.(varname{i}).(ATTRIBUTE) = H5A.read (attr_id, 'H5ML_DEFAULT');
	%        
	%        ATTRIBUTE = 'ScaleFactor';
	%        attr_id = H5A.open_name (data_id, ATTRIBUTE);
	%        datavar.(varname{i}).(ATTRIBUTE) = H5A.read (attr_id, 'H5ML_DEFAULT');
	%    catch
	%        warning('No attributes to read!')
	%    end
		
		%%%%datavar.(varname{i}).data=H5D.read (data_id,'H5T_NATIVE_DOUBLE', 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT');
	
		% Read the dataset.
		
		% condition added by Lorena Castro (the format of TROPOMI date-time dataset is different that OMI one)
		if strcmp(varname(i),'time_utc')
			datavar.(varname{i})=cell2mat(H5D.read(data_id));
		else
			datavar.(varname{i})= H5D.read (data_id,'H5T_NATIVE_DOUBLE', 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT');
		
		end
		%     datavar.(varname{i}).name = long_name(:)';
	end

	% Close and release resources.
	% H5A.close (attr_id)
	H5D.close (data_id);
	H5F.close (file_id);
