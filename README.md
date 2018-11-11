# ThreeLayerHeightBlendTesselationDisplacementShader
1. 3 layers of materials height blended together using splat map.  
1. Distance based tesselation and displacement.  
1. Detailed control.  

If you want to have shadows on tesselated geometry, add "addshadow" to the end of the line 57.

![](https://i.imgur.com/mb8M3mO.png)
Maybe this is not the best example, but I did not have more suitable textures.

# How to use
1. Create new material and assign this shader to it.
1. Assign splat map. R component represents first layer, G - second, B - third.  
1. Assign textures(Albedo, Normal, Roughness, Height) for each layer.  
1. Change settings so that the material looks good.  
