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
        _ThinfilmMax("Thinfilm Max(nm) ", Range(0,400))=0
        _ThinfilmMin("Thinfilm Min(nm) ", Range(0,400))=0
        _STalpha("Structual Color  Alpha", Range(0.0, 100.0)) = 1.0
        _ThinfilmTex ("Thinfilm Texture", 2D) = "white" {}
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
                float2 uv:TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;//頂点のクリップ座標
                float3 normal:TEXCOORD5;//法線のワールド座標
                float4 vpos:TEXCOORD1;//頂点のワールド座標
                float vdotn:TEXCOORD3;//視点ベクトルと法線ベクトルの内積(オブジェクト座標)
                float2 uv:TEXCOORD0;

                half3 reflDir : TEXCOORD2;
                float ldotn:TEXCOORD4;
                half3 viewDir:TEXCOORD6;

            };

            UNITY_DECLARE_TEXCUBE(_CubeMap);
            half3 _Color;
            
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);//頂点のクリップ座標
                o.vpos=mul(unity_ObjectToWorld,v.vertex);//頂点のワールド座標
                o.normal=UnityObjectToWorldNormal(v.normal);//法線のワールド座標


                half3 obj_viewDir = normalize(ObjSpaceViewDir(v.vertex));
                o.viewDir=UnityWorldSpaceViewDir(o.vpos);//引数は頂点のオブジェクト座標ではなく, ワールド座標を入れる

                o.reflDir = mul(unity_ObjectToWorld, reflect(-obj_viewDir, v.normal.xyz));
                
                return o;
            }
            half _ThinfilmMax;
            half _ThinfilmMin;
            sampler2D _ThinfilmTex;
            half _STalpha;
            half _Inc;//増加率
            
            fixed4 frag (v2f i) : SV_Target
            {
                

                float3 lightDir=normalize(_WorldSpaceLightPos0.xyz);//ワールド座標系の光源ベクトル
                float3 viewDir=normalize( i.viewDir);//ワールド座標系の視点ベクトル
 


                float ldotn=max(0,dot(lightDir,i.normal));//光源ベクトルと法線の内積
                float vdotn=max(0,dot(viewDir,i.normal));//視点ベクトルと法線の内積


                fixed4 Cube=UNITY_SAMPLE_TEXCUBE(_CubeMap, i.reflDir);
                half4 alpha=half4(1,1,1,1-vdotn);
                //
                half4 c=half4(0,0,0,0);
                ldotn=pow(ldotn*0.5+0.5,2);//ハーフランバート


                half thin_norm = tex2D(_ThinfilmTex, i.uv).r;
                half d=_ThinfilmMin+thin_norm*(_ThinfilmMax-_ThinfilmMin);
                c+=calc_struc(ldotn,vdotn,d)*_STalpha;
                c+=Cube*alpha;//キューブマップと透明度を追加
                
                return c;
            }
            ENDCG
        }
    }
}