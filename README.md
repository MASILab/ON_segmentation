# ON\_segmentation
Segmentation of the Optic Nerve in MR

## Requirements
* Matlab w/ Image Processing Toolbox
* Optic Nerve Atlas(es) (Cropped?)
* [ANTs](http://stnava.github.io/ANTs/)
* [mipav](https://mipav.cit.nih.gov/)
* JLF - Joint Label Fusion?
* [NiftyReg](http://cmictig.cs.ucl.ac.uk/wiki/index.php/NiftyReg)
* ps2pdf (bundled with [Ghostscript](https://www.ghostscript.com))

**Note:** Input MRI should be axial

## Usage
### Perform Segmentation
```matlab
addpath('ON_segmentation/segment_ON_MR');

segment_ON_MR_v2(test_images,atlas_dir,ANTS_path,niftyreg_path,utils_path,output_dir,mipav_path,jlf_dir,leave_out)
```
*test_images* - Input image(s) to be segmented

*atlas_dir* - Directory of the atlas, should have subdirectories atlas_images and atlas_labels

*ANTS_path* - path to ANTs registration bin

*niftyreg_path* - path to niftyreg bin for affine localization

*utils_path* - 'ON_segmentation/segment_ON_MR/utils'

*output_dir* - Directory to save the results

*mipav_path* - Path to mipav

*jlf_dir* - Path to JLF executable (bin)

*leave_out* - (Optional) the atlas number (based on atlas image order) to be excluded, for use with cross validation.

### Generate Segmentation Visualization Report
```matlab
addpath('ON_segmentation/segment_ON_MR/utils');
addpath('ON_segmentation/segment_ON_MR/PDF');
ON_MR_segmentation_pdf_report_v2_0_0(raw_fname, seg_fname, pdf_fname, tmp_dir, proj_name, subj_name, expr_name, atlas_path, scan_type)
```
*raw_fname* - the raw (intensity image filename -- .nii.gz)

*seg_fname* - the estimated segmentation -- .nii.gz

*pdf_fname* - the final pdf filename

*tmp_dir* - the directory to store temporary output

*proj_name* - the name of the project

*subj_name* - the name of the subject

*expr_name* - the name of the experiment

*atlas_path* - path to atlases used for segmentation

*scan_type* - name of MRI scan protocol

### Perform Sheath Segmentation 
**Note:** Report generated automatically
