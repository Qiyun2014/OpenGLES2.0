//
//  GLEView.m
//  CIImageExample
//
//  Created by IYNMac on 24/4/17.
//  Copyright © 2017年 IYNMac. All rights reserved.
//

#import "GLEView.h"


@implementation GLEView{
    
    GLuint vertexBuffer;
    GLuint indexBuffer;
}

const GLfloat texCoords[] = {
    0, 0,//左下
    1, 0,//右下
    0, 1,//左上
    1, 1,//右上
};

const GLfloat textureVertices[] = {
    -1, -1, 0,   //左下
    1,  -1, 0,   //右下
    -1, 1,  0,   //左上
    1,  1,  0    //右上
};

const GLubyte textureIndices[] = {
    0, 1, 2,
    1, 2, 3
};

+ (Class) layerClass
{
    return [CAEAGLLayer class];
}

- (id)initWithFrame:(CGRect)frame{
    
    if (self == [super initWithFrame:frame]) {
        
        _eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        [EAGLContext setCurrentContext:_eaglContext];
        
        _eaglLayer = (CAEAGLLayer *)self.layer;
        _eaglLayer.frame = frame;
        _eaglLayer.opaque = YES;
        _eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                         [NSNumber numberWithBool:FALSE], kEAGLDrawablePropertyRetainedBacking,
                                         kEAGLColorFormatRGB565, kEAGLDrawablePropertyColorFormat,
                                         nil];
        
        [self processBuffer];
        [self processShaders];
        
        glGenBuffers(1, &indexBuffer);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);

        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
        glBufferData(GL_ARRAY_BUFFER, sizeof(textureVertices), textureVertices, GL_STATIC_DRAW);

        [_eaglContext presentRenderbuffer:GL_RENDERBUFFER];
    }
    return self;
}

- (void)destoryBuffer{
    
    //destory render and frame buffer
    if (_renderBuffer) {
        glDeleteRenderbuffers(1, &_renderBuffer);
        _renderBuffer = 0;
    }
    
    if (_frameBuffer) {
        glDeleteFramebuffers(1, &_frameBuffer);
        _frameBuffer = 0;
    }
}

- (void)processBuffer{
    
    [EAGLContext setCurrentContext:_eaglContext];
    
    [self destoryBuffer];
    
    glGenRenderbuffers(1, &_renderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
    [_eaglContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:(id<EAGLDrawable>)_eaglLayer];
    
    glGenFramebuffers(1, &_frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    
    glFramebufferRenderbuffer(GL_FRAMEBUFFER,
                              GL_COLOR_ATTACHMENT0,
                              GL_RENDERBUFFER,
                              _renderBuffer);
    
    glClearColor(0.5f, 0.5f, 0.5f, 1.0f);
    
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glViewport(0, 0, self.frame.size.width, self.frame.size.height);
    
    glEnable(GL_BLEND);
    glBlendFunc(GL_ONE, GL_ZERO);
}

- (void)processShaders{
    
    _glProgram = [GLEShaderOperations compileVertexShader:@"shaderVertex" shaderFragment:@"shaderFragment"];
    glUseProgram(_glProgram);
    
    _positionSlot = glGetAttribLocation(_glProgram, "Position");
    _colorSlot = glGetAttribLocation(_glProgram, "SourceColor");
    
    _textureSlot = glGetAttribLocation(_glProgram, "Texture");
    _textureCoordsSlot = glGetAttribLocation(_glProgram, "TextureCoords");
    _haveTexture = glGetUniformLocation(_glProgram, "haveTexture");
    
    /*
    // 定义一个Vertex结构, 其中包含了坐标和颜色
    typedef struct{
        float Position[3];
        float Color[4];
    } Vertex;

    // 顶点数组
    const Vertex Vertices[] = {
        {{-1, -1, 0}, {1, 0, 0, 1}},
        {{1,  -1, 0}, {0, 1, 0, 1}},
        {{-1,  1, 0}, {0, 0, 1, 1}},
        {{1,   1, 0}, {1, 1, 1, 1}},
    };
    
    const GLubyte Indices[] = {
        0, 1, 2,
        1, 2, 3
    };
    
    GLuint vertexBuffer;
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertices), Vertices, GL_STATIC_DRAW);
    
    GLuint indexBuffer;
    glGenBuffers(1, &indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Indices), Indices, GL_STATIC_DRAW);
    
    // 取出Vertices数组中的坐标点值，赋给_positionSlot
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), 0);
    glEnableVertexAttribArray(_positionSlot);
    
    // 取出Colors数组中的每个坐标点的颜色值，赋给_colorSlot
    glVertexAttribPointer(_colorSlot, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid *)(sizeof(float) * 3));
    glEnableVertexAttribArray(_colorSlot);
    
    // 绘制两个三角形，复用两个顶点，因此只需要四个顶点坐标
    // 注意，未使用VBO时，glDrawElements的最后一个参数是指向对应索引数组的指针。
    // 但是，当使用VBO时，参数4表示索引数据在VBO（GL_ELEMENT_ARRAY_BUFFER）中的偏移量
    //glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    glDrawElements(GL_TRIANGLE_STRIP, sizeof(Indices)/sizeof(Indices[0]), GL_UNSIGNED_BYTE, (GLvoid *)1);
    glFlush();
     */
}

- (void)processImage:(UIImage *)image{
    
    [self processBuffer];
    
    if (_textureID) {
        glDeleteTextures(1, &_textureID);
        _textureID = 0;
    }
    
    CGImageRef cgImageRef = [image CGImage];
    GLuint width = (GLuint)CGImageGetWidth(cgImageRef);
    GLuint height = (GLuint)CGImageGetHeight(cgImageRef);
    CGRect rect = CGRectMake(0, 0, width, height);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    void *imageData = malloc(width * height * 4);
    CGContextRef context = CGBitmapContextCreate(imageData, width, height, 8, width * 4, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGContextTranslateCTM(context, 0, height);
    CGContextScaleCTM(context, 1.0f, -1.0f);
    CGColorSpaceRelease(colorSpace);
    CGContextClearRect(context, rect);
    CGContextDrawImage(context, rect, cgImageRef);
    
    glEnable(GL_TEXTURE_2D);
    glGenTextures(1, &_textureID);
    glBindTexture(GL_TEXTURE_2D, _textureID);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    // 线性过滤：使用距离当前渲染像素中心最近的4个纹理像素加权平均值
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    /**
     *  将图像数据传递给到GL_TEXTURE_2D中, 因其于textureID纹理对象已经绑定，所以即传递给了textureID纹理对象中。
     *  glTexImage2d会将图像数据从CPU内存通过PCIE上传到GPU内存。
     *  不使用PBO时它是一个阻塞CPU的函数，数据量大会卡。
     */
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData);
    
    // 结束后要做清理
    glBindTexture(GL_TEXTURE_2D, 0); //解绑
    CGContextRelease(context);
    free(imageData);

    glClearColor(0.5f, 0.5f, 0.5f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _textureID);
    glUniform1i(_textureSlot, 0);
    glUniform1i(_haveTexture, 1);

    [self renderUsingIndexVBO];
    
    glBindTexture(GL_TEXTURE_2D, 0);
    [_eaglContext presentRenderbuffer:GL_RENDERBUFFER];
}


- (void)renderUsingIndexVBO {
        
    glVertexAttribPointer(_textureCoordsSlot, 2, GL_FLOAT, GL_FALSE, 0, texCoords);
    glEnableVertexAttribArray(_textureCoordsSlot);
    
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, 0, textureVertices);
    glEnableVertexAttribArray(_positionSlot);
    
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(textureIndices), textureIndices, GL_STATIC_DRAW);
    glDrawElements(GL_TRIANGLE_STRIP, sizeof(textureIndices)/sizeof(textureIndices[0]), GL_UNSIGNED_BYTE, 0);
}


- (void)dealloc{
    
    [self destoryBuffer];

    if (vertexBuffer) glDeleteBuffers(1, &vertexBuffer);
    if (indexBuffer) glDeleteBuffers(1, &indexBuffer);
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end




@implementation GLEShaderOperations

+ (GLuint)compileShader:(NSString *)shaderName type:(GLenum)shaderType{
    
    NSString *shaderPath = [[NSBundle mainBundle] pathForResource:shaderName ofType:@"glsl"];
    NSError *error;
    NSString *shaderString = [NSString stringWithContentsOfFile:shaderPath encoding:NSUTF8StringEncoding error:&error];
    
    if (error || !shaderString) {
        
        NSLog(@"loading shader failed -> %@",[error localizedDescription]);
        return 0;
    }
    
    // 创建一个代表shader的OpenGL对象, 指定vertex或fragment shader
    GLuint shaderHandle = glCreateShader(shaderType);;
    
    // 获取shader的source
    const char *shaderStringUTF8 = [shaderString UTF8String];
    int shaderLength = (int)shaderString.length;
    glShaderSource(shaderHandle, 1, &shaderStringUTF8, &shaderLength);
    
    // 编译shader
    glCompileShader(shaderHandle);
    
    // 查询shader编译的状态
    GLint compileSuccess;
    glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &compileSuccess);
    if (compileSuccess == GL_FALSE) {
        
        GLchar messages[256];
        glGetShaderInfoLog(shaderHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"shader compile failed -> %@", messageString);
        return 0;
    }
    
    return shaderHandle;
}

+ (GLuint)compileVertexShader:(NSString *)shaderVertex shaderFragment:(NSString *)shaderFragment{
    
    // vertex和fragment两个shader都要编译
    GLuint vertexShader = [GLEShaderOperations compileShader:shaderVertex type:GL_VERTEX_SHADER];
    GLuint fragmentShader = [GLEShaderOperations compileShader:shaderFragment type:GL_FRAGMENT_SHADER];
    
    // 连接vertex和fragment shader成一个完整的program
    GLuint program = glCreateProgram();
    glAttachShader(program, vertexShader);
    glAttachShader(program, fragmentShader);
    glLinkProgram(program);
    
    // 查询链接frag和vertex shader的状态
    GLint linkSuccess;
    glGetProgramiv(program, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        
        GLchar messages[256];
        glGetProgramInfoLog(program, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"shader link failed -> %@", messageString);
        return 0;
    }
    
    return program;
}

@end
