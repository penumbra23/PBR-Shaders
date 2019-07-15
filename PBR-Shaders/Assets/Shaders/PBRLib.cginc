float pow5(float v)
{
    return pow(1 - v, 5);
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