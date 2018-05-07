addnode (intensity, r, g, b, a: integer) this command adds a new point to the color table.
azimuth (degree: integer) This command rotates the rendering.
azimuthelevation (azi, elev: integer) Sets the viewer location.
backcolor (r, g, b: integer) Changes the background color, for example backcolor(255, 0, 0) will set a bright red background
bmpzoom (z: integer) copy and save bitmaps at higher resolution than screen. bmpzoom(2) will save images at twice the resolution.
cameradistance (z: float) Sets the viewing distance from the object.
changenode (index, intensity, r, g, b, a: integer) This command adjusts a point in the color table.
clip (depth: float) Creates a clip plane that hides information close to the viewer.
clipazimuthelevation (depth, azi, elev: float) Set a view-point independent clip plane.
colorbarposition (p: integer) Sets the position of the colorbar: 1=bottom, 2=left, 3=top, 4=right.
colorbarsize (f) Change width of color bar f is a value 0.01..0.5 that specifies the fraction of the screen used by the colorbar
colorbarvisible (visible: boolean) Shows a colorbar on the main images.
colorname (filename: string) Loads  the requested colorscheme for the background image.
contrastformvisible (visible: boolean) Shows or hides the contrast and color window.
contrastminmax (min, max: float) sets the minumum nd maximum value for the color lookup table.
cutout (l, a, s, r, p, i: float) Selects a sector to remove from rendering view.
elevation (deg: integer) changes the render camera up or down.
exists (filename): boolean Returns true if file exists.
extract (levels, dilatevox: integer; oneobject: boolean) Attempts to remove noise speckles from dark regions (air) around object. Levels=1..5 (larger for larger surviving image), Dilate=0..12 (larger for larger surround). You can also specify if there is a single object or multiple objects
fontname (filename) Changes font used for colorbar. For example, "fontname('ubuntu')" will use the Ubuntu font.
linecolor (r, g, b: integer) Changes the color for the crosshairs shown on 2D slices. For example linecolor(255, 0, 0) will show red crosshairs.
linewidth (pixels: integer) Adjusts thickness of crosshairs shown on 2D slices. Set to zero to hide crosshairs.
loaddrawing (filename) Load an image for editing with the drawing tools
loaddti (filename: string) If you provide a name of a FSL-format FA image, the corresponding V1 will be loaded
loadimage (filename: string) Opens a NIfTI format image to view.
loadimagevol (filename: string; vol: integer) Use to load a specific volume in a 4D dataset, for example loadimagevol('fmri.nii',4) will load the 4th volume of an fMRI dataset.
maximumintensity (mip_on: boolean) Changes the rendering mode between standard and Maximum Intensity Projection.
modalmessage (str: string) Shows a modal dialog, script stops until user presses 'OK' button to dismiss dialog.
modelessmessage (str: string) Shows text in the rendering window. This text is displayed until the text is changed.
mosaic (str: string) Shows a series of 2D slices.
orthoview (x, y, z: float) Shows a 2D projection view of the brain.
orthoviewmm (x, y, z: float) Shows a 2D projection view of the brain. Crosshair at X,Y,Z coordinates specified in millimeters.
overlaycloseall () This function has no parameters. All open overlays will be closed.
overlaycolorfromzero (fromzero: boolean) If set to false, then the full color range is used to show the overlay.
overlaycolorname (overlay: integer; filename: string) Set the colorscheme for the target overlay to a specified name.
overlaycolornumber (overlay, color_index: integer) Sets the color scheme for a overlay.
overlayhidezeros (mask: boolean) If true, values with intensity of zero are always transparent.
overlaylayertransparencyonbackground (overlaylayer, percent: integer) Specifies a custom transparency for a single overlay layer on top of the background image
overlaylayertransparencyonoverlay (layer, percent: integer) allows you to make a specific overlay volume have a custom transparency on other overlay images.
overlayload (filename: string) integer; Will add the overlay named filename and return the number of the overlay.
overlayloadcluster (filename: string; threshold, clusterMM3: float; lSaveToDisk: boolean) integer; Will add the overlay named filename, only display voxels with intensity greater than threshold with a cluster volume greater than clusterMM and return the number of the overlay.
overlayloadsmooth (smooth: boolean) Determines whether overlays are interpolated using trilinear interpolation.
overlaymaskedbybackground (mask: boolean) If true, than a overlay will be transparent on any voxel where the background image is transparent.
overlayminmax (overlay: integer; min, max: float) Sets the color range for the overlay.
overlaytransparencyonbackground (percent: integer) Controls the opacity of the overlays on the background.
overlaytransparencyonoverlay (percent: integer) Controls the opacity of the overlays on other overlays.
overlayvisible (overlay: integer; visible: boolean) The feature allows you to make individual overlays visible or invisible.
perspective (on: boolean) Turns on or off perspective rendering.
quit () Terminates the program. Use with caution. This allows external programs to launch this software and quit once they are done.
radiological (visible: boolean) If true, the 2D slices displayed in radiological convention (left on right: camera inferior/anterior to object) otherwise neurological (superior/posterior)
resetdefaults () Sets all of the user adjustable settings to their default values.
savebmp (filename: string) Saves the currently viewed image as a PNG format compressed bitmap image.
scriptformvisible (visible: boolean) Shows or hides the scripting window.
setcolortable (tablenum: integer) changes the color scheme used to display an image.
shaderadjust (property: string; value: float) Sets one of the user-adjustable properties.
shaderlightazimuthelevation (azi, elev: integer) Changes location of light source.
shadername (filename: string) Loads the requested shader.
shaderquality1to10 (value: integer) Renderings can be quick or slow but precise, corresponding to values 1-10.
shaderupdategradients () This command re-calculates the gradients for surface direction and magnitude.
sharpen () Emphasize edges in image
slicetext (visible: boolean) If true, the 2D slices will be displayed with text.
toolformvisible (visible: boolean) Shows or hides the tools panel.
version () : string Returns the software version.
viewaxial (std: boolean) creates rendering from an axial viewpoint.
viewcoronal (std: boolean) creates rendering from a coronal viewpoint.
viewsagittal (std: boolean) creates rendering from an sagittal viewpoint.
wait (msec: integer) The program pauses for the specified duration. For example wait(1000) delays the script for one second.
