//
//  GLEView.h
//  CIImageExample
//
//  Created by IYNMac on 24/4/17.
//  Copyright © 2017年 IYNMac. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <OpenGLES/EAGLDrawable.h>

@interface GLEView : UIView{
    
    EAGLContext *_eaglContext;
    CAEAGLLayer *_eaglLayer;
    
    GLuint _renderBuffer;
    GLuint _frameBuffer;
    
    GLuint _glProgram;
    GLuint _positionSlot,_colorSlot;
    
    GLuint _textureSlot;
    GLuint _textureCoordsSlot;
    GLuint _textureID;
    GLuint _haveTexture;
}

- (void)processImage:(UIImage *)image;

@end

@interface GLEShaderOperations : NSObject

+ (GLuint)compileShader:(NSString *)shaderName type:(GLenum)shaderType;
+ (GLuint)compileVertexShader:(NSString *)shaderVertex shaderFragment:(NSString *)shaderFragment;

@end
