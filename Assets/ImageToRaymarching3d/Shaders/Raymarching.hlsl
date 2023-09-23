float distance(float3 ray, UnityTexture2D tex)
{
    float height = tex2Dlod(tex, float4(saturate(ray.xy + .5), 0, 0)).a;
    height = lerp(-0.5, 1.0, height);
    return abs(ray.z) - height * .5;
}
 
float3 calcNormal(float3 pos, UnityTexture2D tex)
{
    float2 ep = float2(0.001, 0.0);
    float d = distance(pos, tex);
    const float ray = pos + ep.xyy;
    return normalize(
        float3(
            distance(ray, tex) - d,
            distance(ray, tex) - d,
            ep.y * sign(pos.z)
        )
    );
}

float2 intersectCube(float3 r0, float3 rd, float3 c, float3 s)
{
    float3 v = c - r0;
    float3 t1 = v / rd - s / abs(rd);
    float3 t2 = v / rd + s / abs(rd);
    float tN = max(t1.x, max(t1.y, t1.z));
    float tF = min(t2.x, min(t2.y, t2.z));
    return float2(tN, tF);
}
 
void RayMarching_float(
    float3 RayPosition,
    float3 RayDirection,
    UnityTexture2D Tex,
    float4 ColorCollection,
    out bool Hit,
    out float3 HitPosition,
    out float4 HitColor,
    out float3 HitNormal)
{
    float3 pos = RayPosition;

    float2 ic = intersectCube(pos, RayDirection, 0, 0.5);
    ic.x = max(ic.x, 0);
    float3 ray = pos + RayDirection * ic.x;
    float d = 0;
    float dt = (ic.y - ic.x) / 60.0;
    bool isInside = false;

    [unroll]
    for (int i = 0; i < 64; ++i)
    {
        ray += RayDirection * dt;
        d = distance(ray, Tex);
        
        if (d < 0.001)
        {
            Hit = true;
            HitPosition = pos;
            // Note: 補間部分の補正
            if (i > 1)
            {
                HitColor = tex2D(Tex, saturate(ray.xy + .5)) * ColorCollection;
            } else
            {
                HitColor = tex2D(Tex, saturate(ray.xy + .5));
            }
            HitNormal = calcNormal(pos, Tex);
            break;
        }

        if (d < 0) isInside = true;
        dt = isInside ? sign(d) * abs(dt * 0.5) : dt;
    }
    clip((d < .001 || isInside) - 1);
}
