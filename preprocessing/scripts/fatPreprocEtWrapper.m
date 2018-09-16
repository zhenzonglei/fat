% 
% ﻿Diffusion pipeline that combines Vistasoft, MRtrix, LiFE and AFQ to produce functional defined white matter tracts.
%  It requires the toolboxes mentioned above, as well as, fROI defined using vistasoft. 
%The pipeline is orgnized as bellow.

clear all;

% The following parameters need to be adjusted to fit your system
fatDir=fullfile('/sni-storage/kalanit/biac2/kgs/projects/NFA_tasks/data_mrAuto');
anatDir_system =fullfile('/biac2/kgs/3Danat');
anatDir =('/sni-storage/kalanit/biac2/kgs/3Danat');


sessid={'01_sc_dti_080917' '02_at_dti_080517' '03_as_dti_083016'...
    '04_kg_dti_101014' '05_mg_dti_071217' '06_jg_dti_083016'...
    '07_bj_dti_081117' '08_sg_dti_081417' '10_em_dti_080817'...
    '12_rc_dti_080717' '13_cb_dti_081317' '16_kw_dti_082117'...
    '17_ad_dti_081817' '18_nc_dti_090817'}


anatid={'siobhan' 'avt' 'anthony_new_recon_2017'...
    'kalanit_new_recon_2017' 'mareike' 'jesse_new_recon_2017'...
    'brianna' 'swaroop' 'eshed' 'richard' 'cody' 'kari' 'alexis' 'nathan'}

runName={'96dir_run1'}

ROIs={'rh_OTS_union_morphing_reading_vs_all.mat' 'rh_pSTS_MTG_union_morphing_reading_vs_all.mat' 'rh_IFG_union_morphing_reading_vs_all.mat' 'rh_ISMG_morphing_reading_vs_all.mat'}
    
t1_name=['t1.nii.gz'];

for s=1:length(sessid)  % Ok, here we go

%1) Prepare fat data and directory structure
for r=1:length(runName)
    
% The following parameters need to be adjusted to fit your system
anatDir_system_current=fullfile(anatDir_system, anatid);
anatDir_system_output=fullfile('/biac2/kgs/projects/NFA_tasks/data_mrAuto/', sessid, runName(r), 't1');

% here we go
fatPrepare(fatDir,sessid(s), anatDir_system_current{1}, anatDir_system_output{1}, r)
end

%2) Preprocess the dti data using vistasoft
for r=1:length(runName)
fatPreprocess(fatDir,sessid(s),runName(r),t1_name,1)
end

%3) Make wm mask from freesurfer output 
fatMakeWMmask(fatDir, anatDir_system, anatid(s), sessid(s),t1_name,'wm', 1)

%4) Run MRtrix to create candidate connectomes with different parameters
for r=1:length(runName)
fatCreateEtConnectome(fatDir, sessid(s), runName(r));
end

%5) Concatenate the fg to construct the final ET connectome
for r=1:length(runName)
        for i=1:5
        x=[0.25 0.5 1 2 4]
        fgInName{i}=['run' num2str(r) '_aligned_trilin_csd_lmax8_run' num2str(r) '_aligned_trilin_brainmask_run' num2str(r) '_aligned_trilin_wm_prob-curv' num2str(x(i)) '-cutoff0.1-200000.pdb']
        end
        fgOutName=['run' num2str(r) '_lmax8_curvatures_concatenated.mat']
        fatConcateFg(fatDir, sessid(s), runName(r), fgInName,fgOutName);
end

%6) Run LiFE to optimize the ET connectome
for r=1:length(runName)
        fgname=['run' num2str(r) '_lmax8_curvatures_concatenated.mat']
        fatRunLife(fatDir, sessid(s), runName(r),fgname,t1_name);
end

% 7) Run AFQ to classify the fibers
fatMakefsROI(anatDir,anatid{s},sessid{s},1) % first create the ROIs needed for AFQ using freesurfer
for r=1:length(runName)
fgName=['run' num2str(r) '_lmax8_curvatures_concatenated_optimize_it500_new.mat']
fatSegmentConnectome(fatDir, anatDir, anatid(s), sessid{s}, runName{r}, fgName)
end

%8) Convert vista ROI to functional ROI 
for r=1:length(runName)
fatVistaRoi2DtiRoi(fatDir, sessid{s}, runName{r}, ROIs, t1_name)
fatDtiRoi2Nii(fatDir, sessid{s}, runName{r}, ROIs)
end

% %9) Define FDFs and get fiber count for classified connectome
for r=1:length(runName)
    foi=1:28; %choose the fibers of interest, I chose all
    fgName=['run' num2str(r) '_lmax8_curvatures_concatenated_optimize_it500_new_classified.mat'];
    fgDir=fullfile(fatDir,sessid{s},runName{r},'dti96trilin','fibers','afq');
    fatFiberIntersectRoi(fatDir, fgDir, sessid{s}, runName{r}, fgName, ROIs, foi, 7)
end
%
% %10) Define FDFs and get fiber count for whole connectome
for r=1:length(runName)
    fgName=['run' num2str(r) '_lmax8_curvatures_concatenated_optimize_it500_new.mat'];
    fgDir=fullfile(fatDir,sessid{s},runName{r},'dti96trilin','fibers');
    fatFiberIntersectRoi(fatDir, fgDir, sessid{s}, runName{r}, fgName, ROIs, 1, 7)
end


 % 11) plot fibers
for r=1
    for n=1:length(ROIs)
        ROIName=strsplit(ROIs{n},'.')
        ROIfg=[ROIName{1} '_r7.00_run' num2str(r) '_lmax8_curvatures_concatenated_optimize_it500_new_classified.mat'];
        if n<5
            hem='lh'
            foi=[11 13 15 19 27 21];
        else
            hem='rh'
            foi=[12 14 16 20 22 28];
        end
        fatRenderFibers(fatDir, sessid{s}, runName{r}, ROIfg, foi,t1_name, hem)
    end
end

for r=1
    for n=1:length(ROIs)
        ROIName=strsplit(ROIs{n},'.')
        ROIfg=['run1_lmax8_curvatures_concatenated_optimize_it500_new_classified.mat'];
        if n<5
            hem='lh'
            foi=[11 13 15 19 21];
        else
            hem='rh'
            foi=[12 14 16 20 22 28];
        end
        fatRenderFibersWholeConnectome(fatDir, sessid{s}, runName{r}, ROIfg, foi,t1_name, hem)
    end
end

% %11) Extract fiber proprieties
% for r=1:length(runName)
%     for n=1:length(ROIs)
%      ROIName=strsplit(ROIs{n},'.')   
%      ROIfg=[ROIName{1} '_r5.00_run' num2str(r) '_aligned_trilin_csd_concatenated_run' num2str(r) '_aligned_trilin_brainmask_run' num2str(r) '_aligned_trilin_wm_prob-200000_optimize_it500_new_classified.mat']
%      fatTractDmr(fatDir, sessid{s}, runName{r}, ROIfg)
% %fatTractQmr(fatDir, sessid(s), runName(r), fgName, qmrDir)
%     end
% end
% 
% 12) Extract roi selectivity
% fatRoiSelectivity(fatDir, sessid, mapName, roiName)
% fatRoiSelectivityCv(fatDir, sessid, contrast, roiName)
% 
% %% Script to merge data
% 1) Normalize fiber count
% normFiberCount(afqFiberCountFile, rawFiberCountFile) 
% 2) Collect all data to a structure
% runMetaDataCollect

end