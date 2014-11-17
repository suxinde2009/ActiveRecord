//
//  ActiveRecordBase.m
//  ActiveRecord
//
//  Created by kenny on 5/17/14.
//  Copyright (c) 2014 webuser. All rights reserved.
//

#import "ActiveRecordBase.h"
#import <sqlite3.h>
sqlite3 *_sql3;
@interface ActiveRecordBase (){
    NSMutableArray *_wheres;
    NSInteger _page;
    NSInteger _perPage;
}
@end

@implementation ActiveRecordBase

- (NSInteger) uniqueId{
    return [self.attributes[@"id"] intValue];
}

+ (BOOL) runSql:(NSString *)sql{
    NSLog(@"\nsqlite: %@", sql);
    NSAssert(_sql3 != nil, @"创建连接失败");
    char *errmsg;
    if (sqlite3_exec(_sql3, [sql UTF8String], NULL, NULL, &errmsg) == SQLITE_OK) {
        return YES;
    }else{
        NSLog(@"sql error:%s",errmsg);
        sqlite3_free(errmsg);
        return NO;
    }
}

+ (NSArray *) getList:(NSString *)sql{
    NSAssert(_sql3 != nil, @"创建连接失败");
    NSMutableArray *array = [NSMutableArray array];
	sqlite3_stmt *statement;
	if (sqlite3_prepare(_sql3, [sql UTF8String], -1, &statement, nil) == SQLITE_OK) {
        NSLog(@"\nsqlite: %@", sql);
        //one line
		while (sqlite3_step(statement) == SQLITE_ROW) {
            int count = sqlite3_column_count(statement);
            //data in one line
            NSMutableDictionary *dic = [NSMutableDictionary dictionary];
            for (int i = 0; i < count; i++) {
                const char *name = sqlite3_column_name(statement, i);
                NSString *value = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, i)];
                [dic setObject:value forKey:[NSString stringWithFormat:@"%s",name]];
            }
            [array addObject:dic];
        }
    }else{
        NSLog(@"wrong sql:%@",sql);
    }
    return array;
}


+ (void) connect{
    NSString *name = @"ar.sqlite";
    NSString *documentPath = [NSString stringWithFormat:@"%@/Documents/%@",NSHomeDirectory(),name];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:documentPath]) {//没在document下面copy过来
        NSString *bundlePath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:name];
        NSError *err;
        BOOL i = [fileManager copyItemAtPath:bundlePath toPath:documentPath error:&err];
        NSLog(@"document下面没有, copy过来%d",i);
        NSLog(@"copy的时候错误信息%@",err);
    }
//    documentPath =  [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:name];
    //此时document下面肯定有了
    NSLog(@"建立链接的sql文件是%@", documentPath);
    if (sqlite3_open([documentPath UTF8String], &_sql3) != SQLITE_OK) {
        sqlite3_close(_sql3);
    }else{
        NSLog(@"建立链接成功");
    }
    
}

+ (void) disConnect{
    sqlite3_close(_sql3);
}

+(NSInteger) lastInsertId{
    NSAssert(_sql3 != nil, @"创建连接失败");
    return (NSInteger)sqlite3_last_insert_rowid(_sql3);
}

+(NSString *) tableName{
    return [self tableName:self];
}

+ (NSString *) tableName: (Class) klass{
    NSString *modelName = [klass description];
    NSMutableArray *underArr = [NSMutableArray array];
    for (int i =0; i < [modelName length]; i++) {
        //把大写字母弄成_a这种
        const char *c = [[modelName substringWithRange:NSMakeRange(i, 1)] UTF8String];
        if (i == 0) {
            [underArr addObject:[NSString stringWithFormat:@"%c", (*c+32)]];
        }else if (*c < 'a') {//a是97, A是65所以这么比就知道大小写了
            //大写
            [underArr addObject:[NSString stringWithFormat:@"_%c", (*c+32)]];
        }else{
            [underArr addObject:[NSString stringWithUTF8String:c]];
        }
    }
    NSString *tableName = [underArr componentsJoinedByString:@""];
    return [NSString stringWithFormat:@"%@s", tableName];
}

- (instancetype) init{
    if (self = [super init]) {
        NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
        for (NSString *field in self.fields) {
            attrs[field] = @"";
        }
        _attributes = attrs;
        _changed_attributes = [NSMutableDictionary dictionary];
        _wheres = [NSMutableArray array];
        _page = 0;
        _perPage = -1;
    }
    
    return self;
}

- (instancetype) initWithAttributes:(NSDictionary *)attributes{
    if (self = [super init]) {
        _attributes = attributes;
        _changed_attributes = [NSMutableDictionary dictionary];
        _wheres = [NSMutableArray array];
        _page = 0;
        _perPage = -1;
    }
    return self;
}

- (NSString *) attribute:(NSString *)attribute{
    return [self.attributes valueForKey:attribute];
}
//修改了属性, 更新到数据库, 会把changes清0
- (BOOL) save{
    NSString *sql = @"";
    if (![self isNewRecord]) {//update
        NSMutableArray *change_strs = [NSMutableArray array];
        for (NSString *key in self.changed_attributes){
            [change_strs addObject:[NSString stringWithFormat:@"%@ = '%@'", key, self.changed_attributes[key]]];
        }
        sql  = [NSString stringWithFormat:@"UPDATE %@ SET %@ WHERE id = %d;",
                [self.class tableName],
                [change_strs componentsJoinedByString:@","],
                [self uniqueId]
                ];
    }else{//insert
        sql  = [NSString stringWithFormat:@"INSERT INTO %@ ('%@') VALUES ('%@');",
                         [self.class tableName],
                         [[self.changed_attributes allKeys] componentsJoinedByString:@"','"],
                         [[self.changed_attributes allValues] componentsJoinedByString:@"','"]
                         ];
    }
    if ([[self class] runSql:sql]) {
        [self reset];
        return YES;
    }else
        return NO;
}

- (void) reset{
    _changed_attributes = [NSMutableDictionary dictionary];
    _wheres = [NSMutableArray array];
    _page = 0;
    _perPage = -1;
    if (![self isNewRecord]) {
        _attributes = [(ActiveRecordBase *)[self.class find:self.uniqueId] attributes];
    }else{
        _attributes =[(ActiveRecordBase *)[self.class find:[self.class lastInsertId]] attributes];
    }
}

- (BOOL) isNewRecord{
    return self.uniqueId == 0;
}

#pragma mark 增
+ (instancetype) create:(NSDictionary *)attributes{
    id model = [[[self class] alloc] init];
    for (NSString *key in attributes){
        [model changed_attributes][key] = attributes[key];
    }
    [model save];
    return model;
}

#pragma mark删
- (void) destory{
    NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE id = %ld;", [self.class tableName], (long)self.uniqueId];
    [self.class runSql: sql];
}
#pragma mark查
+(instancetype) find:(NSInteger)_id{
    NSArray *models = [[self where:@{@"id":[NSString stringWithFormat:@"%ld",(long)_id]}] result];
    return [models objectAtIndex:0];
}

+ (instancetype)where:(id)conditions{
    id entity = [[self alloc] init];
    return [entity where:conditions];
}

+(NSArray *) all{
    return [[self where:nil] result];
}

- (instancetype) where:(id)conditions{
    
    if ([conditions isKindOfClass:NSString.class]) {
        [_wheres addObject:conditions];
    }else if([conditions isKindOfClass:NSDictionary.class]){
        for (NSString *key in conditions){
            id value = conditions[key];
            if ([value isKindOfClass:NSArray.class]) {
                //要in
            }else{
                //直接=
                [_wheres addObject:[NSString stringWithFormat:@"%@ = %@", key, value]];
            }
        }
    }
    return self;
}

- (NSArray *) result{
    NSString *whereStr = @"";
    if ([_wheres count] > 0) {
        whereStr = [NSString stringWithFormat:@" WHERE %@",[_wheres componentsJoinedByString:@" AND "]];
    }
    NSString *limitStr = @"";
    if (_perPage > 0) {
        limitStr = [NSString stringWithFormat:@"Limit %ld,%ld",
                    (long)_page * _perPage, (long)_perPage
                    ];
    }
    NSArray *list = [self.class getList:[NSString stringWithFormat:@"select * from %@ %@ %@;", [self.class tableName], whereStr, limitStr]];
    NSMutableArray *result = [NSMutableArray array];
    for (NSDictionary *attrs in list){
        id model = [[self.class alloc] initWithAttributes:attrs];
        [result addObject:model];
    }
    return result;
}

+ (instancetype) perPage:(NSInteger)perPage{
    return [[[self alloc] init] perPage:perPage];
}

- (instancetype) page: (NSInteger) page{
    _page = page;
    return self;
}

- (id) perPage: (NSInteger) perPage{
    _perPage = perPage;
    return self;
}

#pragma mark --改--
- (void) updateAttribute:(NSString *)field toValue:(id)value{
    [self.changed_attributes setValue:value forKey:field];
    [self save];
}

- (void) updateAttributes:(NSDictionary *)attributes{
    for (NSString *field in attributes){
        [self.changed_attributes setValue:[attributes valueForKey:field] forKey:field];
    }
    [self save];
}
@end
