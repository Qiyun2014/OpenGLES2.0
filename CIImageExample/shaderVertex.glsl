

// variable pass into
attribute vec4 Position;    // position of vertex
attribute vec4 SourceColor; // color of vertex
attribute vec2 TextureCoords;

// variable pass out into fragment shader
// varying means that calculate the color of every pixel between two vertex linearly(smoothly) according to the 2 vertex's color
varying vec4 DestinationColor;
varying vec2 TextureCoordsOut;

void main(void) {
    
    DestinationColor = SourceColor;
    
    // gl_Position is built-in pass-out variable. Must config for in vertex shader
    gl_Position = Position;
    TextureCoordsOut = TextureCoords;
}
