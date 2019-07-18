#define PI 3.14159265359

float pow5(float v)
{
    return pow(1 - v, 5);
}

// Diffuse distribution functions

float3 lambertDiffuse(float3 albedo)
{
    return albedo / PI;
}

// Fresnel functions

float3 fresnel(float3 F0, float NdotV)
{
    return F0 + (1 - F0) * pow5(NdotV);
}

float3 fresnel(float3 F0, float NdotV, float roughness)
{
    return F0 + (max(1.0 - roughness, F0) - F0) * pow5(NdotV);
}

float3 F0(float ior)
{
    return pow((1.0 - ior) / (1.0 + ior), 2);
}

// Normal distribution functions

float trowbridgeReitzNDF(float NdotH, float roughness)
{
    float alpha = roughness * roughness;
    float alpha2 = alpha * alpha;
    float NdotH2 = NdotH * NdotH;
    float denominator = PI * pow((alpha2 - 1) * NdotH2 + 1, 2);
    return alpha2 / denominator;
}

// Geometric attenuation functions

float cookTorranceGAF(float NdotH, float NdotV, float HdotV, float NdotL)
{
    float firstTerm = 2 * NdotH * NdotV / HdotV;
    float secondTerm = 2 * NdotH * NdotL / HdotV;
    return min(1, min(firstTerm, secondTerm));
}

float schlickBeckmannGAF(float dotProduct, float roughness)
{
    float alpha = roughness * roughness;
    float k = alpha * 0.79788456080286536;  // sqrt(2 / PI)
    return dotProduct / (dotProduct * (1 - k) + k + 0.0001);
}

// Helpers
float3 gammaCorrection(float3 v)
{
    return pow(v, 1.0 / 2.2);
}

float3 sRGB2Lin(float3 col)
{
    return pow(col, 2.2);
}