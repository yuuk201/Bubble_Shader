Shader "Unlit/bubbleProc_shader"
{
    Properties
    {
        [PowerSlider(0.1)] _F0 ("F0", Range(0.0, 1.0)) = 0.02
        _CubeMap ("Cube Map", Cube) = "white" {}

        _Color      ("Color"     , Color      ) = (1, 1, 1, 1)
		_Smoothness ("Smoothness", Range(0, 1)) = 1
        _Metallic ("Metallic", Range(0, 1)) = 1
        [Enum(sRGB,1,Wide Gammut,2)]_Colorspace ("Color Space", int) = 1
        [Enum(D55,1,D65,2,D93,3)]_Colortemperature ("Color Temperature", int) = 1
        [Enum(Soap,1)]_Refractiveindex ("Thinfilm Material", int) = 1
        [Header(Thin fllm interference)]
        _ThinfilmMax("Thinfilm(nm) ", Range(0,400))=0
        _STalpha("Structual Color  Alpha", Range(0.0, 100.0)) = 1.0
        [NoScaleOffset] _StructualTex_D55_Soap_sRGB("Structural Color LT_D55_Air_sRGB",3D)="white" {}
        [NoScaleOffset] _StructualTex_D55_Soap_wide("Structural Color LT_D55_Air_wide",3D)="white" {}
        [NoScaleOffset] _StructualTex_D65_Soap_sRGB("Structural Color LT_D65_Air_sRGB",3D)="white" {}
        [NoScaleOffset] _StructualTex_D65_Soap_wide("Structural Color LT_D65_Air_wide",3D)="white" {}
        [NoScaleOffset] _StructualTex_D93_Soap_sRGB("Structural Color LT_D93_Air_sRGB",3D)="white" {}
        [NoScaleOffset] _StructualTex_D93_Soap_wide("Structural Color LT_D93_Air_wide",3D)="white" {}

    }
    SubShader
    {
        Tags { "Queue"      = "Transparent"
			"RenderType" = "Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            CGPROGRAM
           #pragma vertex vert
           #pragma fragment frag
            
           #include "UnityCG.cginc"
           #include "struc_func.cginc"

            struct appdata
            {
                float4 vertex : POSITION;//頂点のオブジェクト座標
                float3 normal : NORMAL;//法線のオブジェクト座標
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;//頂点のクリップ座標
                float3 normal:TEXCOORD5;//法線のワールド座標
                float4 vpos:TEXCOORD1;//頂点のワールド座標
                float vdotn:TEXCOORD3;//視点ベクトルと法線ベクトルの内積(オブジェクト座標)

                half3 reflDir : TEXCOORD2;
                float ldotn:TEXCOORD4;

            };

            UNITY_DECLARE_TEXCUBE(_CubeMap);
            float _F0;
            half3 _Color;
            
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);//頂点のクリップ座標
                o.vpos=mul(unity_ObjectToWorld,v.vertex);//頂点のワールド座標
                o.normal=UnityObjectToWorldNormal(v.normal);//法線のワールド座標


                half3 viewDir = normalize(ObjSpaceViewDir(v.vertex));
                o.vdotn=dot(viewDir, v.normal);
                //half3 lightDir=normalize(ObjSpaceLightDir(v.vertex));
                
                //o.vdotn = dot(viewDir, v.normal.xyz);
                //o.ldotn=dot(lightDir, v.normal.xyz);
                

                o.reflDir = mul(unity_ObjectToWorld, reflect(-viewDir, v.normal.xyz));
                
                return o;
            }
            half _ThinfilmMax;
            half _STalpha;
            half _Inc;//増加率
            
            fixed4 frag (v2f i) : SV_Target
            {
                //half fresnel = _F0 + (1.0h - _F0) * pow(1.0h - i.vdotn, 5);
                

                float3 lightDir=normalize(_WorldSpaceLightPos0.xyz-i.vpos.xyz);//ワールド座標系の光源ベクトル
                float3 viewDir=normalize((float4(_WorldSpaceCameraPos,1.0)-i.vpos).xyz);//ワールド座標系の視点ベクトル
                
                float ldotn=max(0,dot(lightDir,i.normal));//光源ベクトルと法線の内積
                float vdotn=max(0,dot(viewDir,i.normal));//視点ベクトルと法線の内積
                
                
                //fixed4 alpha=half4(1,1,1,1-vdotn);


                fixed4 Cube=UNITY_SAMPLE_TEXCUBE(_CubeMap, i.reflDir);
                half4 alpha=half4(1,1,1,1-vdotn);
                //
                half4 c=half4(0,0,0,0);
                ldotn=((ldotn+1)/2);
                c+=calc_struc(ldotn,vdotn,_ThinfilmMax)*_STalpha;//
                //c+=half4(1,0,0,0);
                c+=Cube*alpha;//キューブマップと透明度を追加
                //c=half4(1-vdotn,1-vdotn,1-vdotn,1.0);

                
                
                //c+=half4(1,0,0,1.0);
                //c.a=1.0;
                //c=calc_struc(i.ldotn,i.vdotn,_ThinfilmMax);
                //c=half4(1.0,0,0,1.0);
                //c=half4(_ThinfilmMax/400,_ThinfilmMax/400,_ThinfilmMax/400,1);
                //c=half4(vdotn,vdotn,vdotn,1.0);
                //c=half4(1,1,1,1-i.vdotn);
                
                return c;
            }
            ENDCG
        }
    }
}