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

-(instancetype)initWithBrwView:(EBrowserView *)eInBrwView{
    self=[super initWithBrwView:eInBrwView];
    if(self){
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
    if([inArguments count] < 1||![inArguments[0] isKindOfClass:[NSString class]]){
        [self parseResultCallback:uexJsonXmlTransErrorInvalidParam];
        return;
    }
    NSString *info = inArguments[0];
    NSData *jsonData = nil;
    BOOL isFilePath = NO;
    for(NSString * pathKey in self.pathKeys){
        if([info hasPrefix:pathKey]){
            isFilePath = YES;
        }
    }
    NSError *error = nil;
    if(isFilePath){
        jsonData=[NSData dataWithContentsOfFile:[self absPath:info]];
        if(!jsonData){
            [self parseResultCallback:uexJsonXmlTransErrorInvalidFilePath];
            return;
        }
        

    }else{
        jsonData=[info dataUsingEncoding:NSUTF8StringEncoding];
    }

    NSDictionary * dict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:&error];
    
    //NSDictionary *dict =
    if(error){
        [self parseResultCallback:uexJsonXmlTransErrorParseJsonFailed];
        return;
    }
    
    [self parseResultCallback:[NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"utf-8\"?>%@",[[dict innerXML] stringByReplacingOccurrencesOfString:@">\n<" withString:@"><"]]];
}
-(void)xml2json:(NSMutableArray *)inArguments{
    if([inArguments count] < 1||![inArguments[0] isKindOfClass:[NSString class]]){
        [self parseResultCallback:uexJsonXmlTransErrorInvalidParam];
        return;
    }
    NSString *info = inArguments[0];
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
        }
        xmlString=[NSString stringWithFormat:@"<root>%@</root>",[[tmp componentsSeparatedByString:@"?>"] lastObject]];
    }else{
        
         xmlString=[NSString stringWithFormat:@"<root>%@</root>",[[info componentsSeparatedByString:@"?>"] lastObject]];

    }
    //xmlString=[xmlString stringByReplacingOccurrencesOfString:@">\n<" withString:@"><"];
    NSMutableDictionary *dict = [[NSDictionary dictionaryWithXMLString:xmlString] mutableCopy];
    [dict removeObjectForKey:XMLDictionaryNodeNameKey];
        /*
        xmlData=[NSData dataWithContentsOfFile:[self absPath:info]];
        if(!xmlData){
            [self parseResultCallback:uexJsonXmlTransErrorInvalidFilePath];
            return;
        }
    }else{
        xmlData=[info dataUsingEncoding:NSUTF8StringEncoding];
    }
    NSDictionary *dict = [NSDictionary dictionaryWithXMLData:xmlData];
    if(!dict){
        [self parseResultCallback:uexJsonXmlTransErrorParseXmlFailed];
        return;
    }
         */
    [self parseResultCallback:[dict JSONFragment]];

}
#pragma mark - JSON Callback


-(void)parseResultCallback:(NSString *)resultStr{
    static NSString * pluginName = @"uexJsonXmlTrans";
    static NSString * name = @"cbTransFinished";
    NSString *jsStr = [NSString stringWithFormat:@"if(%@.%@ != null){%@.%@('%@');}",pluginName,name,pluginName,name,resultStr];
  
    NSLog(jsStr);
    [EUtility brwView:meBrwView evaluateScript:jsStr];
}
@end
