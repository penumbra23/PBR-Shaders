#define PI 3.14159265359
#define EPS 0.00001

float fPow5(float v)
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
    return F0 + (1 - F0) * fPow5(NdotV);
}

float3 fresnel(float3 F0, float NdotV, float roughness)
{
    return F0 + (max(1.0 - roughness, F0) - F0) * fPow5(NdotV);
}

float3 fresnelDisney(float HdotL, float NdotL, float NdotV, float roughness)
{
    float k = 0.5 + 2 * roughness * sqrt(HdotL);
    float firstTerm = (k - 1) * fPow5(NdotV) + 1;
    float secondTerm = (k - 1) * fPow5(NdotL) + 1;
    return firstTerm * secondTerm;
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

float trowbridgeReitzAnisotropicNDF(float NdotH, float roughness, float anisotropy, float HdotT, float HdotB)
{
    float aspect = sqrt(1.0 - 0.9 * anisotropy);
    float alpha = roughness * roughness;

    float roughT = alpha / aspect;
    float roughB = alpha * aspect;

    float alpha2 = alpha * alpha;
    float NdotH2 = NdotH * NdotH;
    float HdotT2 = HdotT * HdotT;
    float HdotB2 = HdotB * HdotB;

    float denominator = PI * roughT * roughB * pow(HdotT2 / (roughT * roughT) + HdotB2 / (roughB * roughB) + NdotH2, 2);
    return 1 / denominator;
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
    float k = alpha * 0.797884560803;  // sqrt(2 / PI)
    return dotProduct / (dotProduct * (1 - k) + k);
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