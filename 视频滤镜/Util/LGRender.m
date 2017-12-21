//
//  LGRender.m
//  VideoBlend
//
//  Created by L了个G on 2017/12/20.
//  Copyright © 2017年 L了个G. All rights reserved.
//

#import "LGRender.h"
#import <GLKit/GLKit.h>
static const GLfloat quadVertexData1 [] = {
    -1.0, 1.0,
    1.0, 1.0,
    -1.0, -1.0,
    1.0, -1.0,
};

static const GLfloat quadTextureData1 [] = {
    0.0, 1.0,
    1.0, 1.0,
    0.0, 0.0,
    1.0,0.0,
};
enum
{
    UNIFORM_SIMPLER,
    UNIFORM_SIMPLER2,
    UNIFORM_SIMPLER3,
    UNIFORM_ALPHA,
    UNIFORM_ROTATION_ANGLE,//旋转矩阵
    UNIFORM_COLOR_CONVERSION_MATRIX,// 色彩转换矩阵
    UNIFORM_TYPE,
    UNIFORM_INTENSITY,
    NUM_UNIFORMS
};
GLint filetUnforms[NUM_UNIFORMS];

enum
{
    ATTRIB_VERTEX,
    ATTRIB_TEXCOORD,
    NUM_ATTRIBURTES
};
@interface LGRender()
@property CGAffineTransform renderTransform;
@property CVOpenGLESTextureCacheRef videoTextureCache;
@property EAGLContext *currentContext;
@property GLuint offscreenBufferHandle;
@property GLuint program;
@property GLuint lookUpTexure;
@property BOOL isFirst;
@end

@implementation LGRender
+ (instancetype)sharedRender {
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
        
    });
    return instance;
}

-(instancetype)init
{
    self = [super init];
    if (self) {
        _currentContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        [EAGLContext setCurrentContext:_currentContext];
        [self setupOffscreenRenderContext];
        NSURL *vertexURL = [[NSBundle mainBundle] URLForResource:@"FilterVertex" withExtension:@"glsl"];
        NSURL *fragURL = [[NSBundle mainBundle] URLForResource:@"FilterFrag" withExtension:@"glsl"];
        [self loadVertexShader:vertexURL AndFragShader:fragURL];
        self.isFirst = YES;
    }
    
    return self;
}

- (void)setupOffscreenRenderContext
{
    //-- Create CVOpenGLESTextureCacheRef for optimal CVPixelBufferRef to GLES texture conversion.
    if (_videoTextureCache) {
        CFRelease(_videoTextureCache);
        _videoTextureCache = NULL;
    }
    CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, _currentContext, NULL, &_videoTextureCache);
    if (err != noErr) {
        NSLog(@"Filter Error at CVOpenGLESTextureCacheCreate %d", err);
    }
    
    glDisable(GL_DEPTH_TEST);
    
    glGenFramebuffers(1, &_offscreenBufferHandle);
    glBindFramebuffer(GL_FRAMEBUFFER, _offscreenBufferHandle);
}
-(BOOL)loadVertexShader:(NSURL *)vertexURL AndFragShader:(NSURL *)fragURL{
    GLuint vertShader,fragShader;
    _program = glCreateProgram();
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER URL:vertexURL]) {
        NSLog(@"Filter Failed to compile vertex shader");
        return NO;
    }
    
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER URL:fragURL]) {
        NSLog(@"Filter Failed to compile frag shader");
        return NO;
    }
    
    glAttachShader(_program, vertShader);
    
    glAttachShader(_program, fragShader);
    
    glBindAttribLocation(_program, ATTRIB_VERTEX, "position");
    glBindAttribLocation(_program, ATTRIB_TEXCOORD, "texCoord");
    
    if (![self linkProgram:_program]) {
        NSLog(@"Filter Faided to link program:%d",_program);
        
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (_program) {
            glDeleteProgram(_program);
            _program = 0;
        }
        
        return NO;
    }
    
    filetUnforms[UNIFORM_SIMPLER] = glGetUniformLocation(_program, "Sampler");
    filetUnforms[UNIFORM_SIMPLER2] = glGetUniformLocation(_program, "Sampler2");
    filetUnforms[UNIFORM_SIMPLER3] = glGetUniformLocation(_program, "Sampler3");
    filetUnforms[UNIFORM_ROTATION_ANGLE] = glGetUniformLocation(_program, "preferredRotation");
    filetUnforms[UNIFORM_COLOR_CONVERSION_MATRIX] = glGetUniformLocation(_program, "colorConversionMatrix");
    filetUnforms[UNIFORM_TYPE] = glGetUniformLocation(_program, "type");
    filetUnforms[UNIFORM_ALPHA] = glGetUniformLocation(_program, "alpha");
    filetUnforms[UNIFORM_INTENSITY] = glGetUniformLocation(_program, "intensity");
    // Release vertex and fragment shaders.
    if (vertShader) {
        glDetachShader(_program, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader) {
        glDetachShader(_program, fragShader);
        glDeleteShader(fragShader);
    }
    
    return YES;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type URL:(NSURL *)URL
{
    NSError *error;
    NSString *sourceString = [NSString stringWithContentsOfURL:URL encoding:NSUTF8StringEncoding error:&error];
    if (sourceString == nil) {
        NSLog(@"Filter Failed to load shader : %@",[error localizedDescription]);
        return NO;
    }
    GLint status;
    const GLchar *source;
    source = (GLchar *)[sourceString UTF8String];
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Filter Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return NO;
    }
    
    return YES;
}


- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Filter Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

-(void)renderPixelBuffer:(CVPixelBufferRef)destinationPixelBuffer usingSourceBuffer:(CVPixelBufferRef)sourcePixelBuffer type:(FilterType)type
{
    NSLog(@"filter %lu",(unsigned long)type);
    [EAGLContext setCurrentContext:self.currentContext];
    NSLog(@"filter %d",self.lookUpTexure);
    if (sourcePixelBuffer) {
        CVOpenGLESTextureRef foregroundTexture = [self sourceTextureForPixelBuffer:sourcePixelBuffer];
        CVOpenGLESTextureRef destTexture       = [self sourceTextureForPixelBuffer:destinationPixelBuffer];
         glViewport(0, 0, (GLsizei)CVPixelBufferGetWidth(destinationPixelBuffer), (GLsizei)CVPixelBufferGetHeight(destinationPixelBuffer));
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(CVOpenGLESTextureGetTarget(foregroundTexture), CVOpenGLESTextureGetName(foregroundTexture));
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, CVOpenGLESTextureGetTarget(destTexture), CVOpenGLESTextureGetName(destTexture), 0);
        if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
            NSLog(@"Filter Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
        }
        
        glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT);
        glUseProgram(_program);
        
        if (type == FilterTypeOldSchool) {
        }else if (type == FilterTypeBlackWhite && self.isFirst)
        {
            [self setuplookUpTexture:@"lookup_黑白.png" type:1 ];
            glUniform1i(filetUnforms[UNIFORM_SIMPLER2], 1);
            
        }else if (type == FilterTypeRomance  && self.isFirst)
        {
            
            [self setuplookUpTexture:@"lookup_amatorka.png" type:1];
            glUniform1i(filetUnforms[UNIFORM_SIMPLER2], 1);
        }else if (type == FilterTypeRio && self.isFirst){
            [self setuplookUpTexture:@"color.png"type:1] ;
            glUniform1i(filetUnforms[UNIFORM_SIMPLER2], 1);
        }else if (type == FilterTypeCheEnShang && self.isFirst){
            [self setuplookUpTexture:@"color2.png" type:1];
            glUniform1i(filetUnforms[UNIFORM_SIMPLER2], 1);
        }else if (type == FilterTypeAutumn && self.isFirst){
            [self setuplookUpTexture:@"color1" type:1];
            glUniform1i(filetUnforms[UNIFORM_SIMPLER2], 1);
            [self setuplookUpTexture:@"color2" type:2];
            glUniform1i(filetUnforms[UNIFORM_SIMPLER3], 2);
        }
        glUniform1i(filetUnforms[UNIFORM_SIMPLER], 0);
        glUniform1i(filetUnforms[UNIFORM_TYPE], (int)type);
        glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, 0, 0, quadVertexData1);
        glEnableVertexAttribArray(ATTRIB_VERTEX);
        glVertexAttribPointer(ATTRIB_TEXCOORD, 2, GL_FLOAT, 0, 0, quadTextureData1);
        glEnableVertexAttribArray(ATTRIB_TEXCOORD);
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        glFlush();
    bail:
        if (foregroundTexture) {
            CFRelease(foregroundTexture);
        }
        CFRelease(destTexture);
        // Periodic texture cache flush every frame
        CVOpenGLESTextureCacheFlush(self.videoTextureCache, 0);
        //glDeleteTextures(1, &_lookUpTexure);
        [EAGLContext setCurrentContext:nil];
        
    }
    
}

- (GLuint)setuplookUpTexture:(NSString *)fileName type:(int)type {
    self.isFirst = NO;
    // 1获取图片的CGImageRef
    CGImageRef spriteImage = [UIImage imageNamed:fileName].CGImage
    ;
    if (!spriteImage) {
        NSLog(@"Failed to load image %@", fileName);
        exit(1);
    }
    
    // 2 读取图片的大小
    size_t width = CGImageGetWidth(spriteImage);
    size_t height = CGImageGetHeight(spriteImage);
    
    GLubyte * spriteData = (GLubyte *) calloc(width * height * 4, sizeof(GLubyte)); //rgba共4个byte
    
    CGContextRef spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width*4,
                                                       CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);
    
    // 3在CGContextRef上绘图
    CGContextDrawImage(spriteContext, CGRectMake(0, 0, width, height), spriteImage);
    
    CGContextRelease(spriteContext);
    
    GLuint texture;
    if (type == 1) {
        glActiveTexture(GL_TEXTURE1);
    } else {
        glActiveTexture(GL_TEXTURE2);
    }
    
    glEnable(GL_TEXTURE_2D);
    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture);
    
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    float fw = width, fh = height;
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, fw, fh, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
    
    free(spriteData);
    return 0;
}
-(CVOpenGLESTextureRef)sourceTextureForPixelBuffer:(CVPixelBufferRef)pixelBuffer
{
    CVOpenGLESTextureRef sourceTexture = NULL;
    CVReturn err;
    if (!_videoTextureCache) {
        NSLog(@" Filter No video texture cache");
        goto bail;
    }
    
    CVOpenGLESTextureCacheFlush(_videoTextureCache, 0);
    
    err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, _videoTextureCache, pixelBuffer, NULL, GL_TEXTURE_2D, GL_RGBA, (int)CVPixelBufferGetWidth(pixelBuffer), (int)CVPixelBufferGetHeight(pixelBuffer), GL_RGBA, GL_UNSIGNED_BYTE, 0, &sourceTexture);
    if (err) {
        NSLog(@"Filter Error at creating luma texture using CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
    }
bail:
    return sourceTexture;
}

- (void)dealloc
{
    NSLog(@"render dealloc ========================================");
    if (_videoTextureCache) {
        CFRelease(_videoTextureCache);
    }
    if (_offscreenBufferHandle) {
        glDeleteFramebuffers(1, &_offscreenBufferHandle);
        _offscreenBufferHandle = 0;
    }
}

@end
