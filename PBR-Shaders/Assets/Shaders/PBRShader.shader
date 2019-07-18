Shader "PBR/PBRShader"
{
    Properties
    {
        _MainTex ("Albedo Map", 2D) = "white" {}
        _NormalMap ("Normal Map", 2D) = "bump" {}
        _MetalnessMap ("Metalness Map", 2D) = "black" {}
        _RoughnessMap ("Roughness Map", 2D) = "black" {}

        _AlbedoColor ("Albedo Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _FresnelColor ("Fresnel Color (F0)", Color) = (1.0, 1.0, 1.0, 1.0)

        _Roughness ("Roughness", Range(0,1)) = 0
        _Metalness ("Metalness", Range(0,1)) = 0

        _EnvMap ("Environment Map", Cube) = "" {}
        _IrradianceMap ("Irradiance Map", Cube) = "" {}
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
            #include "PBRLib.cginc"

            struct v_in 
            {
                float4 position : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
                float4 tangent: TANGENT;
            };

            struct v_out 
            {
                float4 position : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : TEXCOORD1;
                float3 tangent: TEXCOORD2;
                float3 bitangent: TEXCOORD3;
                float3 worldPos : TEXCOORD4;
            };

            sampler2D _MainTex;
            sampler2D _NormalMap;
            sampler2D _MetalnessMap;
            sampler2D _RoughnessMap;

            float3 _AlbedoColor;
            float3 _FresnelColor;

            float _Roughness;
            float _Metalness;

            samplerCUBE _EnvMap;
            samplerCUBE _IrradianceMap;

            // Outputs the spherical sampling coordinates from the normal
            float2 toRadialCoords(float3 normal)
            {
                float3 normalized = normalize(normal);
                float x = atan2(normalized.z, normalized.x);
                float y = acos(normalized.y);
                float2 coords = float2(x, y) / PI;
                return float2(coords.x * 0.5 + 0.5, 1.0 - coords.y);
            }

            v_out vert (v_in v) 
            {
                v_out o;           
                o.uv = float2(2.0 * PI * v.uv.x, PI * v.uv.y);
                o.position = UnityObjectToClipPos(v.position);
                o.worldPos = mul(unity_ObjectToWorld, v.position);

                // Normal mapping parameters
                o.tangent = normalize(mul(unity_ObjectToWorld, v.tangent).xyz);
                o.normal = normalize(UnityObjectToWorldNormal(v.normal));
                o.bitangent = normalize(cross(o.normal, o.tangent.xyz));
                return o;
            }

            float4 frag (v_out i) : SV_Target
            {
                if (_WorldSpaceLightPos0.w == 1)
                    return float4(0.0, 0.0, 0.0, 0.0);

                // Just for mapping the 2d texture onto a sphere
                float2 uv = toRadialCoords(i.normal);
                
                // VECTORS
                // Assuming this pass goes only for directional lights
                float3 lightVec =  normalize(_WorldSpaceLightPos0.xyz);

                float3 viewVec = normalize(_WorldSpaceCameraPos.xyz - i.worldPos);
                float3 halfVec = normalize(lightVec + viewVec);

                // Calculate the tangent matrix if normal mapping is applied
                float3x3 tangentMatrix = transpose(float3x3(i.tangent, i.bitangent, i.normal));
                float3 normal = mul(tangentMatrix, tex2D(_NormalMap, uv).xyz * 2 - 1);

                // DOT PRODUCTS
                float NdotL = max(dot(i.normal, lightVec), 0.0);
                float NdotH = max(dot(i.normal, halfVec), 0.0);
                float HdotV = max(dot(halfVec, viewVec), 0.0);
                float NdotV = max(dot(i.normal, viewVec), 0.0);

                // TEXTURE SAMPLES
                float3 albedo = sRGB2Lin(tex2D(_MainTex, uv));

                // PBR PARAMETERS
                
                // This assumes that the maximum param is right if both are supplied (range and map)
                float roughness = saturate(max(_Roughness, tex2D(_RoughnessMap, uv)).r);
                float metalness = saturate(max(_Metalness, tex2D(_MetalnessMap, uv)).r);

                float3 F0 = lerp(float3(0.04, 0.04, 0.04), _FresnelColor, metalness);

                float D = trowbridgeReitzNDF(NdotH, roughness);
                float3 F = fresnel(F0, NdotV, roughness);
                float G = schlickBeckmannGAF(NdotV, roughness) * schlickBeckmannGAF(NdotL, roughness);

                // DIRECT LIGHTING

                // Normals from normal map
                float lambertDirect = max(dot(normal, lightVec), 0.0);

                float3 radiance = _LightColor0.rgb;

                // INDIRECT LIGHTING

                float3 diffuseIrradiance = sRGB2Lin(texCUBE(_IrradianceMap, i.normal));
                float3 specularIrradiance = sRGB2Lin(texCUBE(_EnvMap, -reflect(viewVec, i.normal)));

                // DIFFUSE COMPONENT
                float3 diffuseTerm = lambertDiffuse(albedo) * (1 - F) * (1 - metalness) * _AlbedoColor;
                
                // SPECULAR COMPONENT
                float3 specularTerm = G * D * F / (4 * NdotV * NdotL + 0.00001);

                // BRDF OUTPUT
                float3 brdfOutput = (diffuseTerm + specularTerm) * lambertDirect * (radiance);

                // Add constant ambient (to boost the lighting, only temporary)
                float3 ambient = diffuseIrradiance * albedo * (1 - F) * (1 - metalness);
                
                //return float4(F, 1.0);
                return float4(gammaCorrection(brdfOutput + ambient), 1.0);
            }
            ENDCG
        }
    }
    FallBack "Standard"
}
