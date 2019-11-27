Shader "Unlit/Work11"
{
    Properties
    {
		_AlbedoTex("AlbedoTex", 2D)="white"{}
		_HeightTex("HeightTex",2D) = "white"{}
		_TessFactor("Tess Factor",float) = 0.1
		_HeightScale("HeightScale",float) = 0.5
		_AmbientRate("Ambient Rate",Range(0,1)) = 0.2
		_SpecularColor("Specular Color", Color) = (0.5, 0.5, 0.5, 1.0)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
			#pragma vertex vert
			#pragma hull hull
			#pragma domain dom
			#pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
			 #include "Lighting.cginc"

			 uniform float _TessFactor;

            struct appdata
            {
                float4 pos : POSITION;
				float2 uv:TEXCOORD0;
				float3 normal:NORMAL;
                
            };

            struct v2h
            {
				float4 pos:POS;
                float2 uv : TEXCOORD0;
				float3 normal:NORMAL;

				float3 viewDir:TEXCOORD2;
            };
			struct h2d_main {
				float3 pos:POS;
				float2 uv:TEXCOORD0;
				float3 normal:NORMAL;
			};
			struct h2d_const {
				float tess_factor[3]:SV_TessFactor;
				float InsideTessFactor : SV_InsideTessFactor;
			};
			struct d2f {
				float4 pos:SV_Position;
				float2 uv:TEXCOORD0;
			};
			struct f_input {
				float4 vertex:SV_Position;
				float3 normal:TEXCOORD1;
				float3 viewDir:TEXCOORD2;
				float2 uv:TEXCOORD0;
				float4 color:COLOR0;
			};

            sampler2D _AlbedoTex;
			sampler2D _HeightTex;
			float4 _AlbedoTex_ST;
			float _HeightScale;
			//float _TessFactor;
			uniform float _AmbientRate;
			uniform float4 _SpecularColor;

            v2h vert (appdata v)
            {
                v2h o;
				o.pos = v.pos;
				o.uv = TRANSFORM_TEX(v.uv, _AlbedoTex);
				o.normal = v.normal;
				o.viewDir = WorldSpaceViewDir(v.pos);
                return o;
            }

			h2d_const HSConst(InputPatch<v2h, 3>i) {
				h2d_const o = (h2d_const)0;
				o.tess_factor[0] = _TessFactor;
				o.tess_factor[1] = _TessFactor;
				o.tess_factor[2] = _TessFactor;
				o.InsideTessFactor = _TessFactor;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[outputcontrolpoints(3)]
			[patchconstantfunc("HSConst")]
			h2d_main hull(InputPatch<v2h, 3>i, uint id:SV_OutputControlPointID) {
				h2d_main o = (h2d_main)0;
				o.pos = i[id].pos;
				o.uv = i[id].uv;
				o.normal = i[id].normal;
				return o;
			}

			[domain("tri")]
			d2f dom(h2d_const hs_count_data,
				const OutputPatch<h2d_main, 3>i, float3 bary:SV_DomainLocation) {
				d2f o = (d2f)0;
				o.uv = i[0].uv*bary.x + i[1].uv*bary.y + i[2].uv*bary.z;
				float3 nrm = i[0].normal*bary.x + i[1].normal*bary.y + i[2].normal*bary.z;
				float3 pos = i[0].pos*bary.x + i[1].pos*bary.y + i[2].pos*bary.z;

				fixed height = tex2Dlod(_HeightTex, float4(o.uv, 0, 0)).x;
				pos += nrm * height*_HeightScale*sin(-_Time);

				o.pos = UnityObjectToClipPos(float4(pos, 1));
				return o;
			}

            fixed4 frag (f_input  i) : SV_Target
            {
                // sample the texture
                //fixed4 col = tex2D(_AlbedoTex, i.uv);
                // apply fog
                //UNITY_APPLY_FOG(i.fogCoord, col);
				float power = Luminance(_WorldSpaceLightPos0.xyz);	//環境光取得

				float3 N = normalize(i.normal);
				float3 L = normalize(_WorldSpaceLightPos0.xyz);
				float3 V = normalize(i.viewDir);


				float4 albedo = tex2D(_AlbedoTex, i.uv);
				float3 ambient = _LightColor0.xyz * albedo.xyz;
				float3 NL = dot(N, L);
				float3 diffuse = _LightColor0.xyz*albedo.xyz*max(0.0, NL);
				float3 lambert = _AmbientRate * ambient + (1.0 - _AmbientRate)*diffuse;


				float3 H = normalize(V + L);
				float3 specular = _LightColor0.xyz * _SpecularColor * pow(max(0.0, dot(H, N)), power);


				float4 col = float4(lambert + specular, 1.0);
				UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
            }
            ENDCG
        }
    }
}
