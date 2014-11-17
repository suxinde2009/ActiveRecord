//
//  ActiveRecordBase.h
//  ActiveRecord
//
//  Created by kenny on 5/17/14.
//  Copyright (c) 2014 webuser. All rights reserved.
//

#import <Foundation/Foundation.h>
@interface ActiveRecordBase : NSObject
@property (readonly) NSArray *fields;
@property (readonly) NSDictionary *attributes;
@property (readonly) NSMutableDictionary *changed_attributes;
@property(readonly) NSInteger uniqueId;
//创建连接和关闭连接
+ (void) connect;
+ (void) disConnect;
//基础方法
- (instancetype) initWithAttributes:(NSDictionary *)attributes;//就是ac的build
+ (BOOL) runSql:(NSString *)sql;
+ (NSArray *) getList:(NSString *)sql;
+ (NSInteger)lastInsertId;
+ (NSString *) tableName;
+ (NSString *) tableName: (Class) klass;

//设置某一个字段的值,类似deal.title=
- (NSString *) attribute:(NSString *)attribute;
- (BOOL) save;
//把changes, attributes全部清空, 就像刚刚find一样, 如果是newrecord那么就认为是刚insert
- (void) reset;
- (BOOL) isNewRecord;
//增
+ (instancetype) create :(NSDictionary *)attributes;
//删
- (void) destory;
//查
+ (instancetype)find:(NSInteger) _id;
+ (instancetype)where: (id)conditions;
+ (NSArray *)all;
- (instancetype) where: (id)conditions;
- (NSArray *) result;
+ (instancetype) perPage: (NSInteger) perPage;
- (instancetype) page: (NSInteger) page;
- (id) perPage: (NSInteger) perPage;
//改
- (void) updateAttribute:(NSString *)field toValue:(id) value;
- (void) updateAttributes: (NSDictionary *) attributes;
@end
