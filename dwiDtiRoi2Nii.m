function dwiDtiRoi2Nii(dwiDir, sessid, runName, roiName)
% dwiDtiRoi2Nii(dwiDir, sessid, runName, roiName)
% Write the dtiRoi mat files generated by dwiVistaRoi2DtiRoi to nii volume
% runName, cell array for run name
% roiName, cell array for roi name, with .mat ext

for s = 1:length(sessid)
    for r = 1:length(runName)
        fprintf('Write Dti ROI to Nii for %s:%s\n',sessid{s},runName{r});
        runDir = fullfile(dwiDir,sessid{s},runName{r},'dti96trilin');
        
        % use ref image info to convert the acpa coords to img coords
        img = niftiRead(fullfile(runDir,'bin','b0.nii.gz'),[]);
        for i = 1:length(roiName)
            roiFile = fullfile(runDir,'ROIs',roiName{i});
            if exist(roiFile, 'file')
                roi = dtiReadRoi(roiFile);
                coords = roi.coords;
                % convert vertex acpc coords to img coords
                imgCoords  = mrAnatXformCoords(img.qto_ijk, coords);
                % get coords for the unique voxels
                imgCoords = unique(ceil(imgCoords),'rows');
                
                % make a 3D image
                roiData = zeros(img.dim);
                roiData(sub2ind(img.dim, imgCoords(:,1), imgCoords(:,2), imgCoords(:,3))) = 1;
                
                % change img data
                img.data = roiData;
                img.cal_min = min(roiData(:));
                img.cal_max = max(roiData(:));
                
                % write the nifti file
                [~,roiNameWoExt] = fileparts(roiName{i});
                img.fname = fullfile(runDir,'ROIs', [roiNameWoExt,'.nii.gz']);                
                writeFileNifti(img);
            end
        end
    end
end