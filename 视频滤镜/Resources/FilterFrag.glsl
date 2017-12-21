varying highp vec2 texCoordVarying;
precision mediump float;
uniform sampler2D Sampler;
uniform sampler2D Sampler2;
uniform sampler2D Sampler3;
uniform  int type;
uniform mat4 colorConversionMatrix;
uniform float intensity;
lowp vec4 lut3d(highp vec4 textureColor)
{
    mediump float blueColor = textureColor.b * 15.0;
    mediump vec2 quad1;
    quad1.y = max(min(4.0,floor(floor(blueColor) / 4.0)),0.0);
    quad1.x = max(min(4.0,floor(blueColor) - (quad1.y * 4.0)),0.0);
    mediump vec2 quad2;
    quad2.y = max(min(floor(ceil(blueColor) / 4.0),4.0),0.0);
    quad2.x = max(min(ceil(blueColor) - (quad2.y * 4.0),4.0),0.0);
    highp vec2 texPos1;
    texPos1.x = (quad1.x * 0.25) + 0.5/64.0 + ((0.25 - 1.0/64.0) * textureColor.r);
    texPos1.y = (quad1.y * 0.25) + 0.5/64.0 + ((0.25 - 1.0/64.0) * textureColor.g);
    highp vec2 texPos2;
    texPos2.x = (quad2.x * 0.25) + 0.5/64.0 + ((0.25 - 1.0/64.0) * textureColor.r);
    texPos2.y = (quad2.y * 0.25) + 0.5/64.0 + ((0.25 - 1.0/64.0) * textureColor.g);
    lowp vec4 newColor1 = texture2D(Sampler2, texPos1);
    lowp vec4 newColor2 = texture2D(Sampler2, texPos2);
    mediump vec4 newColor = mix(newColor1, newColor2, fract(blueColor));
    return newColor;     }

void main()
{
    lowp vec4 textureColor;
    if (type == 0){
        gl_FragColor = texture2D(Sampler, texCoordVarying);
    }else if (type == 1){
        textureColor = texture2D(Sampler, texCoordVarying);
        gl_FragColor = vec4((1.0 - textureColor.rgb), textureColor.w);
    }else if(type == 2){
        textureColor = texture2D(Sampler, texCoordVarying);
        mat4 colorMatrix = mat4(0.3588, 0.7044, 0.1368, 0.0,
                                0.2990, 0.5870, 0.1140, 0.0,
                                0.2392, 0.4696, 0.0912,0.0,
                                0,0,0,1.0);
        gl_FragColor = textureColor * colorMatrix;
    }else if(type == 3 || type == 4){
        vec4 textureColor = texture2D(Sampler, texCoordVarying);
        float blueColor = textureColor.b * 63.0;
        
        vec2 quad1;
        quad1.y = floor(floor(blueColor) / 8.0);
        quad1.x = floor(blueColor) - (quad1.y * 8.0);
        
        vec2 quad2;
        quad2.y = floor(ceil(blueColor) / 8.0);
        quad2.x = ceil(blueColor) - (quad2.y * 8.0);
        
        vec2 texPos1;
        texPos1.x = (quad1.x * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.r);
        texPos1.y = (quad1.y * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.g);
        
        vec2 texPos2;
        texPos2.x = (quad2.x * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.r);
        texPos2.y = (quad2.y * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.g);
        
        vec4 newColor1 = texture2D(Sampler2, texPos1);
        vec4 newColor2 = texture2D(Sampler2, texPos2);
        
        vec4 newColor = mix(newColor1, newColor2, fract(blueColor));
        gl_FragColor = mix(textureColor, vec4(newColor.rgb, textureColor.w), 1.0);
    }else if (type == 7){// 特效
        lowp vec4 base = texture2D(Sampler, texCoordVarying);
        lowp vec4 overlayer = texture2D(Sampler2, texCoordVarying);
        gl_FragColor = base + overlayer;
    }else if (type == 100){
        //gl_FragColor = texture2D(Sampler, texCoordVarying);
        int width = 1280;
        int height = 720;
        vec4 grayMat = vec4(0.299,0.587,0.114,0.0);
        vec4 color = texture2D(Sampler,texCoordVarying);
        float g = dot(color,grayMat);
        float tx;
        float ty;
        tx = 1.0 / float(width);
        ty = 1.0 / float(height);
        vec4 tmp = vec4(0.0);
        vec4 c1;
        c1 = texture2D(Sampler,texCoordVarying+ vec2(-1.0*tx,-1.0*ty));
        tmp = max(tmp,c1);
        c1 = texture2D(Sampler,texCoordVarying+ vec2(0.0*tx,-1.0*ty));
        tmp = max(tmp,c1);
        c1 = texture2D(Sampler,texCoordVarying + vec2(1.0*tx,-1.0*ty));
        tmp = max(tmp,c1);
        c1 = texture2D(Sampler,texCoordVarying+ vec2(-1.0*tx,0.0*ty));
        tmp = max(tmp,c1);
        c1 = color;
        tmp = max(tmp,c1);
        c1 = texture2D(Sampler,texCoordVarying+ vec2(1.0*tx,0.0*ty));
        tmp = max(tmp,c1);
        c1 = texture2D(Sampler,texCoordVarying+ vec2(-1.0*tx,1.0*ty));
        tmp = max(tmp,c1);
        c1 = texture2D(Sampler,texCoordVarying+ vec2(0.0*tx,1.0*ty));
        tmp = max(tmp,c1);
        c1 = texture2D(Sampler,texCoordVarying+ vec2(1.0*tx,1.0*ty));
        tmp = max(tmp,c1);
        vec4 dd;
        float threshold = 57.0/255.0;
        dd = color/tmp;
        g = clamp(g,0.0,threshold);
        float ratio = g/threshold;
        dd = ratio*dd + (1.0 - ratio)*color;
        g = dot(grayMat,dd);
        g = min(1.0,max(0.0,g));
        vec4 yiq;
        mat3 rgb2yiq = mat3(0.299,0.596,0.211,0.587,-0.275,-0.532,0.114,-0.322,0.312);
        yiq.rgb = rgb2yiq*color.rgb;
        yiq.r =  max(min(pow(g, 2.7), 1.0),0.0);
        vec4 rgb;
        mat3 yiq2rgb = mat3(1.0,1.0,1.0,0.956,-0.272,-1.106,0.621,-1.703,0.0);
        rgb.rgb = yiq2rgb*yiq.rgb;
        rgb.a = 1.0;
        gl_FragColor = rgb;
    }else if (type == 6){
        highp vec2 center = vec2(0.5, 0.5);
        highp float radius = 0.71;
        highp float aspectRatio = 1.0;
        highp float refractiveIndex = 0.51;
        highp vec3 lightPosition = vec3(-0.5, 0.5, 1.0);
        highp vec3 ambientLightPosition = vec3(0.0, 0.0, 1.0);
        
        highp vec2  texCoordVaryingToUse = vec2( texCoordVarying.x, ( texCoordVarying.y * aspectRatio + 0.5 - 0.5 * aspectRatio));
        highp float distanceFromCenter = distance(center,  texCoordVaryingToUse);
        lowp float checkForPresenceWithinSphere = step(distanceFromCenter, radius);
        distanceFromCenter = distanceFromCenter / radius;
        highp float normalizedDepth = radius * sqrt(1.0 - distanceFromCenter * distanceFromCenter);
        highp vec3 sphereNormal = normalize(vec3( texCoordVaryingToUse - center, normalizedDepth));
        highp vec3 refractedVector = 2.0 * refract(vec3(0.0, 0.0, -1.0), sphereNormal, refractiveIndex);
        refractedVector.xy = -refractedVector.xy;
        highp vec3 finalSphereColor = texture2D(Sampler, (refractedVector.xy + 1.0) * 0.5).rgb;       // Grazing angle lighting
        highp float lightingIntensity = 2.5 * (1.0 - pow(clamp(dot(ambientLightPosition, sphereNormal), 0.0, 1.0), 0.25));
        finalSphereColor += lightingIntensity;       // Specular lighting
        lightingIntensity  = clamp(dot(normalize(lightPosition), sphereNormal), 0.0, 1.0);
        lightingIntensity  = pow(lightingIntensity, 15.0);
        finalSphereColor += vec3(0.8, 0.8, 0.8) * lightingIntensity;
        gl_FragColor = vec4(finalSphereColor, 1.0) * checkForPresenceWithinSphere;
    }else if (type == 7){
        vec4 orgColor =texture2D(Sampler, texCoordVarying);
        gl_FragColor = lut3d(orgColor);
    }else if (type == 8){
        vec4 value = texture2D(Sampler, texCoordVarying);
        float r = texture2D(Sampler2, vec2(value.r, 0.5)).r;
        float g = texture2D(Sampler2, vec2(value.g, 0.5)).g;
        float b = texture2D(Sampler2, vec2(value.b, 0.5)).b;
        gl_FragColor = vec4(r,g,b,1.0);
    }else if (type == 9){
        vec4 oralData = texture2D(Sampler, texCoordVarying).rgba;
        vec3 graymat = vec3(0.29,0.586,0.114);
        float gray = dot(graymat,oralData.rgb);
        oralData.r = texture2D( Sampler2, vec2(gray,oralData.r)).r;
        oralData.g = texture2D( Sampler2, vec2(gray,oralData.g)).r;
        oralData.b = texture2D( Sampler2, vec2(gray,oralData.b)).r;
        float x = 1.6;
        float rm = 0.30859375*(1.0-x);
        float gm =  0.609375*(1.0-x);
        float bm = 0.08203125*(1.0-x);
        float all = rm * oralData.r + gm * oralData.g + bm * oralData.b;
        oralData.r = max(0.0,min(1.0,all + x * oralData.r));
        oralData.g = max(0.0,min(1.0,all + x * oralData.g));
        oralData.b = max(0.0,min(1.0,all + x * oralData.b));
        oralData.r = texture2D( Sampler3, vec2(oralData.r,0.5)).r;
        oralData.g = texture2D( Sampler3, vec2(oralData.g,0.5)).g;
        oralData.b = texture2D( Sampler3, vec2(oralData.b,0.5)).b;
        gl_FragColor = oralData;
    }else if (type == 300){ // 本地照片渲染
        vec4 orgColor =texture2D(Sampler, texCoordVarying);
        gl_FragColor = vec4(orgColor.b,orgColor.g,orgColor.r,1.0);
    }
}
