

#ifndef STRUC_COL_INCLUDED
#define STRUC_COL_INCLUDED

#include "UnityCG.cginc"
#include "Lighting.cginc"

SamplerState my_point_clamp_sampler;


Texture3D _StructualTex_D55_Soap_sRGB;
Texture3D _StructualTex_D55_Soap_wide;
Texture3D _StructualTex_D65_Soap_sRGB;
Texture3D _StructualTex_D65_Soap_wide;
Texture3D _StructualTex_D93_Soap_sRGB;
Texture3D _StructualTex_D93_Soap_wide;
int _Colorspace;//1:srgb,2:wide
int _Colortemperature;//1:d55,2:d65,3:d93
int _Refractiveindex;//1:air, 2:fe203,3:fe3o4

float4 calc_struc(half NdotL,half NdotV,half Thinfilm){//膜厚と入射角と出社角
    float4 stcol;
    float dmin=0;
    float dmax=400;
    float size=dmax-dmin;
    if(_Colorspace==1){
        if(_Colortemperature==1){
            stcol=_StructualTex_D55_Soap_sRGB.Sample(my_point_clamp_sampler, float3((Thinfilm-dmin)/(dmax-dmin),1.0-NdotL,1.0-NdotV));
           
        }else if(_Colortemperature==2){
            stcol=_StructualTex_D65_Soap_sRGB.Sample(my_point_clamp_sampler, float3((Thinfilm-dmin)/(dmax-dmin),1.0-NdotL,1.0-NdotV));
        }else{
            stcol=_StructualTex_D93_Soap_sRGB.Sample(my_point_clamp_sampler, float3((Thinfilm-dmin)/(dmax-dmin),1.0-NdotL,1.0-NdotV));
        }
    }else{
        if(_Colortemperature==1){
            stcol=_StructualTex_D55_Soap_wide.Sample(my_point_clamp_sampler, float3((Thinfilm-dmin)/(dmax-dmin),1.0-NdotL,1.0-NdotV));
        }else if(_Colortemperature==2){
            stcol=_StructualTex_D65_Soap_wide.Sample(my_point_clamp_sampler, float3((Thinfilm-dmin)/(dmax-dmin),1.0-NdotL,1.0-NdotV));
        }else{
            stcol=_StructualTex_D93_Soap_wide.Sample(my_point_clamp_sampler, float3((Thinfilm-dmin)/(dmax-dmin),1.0-NdotL,1.0-NdotV));
        }
    }
    return float4(stcol.rgb * _LightColor0.xyz*NdotL,1);
    //return float4(1,0,0,1);
}
float4 calc_struc_AL(half NdotL,half NdotV,half Thinfilm,half AmbientLight){//膜厚と入射角と出社角
    float4 stcol;
    NdotL=NdotL+AmbientLight;
    float dmin=0;
    float dmax=400;
    float size=dmax-dmin;
    if(_Colorspace==1){
        if(_Colortemperature==1){
            stcol=_StructualTex_D55_Soap_sRGB.Sample(my_point_clamp_sampler, float3((Thinfilm-dmin)/(dmax-dmin),1.0-NdotL,1.0-NdotV));
           
        }else if(_Colortemperature==2){
            stcol=_StructualTex_D65_Soap_sRGB.Sample(my_point_clamp_sampler, float3((Thinfilm-dmin)/(dmax-dmin),1.0-NdotL,1.0-NdotV));
        }else{
            stcol=_StructualTex_D93_Soap_sRGB.Sample(my_point_clamp_sampler, float3((Thinfilm-dmin)/(dmax-dmin),1.0-NdotL,1.0-NdotV));
        }
    }else{
        if(_Colortemperature==1){
            stcol=_StructualTex_D55_Soap_wide.Sample(my_point_clamp_sampler, float3((Thinfilm-dmin)/(dmax-dmin),1.0-NdotL,1.0-NdotV));
        }else if(_Colortemperature==2){
            stcol=_StructualTex_D65_Soap_wide.Sample(my_point_clamp_sampler, float3((Thinfilm-dmin)/(dmax-dmin),1.0-NdotL,1.0-NdotV));
        }else{
            stcol=_StructualTex_D93_Soap_wide.Sample(my_point_clamp_sampler, float3((Thinfilm-dmin)/(dmax-dmin),1.0-NdotL,1.0-NdotV));
        }
    }
    return float4(stcol.rgb * _LightColor0.xyz*NdotL,1);
    //return float4(1,0,0,1);
}
#endif
 