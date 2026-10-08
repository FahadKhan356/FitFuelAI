#version 460 core
#include <flutter/runtime_effect.glsl>

uniform vec2 uResolution;
uniform float uTime;
uniform float uEnergy;

out vec4 fragColor;

// 3D rotation around Y and X axes
mat3 rotateY(float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return mat3(
        c, 0.0, s,
        0.0, 1.0, 0.0,
        -s, 0.0, c
    );
}

mat3 rotateX(float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return mat3(
        1.0, 0.0, 0.0,
        0.0, c, -s,
        0.0, s, c
    );
}

// Signed Distance Field (SDF) of the dynamic undulating 3D intelligence sphere
float map(vec3 p, float t, float energy) {
    float r = length(p);
    
    // Multi-octave organic fluid wave displacement (Ref Image 1 & 2)
    float w1 = sin(p.x * 4.5 + t * 2.0) * cos(p.z * 4.5 + t * 1.6);
    float w2 = cos(p.y * 5.8 - t * 2.4 + p.x * 1.8);
    float w3 = sin((p.x * p.z) * 7.5 + t * 2.8);
    float w4 = cos((p.x + p.y) * 9.0 - t * 2.0);
    
    float disp = (w1 * 0.075 + w2 * 0.055 + w3 * 0.035 + w4 * 0.02) * energy;
    
    // Base sphere radius = 0.76 with wave ripples
    return (r - 0.76) + disp;
}

// Calculate surface normal using tetrahedron finite differences
vec3 calcNormal(vec3 p, float t, float energy) {
    const float h = 0.002;
    const vec2 k = vec2(1.0, -1.0);
    return normalize(
        k.xyy * map(p + k.xyy * h, t, energy) +
        k.yyx * map(p + k.yyx * h, t, energy) +
        k.yxy * map(p + k.yxy * h, t, energy) +
        k.xxx * map(p + k.xxx * h, t, energy)
    );
}

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 uv = (fragCoord - 0.5 * uResolution) / min(uResolution.x, uResolution.y);
    
    // Shift slightly upward for optimal harmony behind chat transcript
    uv.y += 0.08;

    float t = uTime;
    float energy = uEnergy;

    // Camera setup in 3D space
    vec3 ro = vec3(0.0, 0.0, -2.35);
    vec3 rd = normalize(vec3(uv, 1.85));

    // Dynamic 3D rotation matrix
    float rotY = t * 0.75 * (energy > 1.2 ? 1.8 : 1.0);
    float rotX = 0.28 + sin(t * 0.45) * 0.12;
    mat3 rot = rotateX(rotX) * rotateY(rotY);

    // Transform camera ray into object space
    ro = rot * ro;
    rd = rot * rd;

    // Raymarching loop with volumetric glow accumulation
    float dO = 0.0;
    float glow = 0.0;
    float minD = 100.0;
    vec3 p = ro;
    bool hit = false;

    // Bounding sphere acceleration test
    float bSphere = length(cross(ro, rd)) - 1.25;
    if (bSphere > 0.0) {
        // Outside bounding envelope, render purely ambient cosmic aura
        float dEdge = length(uv);
        float aura = exp(-dEdge * 2.8) * 0.22;
        vec3 auraCol = mix(vec3(0.0, 0.95, 1.0), vec3(0.55, 0.25, 0.95), uv.y + 0.5);
        fragColor = vec4(auraCol * aura, aura * 0.8);
        return;
    }

    for (int i = 0; i < 48; i++) {
        p = ro + rd * dO;
        float dS = map(p, t, energy);
        
        minD = min(minD, dS);
        
        // Accumulate ethereal volumetric corona glow (Ref Image 2)
        glow += 0.016 / (0.018 + dS * dS * 8.0);

        if (abs(dS) < 0.0018) {
            hit = true;
            break;
        }

        if (dO > 3.8) break;
        dO += dS * 0.78; // Conservative step size for ultra-smooth surface
    }

    // ─────────────────────────────────────────────
    // 4K Cinema Lighting & Color Palette
    // ─────────────────────────────────────────────
    vec3 col = vec3(0.0);
    float alpha = 0.0;

    // Colors matching Reference Image 1 & 2
    vec3 colCyan = vec3(0.0, 0.95, 1.0);
    vec3 colBlue = vec3(0.22, 0.65, 1.0);
    vec3 colIndigo = vec3(0.39, 0.40, 0.95);
    vec3 colViolet = vec3(0.58, 0.28, 0.96);
    vec3 colMagenta = vec3(0.96, 0.22, 0.68);
    vec3 colHotPink = vec3(1.0, 0.28, 0.50);

    if (hit) {
        vec3 n = calcNormal(p, t, energy);
        
        // Upper-front key light
        vec3 lightDir = normalize(vec3(0.35, -0.65, 0.70));
        float diff = max(0.0, dot(n, lightDir));
        
        // Fresnel rim-lighting (radiant plasma atmosphere from Ref Image 2)
        float fresnel = pow(1.0 - max(0.0, dot(n, -rd)), 2.8);
        
        // Specular glint
        vec3 ref = reflect(-lightDir, n);
        float spec = pow(max(0.0, dot(ref, -rd)), 24.0);

        // 3D Topological Contour Wave Grid / Micro-Bead Ribbons (Ref Image 1)
        float latitude = (p.y + 0.8) * 34.0;
        float longitude = atan(p.z, p.x) * 26.0;
        float waveRibbon = sin(latitude + sin(longitude * 0.5 + t * 2.0) * 2.0);
        float microDots = smoothstep(0.25, 0.85, sin(longitude) * waveRibbon);

        // Height & wave based spectral gradient
        float h = (p.y + 0.76) / 1.52;
        vec3 surfaceBase;
        if (h < 0.35) {
            surfaceBase = mix(colHotPink, colMagenta, h / 0.35);
        } else if (h < 0.70) {
            surfaceBase = mix(colMagenta, colIndigo, (h - 0.35) / 0.35);
        } else {
            surfaceBase = mix(colIndigo, colCyan, (h - 0.70) / 0.30);
        }

        // Apply topological dot-mesh highlights (Ref Image 1)
        vec3 dotGlint = mix(colCyan, vec3(1.0), spec);
        surfaceBase = mix(surfaceBase * 0.75, dotGlint * 1.45, microDots * 0.85);

        // Diffuse, Fresnel rim and Specular illumination
        col = surfaceBase * (0.35 + 0.65 * diff);
        col += mix(colCyan, colViolet, fresnel) * (fresnel * 1.6);
        col += vec3(1.0, 1.0, 1.0) * (spec * 0.75);

        alpha = 0.95;
    } else {
        // Subtle ambient deep space field behind the core
        alpha = clamp(glow * 0.08, 0.0, 0.85);
    }

    // Add radiant volumetric corona halo (Ref Image 2)
    vec3 coronaCol = mix(colViolet, colCyan, clamp(glow * 0.15, 0.0, 1.0));
    col += coronaCol * (glow * 0.038);
    alpha = max(alpha, clamp(glow * 0.065, 0.0, 0.92));

    // Outer edge soft vignette falloff
    float dFromCenter = length(uv);
    float vignette = smoothstep(1.35, 0.25, dFromCenter);
    col *= vignette;
    alpha *= vignette;

    fragColor = vec4(col, alpha);
}
