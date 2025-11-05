# Generating HDR output images

When properly configured, ART can produce images suitable for [HDR displays](https://en.wikipedia.org/wiki/High-dynamic-range_television) as output.
Starting from version 1.16.4, the procedure has been greatly simplified, and it is a matter of a couple of clicks.

## Exporting as HDR

We can enable HDR output by installing the relevant [custom image format plugins](Customformats) from the [ART-imageio repository](https://github.com/artraweditor/ART-imageio/), following the instructions about the needed dependencies. 
If the plugins are properly configured, you should see three different HDR entriesin the list of available output formats (either in the batch queue or in the file save dialog): "AVIF (HDR PQ)", "JPEG-XL (HDR PQ)", and "HEIC (PQ HDR-TV 1000 nits)". 
Note that as of version 1.18, such plugins are shipped with the Windows installer of ART.

Which format to use depends on the target viewing device, and is briefly discussed at the end of this page. 
In all cases, the processing steps needed for producing HDR output are the same.


## Processing for HDR output

By default, the Tone Curve module of ART will clamp pixel values to force them to be in the range `[0, 1]`. 
This is not want you want for HDR output, since the whole point of HDR is to be able to display luminance values beyond diffuse white (which corresponds to a value of `1`). 

In order to process your picture for HDR, you can use the White Point slider in the Tone Curve module to set a higher clipping threshold. 
The slider will also automatically "stretch" the curve and modify the contrast formula as appropriate, so that in most cases setting a reasonable white point is all you need to do. Ideally the white point should be set to a value that is close to the peak brightness of the intended display medium, considering that a value of `1` should correspond to 100 nits (therefore, if your screen has a peak brightness of 1000 nits, a value of `10` is appropriate):

![tone-curve-white-point](tone-curve-white-point.png)


Note that when you increase the white point value, the preview of the picture in ART will appear too bright and clipped. This is because ART itself cannot display HDR pictures. A solution is to modify the white point only on export, taking advantage of the capability of ART to associate (and remember) different export profiles to different output formats. 
In this case, we might want to associate the following export profile to the AVIF output format that we have configured above:

```conf
[Version]
Version=1038

[ToneCurve]
WhitePoint=10
```

We can do that by saving the above in a partial profile `white-point-1000nits.arp` in the user profiles directory (e.g. `$HOME/.config/ART/profiles` on Linux), and selecting it as an export profile when saving in AVIF format:

![avif-export-profile](avif-export-profile.png)


## Viewing HDR files

In order to enjoy the benefits of HDR pictures, you need a HDR-capable display and a viewer that can perform the required tone mapping. At the time of writing, the easiest way to do so is to use Google Chrome on a recent Apple device (MacBook, iPad, or iPhone), using either AVIF or JPEG-XL as output format. 
Note however that unfortunately I do not have any of such devices, so I can't confirm that this works as intended.

An alternative is that of using an HDR-TV that supports the [PQ format](https://en.wikipedia.org/wiki/High-dynamic-range_television#PQ10_(PQ_format)) and that can read HEIC files. I am not sure how common is the support for HEIC stills in HDR-TVs, but I can at least confirm that it works on my TV (FWIW :-).
