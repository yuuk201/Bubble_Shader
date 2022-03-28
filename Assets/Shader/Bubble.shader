Shader "Unlit/Bubble"
{
    Properties
    {
        [PowerSlider(0.1)] _F0("F0", Range(0, 1)) = 0.02
        _RimLightIntensity ("RimLight Intensity", Float) = 1.0
        _Color ("Color", Color) = (1, 1, 1, 1)
        _MainTex ("Texture", 2D) = "white" {}
        _DTex ("D Texture", 2D) = "gray" {}
        _LETex ("LE Texture", 2D) = "gray" {}
        _CubeMap ("Cube Map", Cube) = "white" {}
        _Thinfilm("Thin film",Range(0,400))=0.0
        _Smoothness ("Smoothness", Range(0, 1)) = 1
        _Metallic ("Metallic", Range(0, 1)) = 1
        _StructualTex_D65_Soap_sRGB("Structural Color LT_D65_Air_sRGB",3D)="white" {}
    }

    SubShader
    {
        Tags
        {
            "Queue"="Transparent"
            "RenderType"="Transparent"     
        }
        

        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            //Blend DstColor Zero

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            //#include "./PerlinNoise.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float3 tangent : TANGENT;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 normal : TEXCOORD1;
                float3 tangent : TEXCOORD2;
                float3 viewDir : TEXCOORD3;
                float3 lightDir : TEXCOORD4;
                half fresnel : TEXCOORD5;
                half3 reflDir : TEXCOORD6;
                float4 vpos: TEXCOORD9;
            };

            sampler2D _MainTex;
            sampler2D _DTex;
            sampler2D _LETex;
            Texture3D _StructualTex_D65_Soap_sRGB;
            SamplerState my_point_clamp_sampler;

            UNITY_DECLARE_TEXCUBE(_CubeMap);

            float _F0;
            float _RimLightIntensity;
            float4 _MainTex_ST;
            fixed4 _Color;
            float _Thinfilm;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.vpos=mul(unity_ObjectToWorld, v.vertex);
                o.tangent = v.tangent;
                o.viewDir  = normalize(ObjSpaceViewDir(v.vertex));
                o.lightDir = normalize(ObjSpaceLightDir(v.vertex));
                o.fresnel = _F0 + (1.0h - _F0) * pow(1.0h - dot(o.viewDir, v.normal.xyz), 5.0);
                o.reflDir = mul(unity_ObjectToWorld, reflect(-o.viewDir, v.normal.xyz));
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                i.uv = pow((i.uv * 2.0) - 1.0, 2.0);
                //float d = tex2D(_DTex, i.uv + _Time.xy * 0.1);
                //float d = perlinNoise((i.uv + _Time.xy * 0.1) * 3.0);//膜厚をパーリンノイズを用いている
                float d = _Thinfilm;

                float u, v;

                // Calculate U.
                {
                    float ln = dot(i.lightDir, i.normal);
                    ln = (ln * 0.5) * d;

                    float lt = dot(i.lightDir, i.tangent);
                    lt = ((lt + 1.0) * 0.5) * d;

                    u = tex2D(_LETex, float2(ln, lt)).x;
                }

                // Calculate V.
                {
                    float en = dot(i.viewDir, i.normal);
                    en = ((1.0 - en) * 0.5 + 0.5) * d;

                    float et = dot(i.viewDir, i.tangent);
                    et = ((et + 1.0) * 0.5) * d;

                    v = tex2D(_LETex, float2(en, et)).x;
                }

                float2 uv = float2(u, v);
                float3 normal = i.normal;//追加
 	            float3 lightDirectionNormal = normalize((_WorldSpaceLightPos0-i.vpos).xyz);

	            float ndotl = max(0,dot(normal, lightDirectionNormal));//追加
                //float ndotl=max(0, dot(normal, _WorldSpaceLightPos0.xyz));
                float3 viewDirectionNormal = normalize((float4(_WorldSpaceCameraPos, 1.0) - i.vpos).xyz);
                float ndotv=max(0, dot(normal, viewDirectionNormal));
                float dmin=0;
                float dmax=400;
                //float4 col = tex2D(_MainTex, uv);//従来手法での構造色
                float4 col = _StructualTex_D65_Soap_sRGB.Sample(my_point_clamp_sampler, float3((_Thinfilm-dmin)/(dmax-dmin),1.0-ndotl,1.0-ndotv));//3DTexを使った構造色取得

                float NdotL = dot(i.normal, i.lightDir);
                float3 localRefDir = -i.lightDir + (2.0 * i.normal * NdotL);
                float spec = pow(max(0, dot(i.viewDir, localRefDir)), 10.0);//簡単なPhongモデル

                float rimlight = 1.0 - dot(i.normal, i.viewDir);

                fixed4 cubemap = UNITY_SAMPLE_TEXCUBE(_CubeMap, i.reflDir);
                col.a = i.fresnel;

                //col *= cubemap;
                //col += rimlight * _RimLightIntensity;
                //col += spec;

                return col;
            }
            ENDCG
        }

        CGPROGRAM
			#pragma target 3.0
			#pragma surface surf Standard alpha

			half _Smoothness;
            half _Metallic;
            float _RimLightIntensity;
			
			struct Input {
				//float3 viewDir;
                fixed null;
			};

			void surf (Input IN, inout SurfaceOutputStandard o) {
				o.Smoothness = _Smoothness;
                o.Metallic=_Metallic;
                //half rim = 1.0 - saturate(dot(normalize(IN.viewDir), o.Normal));
                //o.Emission = rim*_RimLightIntensity;
			}
		ENDCG
    }
}
