Shader "PBR/PBRShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            // For directional light
            Tags { "LightMode"="ForwardBase" }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            #pragma target 3.0

            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "Lighting.cginc"

            struct v_in {
                float4 position : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v_out {
                float4 position : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : TEXCOORD3;
                float3 worldPos : TEXCOORD4;
            };

            sampler2D _MainTex;

            v_out vert (v_in v) {
                v_out o;           
                o.uv = v.uv;
                o.normal = normalize(UnityObjectToWorldNormal(v.normal));
                o.position = UnityObjectToClipPos(v.position);
                o.worldPos = mul(unity_ObjectToWorld, v.position);
                return o;
            }

            float4 frag (v_out i) : SV_Target
            {
                if (_WorldSpaceLightPos0.w == 1){
                    return float4(0.0, 0.0, 0.0, 0.0);
                }

                // Assuming this pass goes only for directional lights
                float3 lightVec =  normalize(_WorldSpaceLightPos0.xyz);

                float3 viewVec = normalize(_WorldSpaceCameraPos.xyz - i.worldPos);
                float3 halfVec = normalize(lightVec + viewVec);

                float NdotL = max(dot(i.normal, lightVec), 0.0);
                float HdotN = max(dot(i.normal, halfVec), 0.0);

                float3 albedo = tex2D(_MainTex, i.uv);

                // Diffuse part
                float3 diffuseColor = albedo * NdotL * _LightColor0.rgb;

                // Specular part
                float specularAttenuation = 16.0;
                float3 specularColor = pow(HdotN, specularAttenuation) * _LightColor0.rgb;

                return float4(diffuseColor + specularColor, 1.0);
            }
            ENDCG
        }
    }
    FallBack "Standard"
}
