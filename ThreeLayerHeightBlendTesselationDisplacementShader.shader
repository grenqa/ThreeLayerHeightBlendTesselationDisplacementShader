Shader "Grenqa/ThreeLayerHeightBlendTesselationDisplacement"
{
    Properties
    {
		_Tiling1 ("Tiling 1", Vector) = (1, 1, 0, 0)
		[NoScaleOffset] _Albedo1("Albedo 1", 2D) = "white" {}
		[NoScaleOffset] [Normal] _Normal1("Normal 1", 2D) = "bump" {}
		[NoScaleOffset] _Roughness1("Roughness 1", 2D) = "gray" {}
		[NoScaleOffset] _Height1("Height 1", 2D) = "gray" {}
		[Space(10)]
		_Height1_Min("Height Min 1", Range(0, 1)) = 0
		_Height1_Max("Height Max 1", Range(0, 1)) = 1
		_Height1_Contrast("Height Contrast 1", Range(0, 4)) = 1
		_BlendDepth1("Blend Depth 1", Range(.001, 1)) = .3

		[Space(40)]

		_Tiling2("Tiling 2", Vector) = (1, 1, 0, 0)
		[NoScaleOffset] _Albedo2("Albedo 2", 2D) = "white" {}
		[NoScaleOffset] [Normal] _Normal2("Normal 2", 2D) = "bump" {}
		[NoScaleOffset] _Roughness2("Roughness 2", 2D) = "gray" {}
		[NoScaleOffset] _Height2("Height 2", 2D) = "gray" {}
		[Space(10)]
		_Height2_Min("Height Min 2", Range(0, 1)) = 0
		_Height2_Max("Height Max 2", Range(0, 1)) = 1
		_Height2_Contrast("Height Contrast 2", Range(0, 4)) = 1
		_BlendDepth2("Blend Depth 2", Range(.001, 1)) = .3

		[Space(40)]

		_Tiling3("Tiling 3", Vector) = (1, 1, 0, 0)
		[NoScaleOffset] _Albedo3("Albedo 3", 2D) = "white" {}
		[NoScaleOffset] [Normal] _Normal3("Normal 3", 2D) = "bump" {}
		[NoScaleOffset] _Roughness3("Roughness 3", 2D) = "gray" {}
		[NoScaleOffset] _Height3("Height 3", 2D) = "gray" {}
		[Space(10)]
		_Height3_Min("Height Min 3", Range(0, 1)) = 0
		_Height3_Max("Height Max 3", Range(0, 1)) = 1
		_Height3_Contrast("Height Contrast 3", Range(0, 4)) = 1
		_BlendDepth3("Blend Depth 3", Range(.001, 1)) = .3

		[Space(40)]

		_SplatMap("Splat Map", 2D) = "white" {}

		_DisplacementIntensity("Displacement Intensity", Range(0, .5)) = .1
		_TesselationMultiplier ("Tesselation Multiplier", Range(1, 64)) = 10
		_TesselationMinDistance("Tesselation Min Distance", Float) = 25
		_TesselationMaxDistance("Tesselation Max Distance", Float) = 100
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        CGPROGRAM

		#pragma surface surf Lambert fullforwardshadows vertex:vert tessellate:tess addshadow

        #pragma target 5.0

		#include "Tessellation.cginc"

		struct appdata
		{
			float4 vertex : POSITION;
			float4 tangent : TANGENT;
			float3 normal : NORMAL;
			float2 texcoord : TEXCOORD0;
			float2 texcoord1 : TEXCOORD1;
			float2 texcoord2 : TEXCOORD2;
		};

		struct Input
		{
			float2 uv_Albedo1;
			float2 uv_Albedo2;
			float2 uv_Albedo3;
			float2 uv_SplatMap;
		};

	#define DECLARE_MATERIAL_VARIABLES(count) \
		sampler2D _Albedo##count##; \
		sampler2D _Normal##count##; \
		sampler2D _Roughness##count##; \
		sampler2D _Height##count##; \
		float _Height##count##_Min; \
		float _Height##count##_Max; \
		float _Height##count##_Contrast; \
		float2 _Tiling##count; \
		float _BlendDepth##count

		DECLARE_MATERIAL_VARIABLES(1);
		DECLARE_MATERIAL_VARIABLES(2);
		DECLARE_MATERIAL_VARIABLES(3);

		sampler2D _SplatMap;

		float _DisplacementIntensity;
		float _TesselationMultiplier;
		float _TesselationMinDistance;
		float _TesselationMaxDistance;

	#define GET_HEIGHT(texcoord, count) saturate( \
													lerp( \
														_Height##count##_Min, \
														_Height##count##_Max, \
														Contrast( \
															tex2Dlod(_Height##count, float4(texcoord, 0, 0)).r, \
															_Height##count##_Contrast) \
													) \
												)

		inline float Contrast(float value, float contrast)
		{
			return (value - .5) * contrast + .5;
		}
		
		inline float4 HeightBlend(float4 texture1, float4 texture2, float4 texture3, 
								  float3 height,
								  float3 factor, 
								  float3 depth)
		{
			float finalDepth = (depth.x * factor.x + depth.y * factor.y + depth.z * factor.z) / 3;

			factor = factor * 2 - 1;

			float ma = max(height.x + factor.x, max(height.y + factor.y, height.z + factor.z)) - finalDepth;

			float b1 = max(height.x + factor.x - ma, 0);
			float b2 = max(height.y + factor.y - ma, 0);
			float b3 = max(height.z + factor.z - ma, 0);
			
			float4 result = (texture1 * b1 + texture2 * b2 + texture3 * b3) / (b1 + b2 + b3);

			result.a = 1;

			return result;
		}

		inline float InverseLerp(float min, float max, float value)
		{
			return saturate((value - min) / (max - min));
		}

		void vert(inout appdata v)
		{
			float3 height = float3(
				GET_HEIGHT(v.texcoord.xy * _Tiling1, 1),
				GET_HEIGHT(v.texcoord.xy * _Tiling2, 2),
				GET_HEIGHT(v.texcoord.xy * _Tiling3, 3));

			float3 depth = float3(_BlendDepth1, _BlendDepth2, _BlendDepth3);

			float3 splat = tex2Dlod(_SplatMap, float4(v.texcoord.xy, 0, 0)).rgb;

			float distanceFromCamera = distance(mul(unity_ObjectToWorld, v.vertex), _WorldSpaceCameraPos);
			float result = HeightBlend(height.x, height.y, height.z, height, splat, depth) * 
						   (1 - InverseLerp(_TesselationMinDistance, _TesselationMaxDistance, distanceFromCamera));

			float d = (result * 2 - 1) * _DisplacementIntensity;
			v.vertex.xyz += v.normal * d;
		}

		float4 tess(appdata v0, appdata v1, appdata v2)
		{
			return UnityDistanceBasedTess(v0.vertex, v1.vertex, v2.vertex, _TesselationMinDistance, _TesselationMaxDistance, _TesselationMultiplier);
		}

		void surf(Input input, inout SurfaceOutput o)
		{
			float2 uv1 = input.uv_Albedo1 * _Tiling1;
			float2 uv2 = input.uv_Albedo2 * _Tiling2;
			float2 uv3 = input.uv_Albedo3 * _Tiling3;

			float3 height = float3( GET_HEIGHT(uv1, 1), GET_HEIGHT(uv2, 2), GET_HEIGHT(uv3, 3));
			float3 depth = float3(_BlendDepth1, _BlendDepth2, _BlendDepth3);
			float3 splat = tex2D(_SplatMap, input.uv_SplatMap).rgb;

			float4 albedo1 = tex2D(_Albedo1, uv1);
			float4 albedo2 = tex2D(_Albedo2, uv2);
			float4 albedo3 = tex2D(_Albedo3, uv3);

			float4 roughness1 = tex2D(_Roughness1, uv1);
			float4 roughness2 = tex2D(_Roughness2, uv2);
			float4 roughness3 = tex2D(_Roughness3, uv3);

			float4 normal1 = float4(UnpackNormal(tex2D(_Normal1, uv1)), 1);
			float4 normal2 = float4(UnpackNormal(tex2D(_Normal2, uv2)), 1);
			float4 normal3 = float4(UnpackNormal(tex2D(_Normal3, uv3)), 1);

			o.Albedo = HeightBlend(albedo1, albedo2, albedo3, height, splat, depth);
			o.Gloss = 1 - HeightBlend(roughness1, roughness2, roughness3, height, splat, depth);
			o.Normal = HeightBlend(normal1, normal2, normal3, height, splat, depth);

			o.Specular = float4(0, 0, 0, 0);
		}
		ENDCG
    }
}
