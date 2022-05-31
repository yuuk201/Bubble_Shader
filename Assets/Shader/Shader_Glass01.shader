

Shader "Custom/Shader_Glass01" {
	Properties {
		_Color      ("Color"     , Color      ) = (1, 1, 1, 1)
		_Smoothness ("Smoothness", Range(0, 1)) = 1
        _Metallic ("Metallic", Range(0, 1)) = 1
		//_Alpha      ("Alpha"     , Range(0, 1)) = 0
        //_F0("F0", Float) = 0.02
        //_RimLightIntensity ("RimLight Intensity", Float) = 1.0

        //_BumpScale("Scale", Float) = 1.0
        //[Normal] _BumpMap("Normal Map", 2D) = "bump" {}
        [Enum(sRGB,1,Wide Gammut,2)]_Colorspace ("Color Space", int) = 1
        [Enum(D55,1,D65,2,D93,3)]_Colortemperature ("Color Temperature", int) = 1
        [Enum(Soap,1)]_Refractiveindex ("Thinfilm Material", int) = 1
        //[Enum(add,1,mult,2)]_Addormult ("Add or Mult", int) = 1
        [Header(Thin fllm interference)]
        //_Thinfilm("Thinfilm",Range(0,320))=0
        _ThinfilmMax("Thinfilm(nm) ", Range(0,400))=0
        _STalpha("Structual Color  Alpha", Range(0.0, 100.0)) = 1.0
        //_AmbientLight("Ambient Light",Range(0,1))=0.0
        //_ThinfilmMin("Thinfilm Thickness 2nd (nm)", Range(0,400))=0
        //[MaterialToggle] _Changefilm ("Use Thickness Map", Float) = 0 
        //_CubeMap ("Cube Map", Cube) = "white" {}

        //_ThinfilmTex("Thickness Map", 2D)="white" {}
        //_ThinfilmTex2("Thickness Map2", 2D)="white" {}
        
        //[HideInInspector] _ThinfilmRate("Thinfilm Rate", Range(0.0,10.0)) = 1.0//膜厚の変化を均等じゃなくするため, 掛ける値
        //_ThinfilmGamma("Thickness Map Gamma", Range(0.1,10.0)) = 1.0//膜厚の変化を線形変換でなく, ガンマ変換とする.　
        
        //_Gausssigma("Sigma of Gauss", Range(0.1,10.0)) = 1.0
        //_Roughness("RoughnessGold", Range(0.0, 1.0)) = 0.5
        //_FresnelReflectance("FresnelReflectance", Range(0.0, 1.0)) = 0.5
        //_GoldColor("GoldColor", Color) = (1,0.84,0,1)
        //_GoldTex("GoldTexture",2D)="white"{}
        //_StrucPos("Structural Color Mask",2D)="white"{}
        [NoScaleOffset] _StructualTex_D55_Soap_sRGB("Structural Color LT_D55_Air_sRGB",3D)="white" {}
        [NoScaleOffset] _StructualTex_D55_Soap_wide("Structural Color LT_D55_Air_wide",3D)="white" {}
        [NoScaleOffset] _StructualTex_D65_Soap_sRGB("Structural Color LT_D65_Air_sRGB",3D)="white" {}
        [NoScaleOffset] _StructualTex_D65_Soap_wide("Structural Color LT_D65_Air_wide",3D)="white" {}
        [NoScaleOffset] _StructualTex_D93_Soap_sRGB("Structural Color LT_D93_Air_sRGB",3D)="white" {}
        [NoScaleOffset] _StructualTex_D93_Soap_wide("Structural Color LT_D93_Air_wide",3D)="white" {}

	}

	SubShader {
		Tags {
			"Queue"      = "Transparent"
			"RenderType" = "Transparent"
		}

		// 背景とのブレンド法を「乗算」に指定
		Blend DstColor Zero
        //Blend SrcAlpha OneMinusSrcAlpha

		Pass {
            Tags{"LightMode"="ForwardBase"}
			CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#include "UnityCG.cginc"
                #include "struc_func.cginc"

				half3 _Color;
				half _Alpha;

				struct appdata {
					float4 vertex : POSITION;
                    half3 normal    : NORMAL;
				};

				struct v2f {
					float4 vertex : SV_POSITION;
                    float4 vpos: TEXCOORD9;//追加。ワールド座標を保持しておく

                    float3 normal:NORMAL;//追加
                    float3 tangent:TANGENT;//追加
                    float4 light : COLOR1;//追加

                    float3 viewDir : TEXCOORD10;//追加
                    float3 lightDir : TEXCOORD11;//追加
                    half fresnel : TEXCOORD12;//追加
                    half3 reflDir:TEXCOORD13;//追加
				};

                half _F0;
				
				v2f vert (appdata v) {
					v2f o;
                    float3 normalWorld = UnityObjectToWorldNormal(v.normal);

                    // added for SC support
                    o.normal=normalWorld;
                    o.vpos=mul(unity_ObjectToWorld, v.vertex);

                    o.viewDir  = normalize(ObjSpaceViewDir(v.vertex));
                    o.lightDir = normalize(ObjSpaceLightDir(v.vertex));
                    o.fresnel = _F0 + (1.0h - _F0) * pow(1.0h - dot(o.viewDir, v.normal.xyz), 5.0);
                    //o.reflDir = mul(unity_ObjectToWorld, reflect(-o.viewDir, v.normal.xyz));

					o.vertex = UnityObjectToClipPos(v.vertex);

					return o;
				}
                half _ThinfilmMax;
                half _ThinfilmMin;
                half _ThinfilmRate;
                float _Changefilm;
                sampler2D _StrucPos;
                sampler2D _ThinfilmTex;
                float _ThinfilmGamma;
                float _Gausssigma;
                int _Addormult; 
                float _STalpha;
                half _AmbientLight;
                sampler2D _ThinfilmTex2;
                UNITY_DECLARE_TEXCUBE(_CubeMap);
				
				fixed4 frag (v2f i) : SV_Target {
                    float3 normal = i.normal;//追加
                    float3 lightDirectionNormal = normalize((_WorldSpaceLightPos0-i.vpos).xyz);
                    float ndotl = max(0,dot(normal, lightDirectionNormal));
                    float3 viewDirectionNormal = normalize((float4(_WorldSpaceCameraPos, 1.0) - i.vpos).xyz);
                    float ndotv=max(0, dot(normal, viewDirectionNormal));
                    half4 c=half4(0,0,0,0);
                    c+=half4(_Color,1);
                    c+=calc_struc(ndotl,ndotv,_ThinfilmMax)*_STalpha;
                    //c+=calc_struc_AL(ndotl,ndotv,_ThinfilmMax,_AmbientLight)*_STalpha;
                    //float rimlight=1.0 - dot(i.normal, i.viewDir);
                    //c.a = i.fresnel;
                    //c+=rimlight*_RimLightIntensity;
					return c;
				}
			ENDCG
		}
        Pass {
            Tags{"LightMode"="ForwardAdd"}
			CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#include "UnityCG.cginc"
                #include "struc_func.cginc"

				half3 _Color;
				half _Alpha;

				struct appdata {
					float4 vertex : POSITION;
                    half3 normal    : NORMAL;
				};

				struct v2f {
					float4 vertex : SV_POSITION;
                    float4 vpos: TEXCOORD9;//追加。ワールド座標を保持しておく

                    float3 normal:NORMAL;//追加
                    float3 tangent:TANGENT;//追加
                    float4 light : COLOR1;//追加

                    float3 viewDir : TEXCOORD10;//追加
                    float3 lightDir : TEXCOORD11;//追加
                    half fresnel : TEXCOORD12;//追加
                    half3 reflDir:TEXCOORD13;//追加
				};

                half _F0;
				
				v2f vert (appdata v) {
					v2f o;
                    float3 normalWorld = UnityObjectToWorldNormal(v.normal);

                    // added for SC support
                    o.normal=normalWorld;
                    o.vpos=mul(unity_ObjectToWorld, v.vertex);

                    o.viewDir  = normalize(ObjSpaceViewDir(v.vertex));
                    o.lightDir = normalize(ObjSpaceLightDir(v.vertex));
                    o.fresnel = _F0 + (1.0h - _F0) * pow(1.0h - dot(o.viewDir, v.normal.xyz), 5.0);
                    //o.reflDir = mul(unity_ObjectToWorld, reflect(-o.viewDir, v.normal.xyz));

					o.vertex = UnityObjectToClipPos(v.vertex);

					return o;
				}
                half _ThinfilmMax;
                half _ThinfilmMin;
                half _ThinfilmRate;
                float _Changefilm;
                sampler2D _StrucPos;
                sampler2D _ThinfilmTex;
                float _ThinfilmGamma;
                float _Gausssigma;
                int _Addormult; 
                float _STalpha;
                sampler2D _ThinfilmTex2;
                half _AmbientLight;
                UNITY_DECLARE_TEXCUBE(_CubeMap);
				
				fixed4 frag (v2f i) : SV_Target {
                    float3 normal = i.normal;//追加
                    float3 lightDirectionNormal = normalize((_WorldSpaceLightPos0-i.vpos).xyz);
                    float ndotl = max(0,dot(normal, lightDirectionNormal));
                    float3 viewDirectionNormal = normalize((float4(_WorldSpaceCameraPos, 1.0) - i.vpos).xyz);
                    float ndotv=max(0, dot(normal, viewDirectionNormal));
                    half4 c=half4(0,0,0,0);
                    c+=half4(_Color,1);
                    c+=calc_struc(ndotl,ndotv,_ThinfilmMax)*_STalpha;
                    //c+=calc_struc_AL(ndotl,ndotv,_ThinfilmMax,_AmbientLight)*_STalpha;
                    //float rimlight=1.0 - dot(i.normal, i.viewDir);
                    //c.a = i.fresnel;
                    //c+=rimlight*_RimLightIntensity;
					return c;
				}
			ENDCG
		}

		// V/FシェーダーはReflection Probeに反応しないので
		// 反射だけを描画するSurface Shaderを追記する
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

	FallBack "Standard"
}