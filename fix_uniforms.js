const fs = require('fs');
let code = fs.readFileSync('Source/Sources/Overlay/DuoRenderer.swift', 'utf8');

const targetStr = `        var uniforms = FoldUniforms(
            tilt: Float(state.tilt),
            progress: Float(state.progress),
            defocus: Float(state.defocus),
            style: appearance.style.shaderIndex,
            blur: Float(appearance.blur),
            dim: Float(appearance.dimming),
            perspective: Float(perspective),
            eyeDistance: Float(4.0 - 2.4 * perspective),
            aspect: Float(texture.width) / Float(max(1, texture.height)),
            width: Float(texture.width),
            height: Float(texture.height),
            velocity: Float(state.velocity),
            gloss: Float(appearance.reflections)
        )`;

const replacementStr = `        let tint = PreferencesManager.shared.tintColor
        var r: Float = 1.0, g: Float = 1.0, b: Float = 1.0
        switch tint {
        case .white: r = 1.0; g = 1.0; b = 1.0
        case .green: r = 0.2; g = 1.0; b = 0.3
        case .amber: r = 1.0; g = 0.7; b = 0.2
        case .blue:  r = 0.2; g = 0.5; b = 1.0
        }

        var uniforms = FoldUniforms(
            tilt: Float(state.tilt),
            progress: Float(state.progress),
            defocus: Float(state.defocus),
            style: appearance.style.shaderIndex,
            blur: Float(appearance.blur),
            dim: Float(appearance.dimming),
            perspective: Float(perspective),
            eyeDistance: Float(4.0 - 2.4 * perspective),
            aspect: Float(texture.width) / Float(max(1, texture.height)),
            width: Float(texture.width),
            height: Float(texture.height),
            velocity: Float(state.velocity),
            gloss: Float(appearance.reflections),
            tintColorR: r,
            tintColorG: g,
            tintColorB: b
        )`;

code = code.replace(targetStr, replacementStr);
fs.writeFileSync('Source/Sources/Overlay/DuoRenderer.swift', code);
