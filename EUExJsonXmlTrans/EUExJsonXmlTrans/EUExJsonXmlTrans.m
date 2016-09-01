//
//  EUExJsonXmlTrans.m
//  EUExJsonXmlTrans
//
//  Created by Cerino on 15/9/22.
//  Copyright © 2015年 AppCan. All rights reserved.
//

#import "EUExJsonXmlTrans.h"
#import <XMLDictionary/XMLDictionary.h>
#import "JSON.h"
#import "EUtility.h"

@interface EUExJsonXmlTrans()
@property (nonatomic,strong) NSArray * pathKeys;
@end


NSString * const uexJsonXmlTransErrorInvalidParam=@"请传入参数";
NSString * const uexJsonXmlTransErrorInvalidFilePath=@"未读取到文件内容，请检查文件路径";
NSString * const uexJsonXmlTransErrorParseJsonFailed=@"JSON 解析出错";
NSString * const uexJsonXmlTransErrorParseXmlFailed=@"XML 解析出错";

@implementation EUExJsonXmlTrans

/*

+ (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[XMLDictionaryParser sharedInstance]setTrimWhiteSpace:YES];
        //[[XMLDictionaryParser sharedInstance]setCollapseTextNodes:NO];
    });
    return YES;
}

*/
#pragma mark - Required Method

-(id)initWithWebViewEngine:(id<AppCanWebViewEngineObject>)engine{
    if (self = [super initWithWebViewEngine:engine]) {
        self.pathKeys=@[@"wgt://",@"res://",@"file://",@"wgts://"];
    }
    return self;
}

-(void)clean{
    
}
-(void)dealloc{
    [self clean];
}




#pragma mark - Main API

-(void)json2xml:(NSMutableArray *)inArguments{
    ACJSFunctionRef *func = JSFunctionArg(inArguments.lastObject);
    if([inArguments count] < 1||![inArguments[0] isKindOfClass:[NSString class]]){
        [self parseResultCallback:uexJsonXmlTransErrorInvalidParam];
        return;
    }
    //NSString *info = inArguments[0];
    ACArgsUnpack(NSString *info) = inArguments;
    NSData *jsonData = nil;
    BOOL isFilePath = NO;
    for(NSString * pathKey in self.pathKeys){
        if([info hasPrefix:pathKey]){
            isFilePath = YES;
        }
    }
    __block NSError *error = nil;
    if(isFilePath){
        jsonData=[NSData dataWithContentsOfFile:[self absPath:info]];
        if(!jsonData){
            [self parseResultCallback:uexJsonXmlTransErrorInvalidFilePath];
            [func executeWithArguments:ACArgsPack(@(1),uexJsonXmlTransErrorInvalidFilePath)];
            return;
        }
        

    }else{
        jsonData=[info dataUsingEncoding:NSUTF8StringEncoding];
    }
   
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSDictionary * dict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:&error];
        if(error){
            [self parseResultCallback:uexJsonXmlTransErrorParseJsonFailed];
            [func executeWithArguments:ACArgsPack(@(1),uexJsonXmlTransErrorParseJsonFailed)];
            return;
        }
        NSString *resultStr = [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"utf-8\"?>%@",[[dict innerXML] stringByReplacingOccurrencesOfString:@">\n<" withString:@"><"]];
        [self parseResultCallback:resultStr];
        [func executeWithArguments:ACArgsPack(@(0),resultStr)];
       
    });
   
    
    
    
}
-(void)xml2json:(NSMutableArray *)inArguments{
    ACJSFunctionRef *func = JSFunctionArg(inArguments.lastObject);
    if([inArguments count] < 1||![inArguments[0] isKindOfClass:[NSString class]]){
        [self parseResultCallback:uexJsonXmlTransErrorInvalidParam];
        [func executeWithArguments:ACArgsPack(@(1),uexJsonXmlTransErrorInvalidParam)];
        return;
    }
    //NSString *info = inArguments[0];
    ACArgsUnpack(NSString*info) = inArguments;
    NSString *xmlString = nil;
    BOOL isFilePath = NO;
    for(NSString * pathKey in self.pathKeys){
        if([info hasPrefix:pathKey]){
            isFilePath = YES;
        }
    }
    NSError *error =nil;
   
    if(isFilePath){
        NSString * tmp = [NSString stringWithContentsOfFile:[self absPath:info] encoding:NSUTF8StringEncoding error:&error];
        if(error){
            [self parseResultCallback:uexJsonXmlTransErrorInvalidFilePath];
            [func executeWithArguments:ACArgsPack(@(1),uexJsonXmlTransErrorInvalidFilePath)];
        }
        xmlString=[NSString stringWithFormat:@"<root>%@</root>",[[tmp componentsSeparatedByString:@"?>"] lastObject]];
    }else{
        
         xmlString=[NSString stringWithFormat:@"<root>%@</root>",[[info componentsSeparatedByString:@"?>"] lastObject]];

    }
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSMutableDictionary *dict = [[NSDictionary dictionaryWithXMLString:xmlString] mutableCopy];
        [dict removeObjectForKey:XMLDictionaryNodeNameKey];
        [self parseResultCallback:[dict ac_JSONFragment]];
        [func executeWithArguments:ACArgsPack(@(0),dict)];
         NSLog(@"currentThread:%@",[NSThread currentThread]);
    });
    
}
#pragma mark - JSON Callback


-(void)parseResultCallback:(NSString *)resultStr{

    [self.webViewEngine callbackWithFunctionKeyPath:@"uexJsonXmlTrans.cbTransFinished" arguments:ACArgsPack(resultStr)];
}
@end
