#version 460 core
#include <flutter/runtime_effect.glsl>

uniform vec2 uResolution;
uniform float uTime;
uniform float uEnergy;

out vec4 fragColor;

// High-performance pseudo-random 3D hash
float hash31(vec3 p) {
    p = fract(p * vec3(443.897, 441.423, 437.195));
    p += dot(p, p.yzx + 19.19);
    return fract((p.x + p.y) * p.z);
}

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

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 uv = (fragCoord - 0.5 * uResolution) / min(uResolution.x, uResolution.y);
    
    // Position slightly upper-center so it harmonizes behind chat transcript
    uv.y += 0.06;

    float t = uTime;
    float energy = uEnergy;
    float speed = energy > 1.2 ? 1.8 : 1.0;

    float r = length(uv);
    // Base radius of the sphere in UV space
    float R = 0.38 + 0.010 * sin(t * 2.5 * speed);

    // ─────────────────────────────────────────────
    // 1. Color Palette (Reference Image: Luminous Celestial Purple)
    // ─────────────────────────────────────────────
    vec3 colWhite = vec3(1.0, 0.98, 1.0);
    vec3 colLavender = vec3(0.88, 0.74, 1.0);
    vec3 colViolet = vec3(0.70, 0.42, 0.98);
    vec3 colDeepPurple = vec3(0.44, 0.18, 0.78);
    vec3 colAmethyst = vec3(0.55, 0.25, 0.88);

    vec3 col = vec3(0.0);
    float alpha = 0.0;

    // ─────────────────────────────────────────────
    // 2. Hyper-Intense Radiant Rim / Corona Halo (Exact Match)
    // ─────────────────────────────────────────────
    float dRim = abs(r - R);
    
    // Ultra-sharp bright emission along perimeter
    float rimGlow = 0.0032 / (dRim * dRim * 26.0 + 0.00032);
    // Secondary softer atmospheric glow ring
    float rimHaze = exp(-dRim * 26.0) * 0.88;

    // Horizontal Anamorphic Lens Flare (Horizontal light bleed on sides)
    float horizDist = abs(uv.y);
    float horizStreak = exp(-horizDist * 32.0) * exp(-abs(r - R) * 14.0) * 0.48;

    // Subtle micro-spikes / corona glints on the rim
    float angle = atan(uv.y, uv.x);
    float rays = sin(angle * 72.0 + t * 2.8) * sin(angle * 36.0 - t * 1.8);
    float rimSparkle = smoothstep(0.3, 0.9, rays) * exp(-dRim * 38.0) * 0.35;

    float totalRim = rimGlow * 1.45 + rimHaze * 0.72 + horizStreak + rimSparkle;
    vec3 rimCol = mix(colViolet, colLavender, clamp(rimGlow * 0.5, 0.0, 1.0));
    rimCol = mix(rimCol, colWhite, clamp(rimGlow * 0.82 - 0.45, 0.0, 1.0));

    col += rimCol * totalRim;
    alpha += totalRim * 0.92;

    // ─────────────────────────────────────────────
    // 3. Volumetric Quantum Particle Cloud inside the Sphere (r < R)
    // ─────────────────────────────────────────────
    if (r < R) {
        // Spherical 3D depth: z coordinate
        float z = sqrt(max(0.0, R * R - r * r));
        float zNorm = z / R; // 1.0 at center, 0.0 at rim
        
        // 3D rotation of the starfield core
        mat3 rot = rotateY(t * 0.35 * speed) * rotateX(t * 0.18);
        
        // Multiple depth layers of twinkling celestial stardust
        float stardust = 0.0;
        float fineGlitter = 0.0;
        
        // Layer 1: Dense 3D rotating starfield
        for (int layer = 0; layer < 3; layer++) {
            float depthOffset = (float(layer) - 1.0) * 0.55 * z;
            vec3 pos3D = rot * vec3(uv.x * 1.05, uv.y * 1.05, depthOffset);
            
            float gridSize = 68.0 + float(layer) * 26.0;
            vec3 cell = floor(pos3D * gridSize);
            float rnd = hash31(cell);
            
            if (rnd > 0.82) {
                vec3 pInCell = fract(pos3D * gridSize) - 0.5;
                float dPt = length(pInCell);
                float twinkle = sin(t * 5.2 * speed + rnd * 30.0) * 0.5 + 0.5;
                float intensity = smoothstep(0.42, 0.02, dPt) * (0.4 + twinkle * 0.6);
                stardust += intensity * (0.65 + rnd * 0.65);
            }
        }

        // Layer 2: Ultra-fine high-density micro-sparkle mist
        vec3 microPos = rot * vec3(uv * 185.0, z * 95.0);
        float noiseVal = hash31(floor(microPos));
        if (noiseVal > 0.87) {
            float microTwinkle = sin(t * 8.5 * speed + noiseVal * 42.0) * 0.5 + 0.5;
            fineGlitter += (noiseVal - 0.87) * 8.5 * microTwinkle;
        }

        // Layer 3: Vertical micro-strands / scanlines in lower hemisphere (Ref Image detail)
        float lowerMask = smoothstep(0.05, -0.25, uv.y) * zNorm;
        float verticalStrands = sin(uv.x * 290.0) * 0.5 + 0.5;
        verticalStrands = pow(verticalStrands, 3.0) * lowerMask * 0.45;

        // Combine particle cloud
        float totalParticles = stardust * 0.88 + fineGlitter * 0.68 + verticalStrands;

        // Particle color gradient: lavender / violet / incandescent white sparks
        vec3 starColor = mix(colDeepPurple, colLavender, clamp(totalParticles, 0.0, 1.0));
        starColor = mix(starColor, colWhite, clamp(stardust * 0.65 - 0.28, 0.0, 1.0));

        col += starColor * totalParticles;
        
        // Internal luminous atmospheric haze (soft purple gas)
        float innerHaze = (1.0 - zNorm * 0.35) * 0.20;
        col += colDeepPurple * innerHaze;
        
        alpha = max(alpha, clamp(totalParticles * 0.85 + 0.28, 0.0, 1.0));
    }

    // ─────────────────────────────────────────────
    // 4. Outer Celestial Glow Falloff (r > R)
    // ─────────────────────────────────────────────
    if (r >= R) {
        float outerDist = r - R;
        float softAura = exp(-outerDist * 8.5) * 0.44 + exp(-outerDist * 3.2) * 0.16;
        vec3 auraCol = mix(colViolet, colDeepPurple, clamp(outerDist * 4.0, 0.0, 1.0));
        col += auraCol * softAura;
        alpha = max(alpha, softAura * 0.88);
    }

    // Thinking state boost
    if (energy > 1.1) {
        float boost = (energy - 1.0) * 0.48;
        col *= (1.0 + boost);
    }

    // Soft vignette at edges
    float vignette = smoothstep(1.30, 0.22, length(uv));
    col *= vignette;
    alpha *= vignette;

    fragColor = vec4(col, clamp(alpha, 0.0, 1.0));
}
