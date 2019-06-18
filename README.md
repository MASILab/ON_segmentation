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

## Step 1: Segment the Optic Nerve
### Perform Segmentation
*/segment_ON_MR*

**segment\_ON\_MR\_v2**(test\_images,atlas\_dir,ANTS\_path,niftyreg\_path,utils\_path,output\_dir,mipav\_path,jlf\_dir,varargin)

### Generate Report
*/segment_ON_MR/PDF*

**ON\_MR\_segmentation\_pdf\_report\_v2\_0\_0**()

## Step 2: Segment the Optic Nerve Sheath
