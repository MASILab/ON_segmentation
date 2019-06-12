# ON-segmentation
Segmentation of the Optic Nerve in MR and CT

## Requirements
* Matlab w/ Image Processing Toolbox
* Optic Nerve Atlas(es) (Cropped?)
* [ANTs](http://stnava.github.io/ANTs/)
* [mipav](https://mipav.cit.nih.gov/)
* JLF - Joint Label Fusion?
* [NiftyReg](http://cmictig.cs.ucl.ac.uk/wiki/index.php/NiftyReg)

Input should be axial
other matlab files:
init_ON_MR_v2,localize_ON_MR_affine,crop_ON_MR_v2,register_ON_MR_v2,fuse_ON_MR_v2,uncrop_ON_MR_v2


tprintf,get_file_name,make_dir_if_doesnt_exist,get_file_name,load_untouch_nii_gz,
save_untouch_nii_gz, boxtprintf,run_statistical_fusion_jist
