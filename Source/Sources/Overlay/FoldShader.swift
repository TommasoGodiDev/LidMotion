import Foundation

enum FoldShader {
    static let source = #"""
    #include <metal_stdlib>
    using namespace metal;

    struct Uniforms {
        float tilt;         
        float progress;     
        float defocus;      
        uint  style;        
        float blur;         
        float dim;          
        float perspective;  
        float eyeDistance;  
        float aspect;       
        float width;
        float height;
        float velocity;     
        float gloss;        
    };

    struct VOut { float4 position [[position]]; float2 uv; };

    vertex VOut duoVertex(uint id [[vertex_id]], constant Uniforms& u [[buffer(0)]]) {
        const float2 p[4] = { float2(-1.0, 1.0), float2(-1.0, -1.0), float2(1.0, 1.0), float2(1.0, -1.0) };
        float2 pos = p[id];
        VOut o;
        o.position = float4(pos, 0.0, 1.0);
        o.uv = float2((pos.x + 1.0) * 0.5, 1.0 - (pos.y + 1.0) * 0.5);
        return o;
    }

    static float smoother(float x) {
        x = clamp(x, 0.0, 1.0);
        return x * x * x * (x * (x * 6.0 - 15.0) + 10.0);
    }

    static float3 sampleBlurred(texture2d<float> tex, sampler s, float2 uv, float sigmaUV) {
        float3 sharp = tex.sample(s, uv, level(0.0)).rgb;
        float sigma = sigmaUV * float(tex.get_height());
        if (sigma < 0.35) return sharp;
        float maxLod = float(tex.get_num_mip_levels() - 1);
        float lod = clamp(0.5 * log2(1.0 + sigma * sigma * 2.4) - 0.5, 0.0, maxLod);
        float2 texel = float2(1.0 / float(tex.get_width()), 1.0 / float(tex.get_height())) * pow(2.0, lod) * 0.9;
        float3 acc = tex.sample(s, uv, level(lod)).rgb * 0.2;
        acc += tex.sample(s, uv + float2( 1.0,  0.0) * texel, level(lod)).rgb * 0.1;
        acc += tex.sample(s, uv + float2(-1.0,  0.0) * texel, level(lod)).rgb * 0.1;
        acc += tex.sample(s, uv + float2( 0.0,  1.0) * texel, level(lod)).rgb * 0.1;
        acc += tex.sample(s, uv + float2( 0.0, -1.0) * texel, level(lod)).rgb * 0.1;
        acc += tex.sample(s, uv + float2( 0.7071,  0.7071) * texel, level(lod)).rgb * 0.1;
        acc += tex.sample(s, uv + float2(-0.7071,  0.7071) * texel, level(lod)).rgb * 0.1;
        acc += tex.sample(s, uv + float2( 0.7071, -0.7071) * texel, level(lod)).rgb * 0.1;
        acc += tex.sample(s, uv + float2(-0.7071, -0.7071) * texel, level(lod)).rgb * 0.1;
        return mix(sharp, acc, smoothstep(0.35, 1.5, sigma));
    }

    static float lighting(constant Uniforms& u, float h) {
        float shade = 1.0 - clamp(u.dim, 0.0, 1.0) * (0.15 * u.progress + 0.40 * u.progress * h);
        return shade;
    }

            static float4 holdPixel(float2 uv, texture2d<float> tex, sampler s, constant Uniforms& u) {
        float h = 1.0 - uv.y;
        float rawTilt = clamp(u.tilt, 0.0, 1.48);
        
        // 1. Contro-Rotazione Assoluta (World-Space Anchoring): mult = 1.0 se perspective = 1.0
        float mult = clamp(u.perspective, 0.0, 1.0); 
        float tilt = rawTilt * mult;
        
        // Curva di accelerazione bilanciata: unisce il logaritmo naturale (sin) con l'esponenziale (1-cos)
        // per avere uno scatto iniziale né troppo lento né troppo veloce.
        float curve = mix(sin(tilt), 1.0 - cos(tilt), 0.7);
        
        // B controlla l'intensità della prospettiva
        float B = curve * mult * 2.0;
        
        // Mappatura Y: Omografia pura (da 0 a 1 -> da 0 a 1)
        float Y_virtual = h / (1.0 + B - B * h);
        
        // Taglio dinamico
        float crop = mix(1.0, 0.60, curve * mult);
        
        // Mappatura X: Scala per mantenere le proporzioni 3D
        float scale = (1.0 + B - B * h) / (1.0 + B);
        
        float2 src;
        src.x = 0.5 + (uv.x - 0.5) / scale;
        src.y = 1.0 - (Y_virtual * crop);

        float separation = pow(clamp(h, 0.0, 1.0), 1.5);
        float fgSigma = clamp(u.blur, 0.0, 1.0) * 0.05 * u.defocus * separation + 0.012 * u.velocity * separation;
        fgSigma = max(fgSigma, 1e-4);
        float3 fgColor = sampleBlurred(tex, s, src, fgSigma);

        // Aliasing sui bordi proiettati
        float2 fw = max(float2(min(0.015, 1.8 * fgSigma / max(u.aspect, 0.1)), min(0.015, 1.8 * fgSigma)), fwidth(src)) + 1e-5;
        float edgeX = smoothstep(-fw.x, 0.0, src.x) * (1.0 - smoothstep(1.0, 1.0 + fw.x, src.x));
        float edgeTop = smoothstep(-fw.y, 0.0, src.y);
        float coverage = edgeX * edgeTop;
        
        float3 finalColor = fgColor * coverage * lighting(u, h);
        float globalFade = 1.0 - smoothstep(0.84, 0.97, u.progress);
        return float4(finalColor * globalFade, 1.0);
    }

    static float4 fadePixel(float2 uv, texture2d<float> tex, sampler s, constant Uniforms& u) {
        float p = smoother(u.progress);
        float scaleDown = mix(1.0, max(0.1, 1.0 - clamp(u.gloss, 0.0, 1.0)), p);
        float2 src = float2((uv.x - 0.5)/scaleDown + 0.5, (uv.y - 0.5)/scaleDown + 0.5);
        if (src.x < 0.0 || src.x > 1.0 || src.y < 0.0 || src.y > 1.0) return float4(0,0,0,1);
        
        float sigmaUV = clamp(u.blur, 0.0, 1.0) * 0.05 * u.defocus;
        float3 color = sampleBlurred(tex, s, src, sigmaUV);
        
        float luminance = dot(color, float3(0.299, 0.587, 0.114));
        color = mix(color, float3(luminance), clamp(u.perspective, 0.0, 1.0) * p);

        float shade = 1.0 - clamp(u.dim, 0.0, 1.0) * p;
        float alpha = 1.0 - smoothstep(0.2, 1.0, p);
        return float4(color * shade * alpha, 1.0);
    }

    static float4 crtPixel(float2 uv, texture2d<float> tex, sampler s, constant Uniforms& u) {
        float p = smoother(u.progress);
        
        float verticalCollapse = smoothstep(0.0, 0.4, p);
        float horizontalCollapse = smoothstep(0.4, 0.7, p);
        
        float scaleY = mix(1.0, mix(0.01, 0.002, horizontalCollapse), verticalCollapse);
        float scaleX = mix(1.0, mix(0.9, 0.0, horizontalCollapse), verticalCollapse);
        
        float2 src = float2((uv.x - 0.5)/max(scaleX, 0.0001) + 0.5, (uv.y - 0.5)/max(scaleY, 0.0001) + 0.5);
        
        float aberration = verticalCollapse * 0.03 * clamp(u.blur, 0.0, 1.0);
        
        if (src.x < 0.0 || src.x > 1.0 || src.y < 0.0 || src.y > 1.0) return float4(0,0,0,1);
        
        float r = tex.sample(s, clamp(src + float2(aberration, 0), 0.0, 1.0)).r;
        float g = tex.sample(s, src).g;
        float b = tex.sample(s, clamp(src - float2(aberration, 0), 0.0, 1.0)).b;
        
        float3 color = float3(r, g, b);
        
        float scanline = sin(uv.y * 1200.0) * 0.1 * clamp(u.gloss, 0.0, 1.0);
        color -= scanline;
        
        float dist = distance(uv, float2(0.5, 0.5));
        float vignetteStr = clamp(u.perspective, 0.0, 1.0);
        float vignetteEffect = smoothstep(0.8, 0.2, dist * verticalCollapse);
        color *= mix(1.0, vignetteEffect, vignetteStr);
        
        float flash = smoothstep(0.3, 0.5, p) * (1.0 - smoothstep(0.5, 0.7, p)) * 3.0;
        float dotFade = smoothstep(0.65, 0.75, p) * (1.0 - smoothstep(0.75, 0.95, p)) * 5.0;
        
        color = color + float3(flash) + float3(dotFade);
        return float4(color, 1.0);
    }

    static float4 sleepPixel(float2 uv, texture2d<float> tex, sampler s, constant Uniforms& u) {
        float p = smoother(u.progress);
        
        float maxZoom = 1.0 + clamp(u.perspective, 0.0, 1.0) * 0.5;
        float scale = mix(1.0, maxZoom, p);
        float2 src = float2((uv.x - 0.5)/scale + 0.5, (uv.y - 0.5)/scale + 0.5);
        
        if (src.x < 0.0 || src.x > 1.0 || src.y < 0.0 || src.y > 1.0) return float4(0,0,0,1);
        
        float sigmaUV = clamp(u.blur, 0.0, 1.0) * 0.08 * u.defocus;
        float3 color = sampleBlurred(tex, s, src, sigmaUV);
        
        float luminance = dot(color, float3(0.299, 0.587, 0.114));
        float desatAmount = clamp(u.gloss, 0.0, 1.0);
        // Usa smoothstep per accelerare la desaturazione all'inizio
        color = mix(color, float3(luminance), desatAmount * smoothstep(0.0, 0.4, p));
        
        float shade = 1.0 - clamp(u.dim, 0.0, 1.0) * p * 1.5;
        shade = max(0.0, shade);
        float fade = 1.0 - smoothstep(0.3, 0.95, p);
        
        return float4(color * shade * fade, 1.0);
    }

    static float rand(float2 co){
        return fract(sin(dot(co.xy ,float2(12.9898,78.233))) * 43758.5453);
    }

    static float4 glitchPixel(float2 uv, texture2d<float> tex, sampler s, constant Uniforms& u) {
        float p = u.progress;
        
        float intensity = p * 0.3;
        float2 glitchUV = uv;
        
        float blockThreshold = mix(1.01, 0.70, clamp(u.blur, 0.0, 1.0)); 
        
        float blockY = floor(uv.y * 40.0);
        float noise = rand(float2(blockY, p));
        if (noise > blockThreshold) {
            glitchUV.x += (rand(float2(p, blockY)) - 0.5) * intensity * 2.0;
        }
        
        if (rand(float2(uv.y * 100.0, p)) > mix(1.01, 0.90, clamp(u.blur, 0.0, 1.0))) {
            glitchUV.x += (rand(float2(p, uv.y)) - 0.5) * intensity * 0.5;
        }
        
        float2 grid = floor(uv * 50.0);
        if (rand(grid + p) > mix(1.01, 0.92, clamp(u.blur, 0.0, 1.0))) {
            glitchUV.y += (rand(grid) - 0.5) * intensity;
        }
        
        float rgbSplit = intensity * clamp(u.perspective, 0.0, 1.0) * 0.5;
        
        float r = tex.sample(s, clamp(glitchUV + float2(rgbSplit, 0.0), 0.0, 1.0)).r;
        float g = tex.sample(s, clamp(glitchUV, 0.0, 1.0)).g;
        float b = tex.sample(s, clamp(glitchUV - float2(rgbSplit, 0.0), 0.0, 1.0)).b;
        
        float scanline = sin(uv.y * 800.0 + p * 10.0) * 0.08 * clamp(u.gloss, 0.0, 1.0);
        float3 color = float3(r, g, b) - scanline;
        
        if (rand(float2(p, 1.0)) > mix(1.01, 0.90, clamp(u.gloss, 0.0, 1.0))) {
            color += 0.2;
        }
        
        float shade = 1.0 - clamp(u.dim, 0.0, 1.0) * p;
        float fade = 1.0 - smoothstep(0.6, 0.95, p);
        
        return float4(color * shade * fade, 1.0);
    }

    static float4 notchPixel(float2 uv, texture2d<float> tex, sampler s, constant Uniforms& u) {
        float p = u.progress;
        
        float sigmaUV = clamp(u.blur, 0.0, 1.0) * 0.05 * p;
        float3 color = sampleBlurred(tex, s, uv, sigmaUV);
        float shade = 1.0 - clamp(u.dim, 0.0, 1.0) * p * 0.5;
        
        // Curva morbida per l'espansione
        float p_notch = pow(p, 1.5);
        
        // Partiamo da dimensioni STRETTAMENTE MINORI del notch fisico del MacBook.
        // Il notch fisico è circa largo 16% (0.16) e alto 4.5% (0.045).
        // Partendo da width 0.10 e height 0.02, il notch software viene renderizzato,
        // ma è completamente coperto e nascosto dal notch nero hardware.
        // Man mano che chiudi, "sbucherà" da sotto il notch vero.
        float nWidth = mix(0.10, 3.0, p_notch);
        float nHeight = mix(0.02, 2.0, p_notch);
        float nRadius = mix(0.01, 0.3, p_notch);
        
        float2 d = float2(abs(uv.x - 0.5), uv.y);
        float2 q = d - float2(nWidth * 0.5 - nRadius, nHeight - nRadius);
        float dist = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - nRadius;
        
        float notchMask = 1.0 - smoothstep(-0.01, 0.01, dist);
        
        color = mix(color * shade, float3(0.0), notchMask);
        return float4(color, 1.0);
    }
    static float4 swellPixel(float2 uv, texture2d<float> tex, sampler s, constant Uniforms& u) {
        float h = 1.0 - uv.y;
        float p = smoother(u.progress);
        float expansion = 1.0 + p * (0.10 + mix(0.25, 0.60, clamp(u.perspective, 0.0, 1.0)) * h);
        float2 src = float2(0.5 + (uv.x - 0.5) / expansion, 1.0 - h / expansion);

        float spread = 0.12 + 0.88 * pow(clamp(h, 0.0, 1.0), 1.15);
        float sigmaUV = clamp(u.blur, 0.0, 1.0) * 0.05 * u.defocus * spread + 0.012 * u.velocity * spread;
        float3 color = sampleBlurred(tex, s, src, sigmaUV);

        float soft = clamp(u.blur, 0.0, 1.0);
        float topW = max(p * (0.07 + 0.14 * soft) + 1.5 * sigmaUV, 1e-4);
        float sideW = max((p * (0.05 + 0.11 * soft) + 1.5 * sigmaUV) / max(u.aspect, 0.1), 1e-4);
        float mask = smoothstep(0.0, topW, uv.y) * smoothstep(0.0, sideW, uv.x) * smoothstep(0.0, sideW, 1.0 - uv.x);
        return float4(color * mask * lighting(u, h), 1.0);
    }

    static float3 glassLight(float3 color, float2 uv, constant Uniforms& u) {
        float h = 1.0 - uv.y;
        float tiltNorm = clamp(u.tilt, 0.0, 1.48);
        float gloss    = clamp(u.gloss, 0.0, 1.0);
        float bend     = sin(tiltNorm) * gloss;
        float fade     = 1.0 - smoothstep(0.82, 0.97, u.progress);

        float hinge    = exp(-pow(uv.y / 0.012, 2.0)) * 0.55;
        float diagonal = h * 0.72 + (uv.x - 0.5) * 0.38;
        float band     = exp(-pow((diagonal - 0.50) / 0.16, 2.0)) * 0.28;
        float rightEdge = exp(-pow((uv.x - 1.0) / 0.018, 2.0)) * 0.22;

        float3 light = float3(0.92, 0.95, 1.00);
        return color + light * (hinge + band + rightEdge) * bend * fade;
    }

    fragment float4 duoFragment(VOut in [[stage_in]],
                                texture2d<float> tex [[texture(0)]],
                                constant Uniforms& u [[buffer(0)]]) {
        constexpr sampler s(coord::normalized, address::clamp_to_edge, filter::linear, mip_filter::linear);
        if (u.progress <= 0.0 && u.tilt <= 0.0 && u.defocus <= 0.0) {
            return float4(tex.sample(s, in.uv, level(0.0)).rgb, 1.0);
        }
        if (u.progress >= 0.98) return float4(0.0, 0.0, 0.0, 1.0);
        float4 result;
        switch (u.style) {
            case 1u: result = swellPixel(in.uv, tex, s, u); break;
            case 2u: result = fadePixel(in.uv, tex, s, u); break;
            case 3u: result = crtPixel(in.uv, tex, s, u); break;
            case 4u: result = sleepPixel(in.uv, tex, s, u); break;
            case 5u: result = glitchPixel(in.uv, tex, s, u); break;
            case 6u: result = notchPixel(in.uv, tex, s, u); break;
            default: result = holdPixel(in.uv, tex, s, u); break;
        }
        if (u.style <= 1u) {
            result.rgb = glassLight(result.rgb, in.uv, u);
        } else if (u.progress < 0.04) {
            result.rgb = mix(tex.sample(s, in.uv, level(0.0)).rgb, result.rgb, smoothstep(0.0, 0.04, u.progress));
        }
        return result;
    }
    """#
}
