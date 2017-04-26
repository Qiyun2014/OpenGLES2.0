
precision mediump float;
uniform sampler2D Texture;
uniform int haveTexture;

varying lowp vec4 DestinationColor;
varying vec2 TextureCoordsOut;

void main(void) {
    
    if (haveTexture > 0) {
        
        vec4 mask = texture2D(Texture, TextureCoordsOut);
        gl_FragColor = vec4(mask.rgb, 1.0);
        
    }else
        gl_FragColor = DestinationColor; // must set gl_FragColor for fragment shader
}
