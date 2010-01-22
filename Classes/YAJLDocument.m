//
//  YAJLDocument.m
//  YAJL
//
//  Created by Gabriel Handford on 3/1/09.
//  Copyright 2009. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//


#import "YAJLDocument.h"

@interface YAJLDocument (Private)
- (void)_pop;
- (void)_popKey;
@end

NSInteger YAJLDocumentStackCapacity = 20;

@implementation YAJLDocument

@synthesize root=root_;

- (id)init {
  return [self initWithParserOptions:0];
}

- (id)initWithParserOptions:(YAJLParserOptions)parserOptions {
	if ((self = [super init])) {
		stack_ = CFArrayCreateMutable(NULL, 10, &kCFTypeArrayCallBacks);
		keyStack_ = CFArrayCreateMutable(NULL, 3, &kCFTypeArrayCallBacks);
		status_ = YAJLParserStatusNone;
		parser_ = [[YAJLParser alloc] initWithParserOptions:parserOptions];
		parser_.delegate = self;
	}
	return self;
}

- (id)initWithData:(NSData *)data parserOptions:(YAJLParserOptions)parserOptions error:(NSError **)error {
	if ((self = [self initWithParserOptions:parserOptions])) {		
		[self parse:data error:error];
	}
	return self;
}

- (void)dealloc {
	CFRelease(stack_);
	CFRelease(keyStack_);
	parser_.delegate = nil;
	[parser_ release];	
	[root_ release];
	[super dealloc];
}

- (YAJLParserStatus)parse:(NSData *)data error:(NSError **)error {
	status_ = [parser_ parse:data];
	if (error) *error = [parser_ parserError];
	return status_;
}

#pragma mark Delegates

- (void)parser:(YAJLParser *)parser didAdd:(id)value {
	switch(currentType_) {
		case YAJLDecoderCurrentTypeArray:
			CFArrayAppendValue(array_, value);
			break;
		case YAJLDecoderCurrentTypeDict:
			NSParameterAssert(key_);
			CFDictionarySetValue(dict_, key_, value);
			[self _popKey];
			break;
	}	
}

- (void)parser:(YAJLParser *)parser didMapKey:(NSString *)key {
	key_ = key;
	CFArrayAppendValue(keyStack_, key); // Push
}

- (void)_popKey {
	key_ = nil;

	CFIndex count = CFArrayGetCount(keyStack_);

	if (count > 0)
	{
		CFArrayRemoveValueAtIndex(keyStack_, count-1);

		if (count > 1)
		{
			key_ = (id)CFArrayGetValueAtIndex(keyStack_, count-2);
		}
	}
}

- (void)parserDidStartDictionary:(YAJLParser *)parser {
	CFMutableDictionaryRef dict = CFDictionaryCreateMutable(NULL, 0, &kCFCopyStringDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
	if (!root_) root_ = [(id)dict retain];
	CFArrayAppendValue(stack_, dict); // Push
	dict_ = dict;
  CFRelease(dict);
	currentType_ = YAJLDecoderCurrentTypeDict;	
}

- (void)parserDidEndDictionary:(YAJLParser *)parser {
	CFIndex count = CFArrayGetCount(stack_);
	CFTypeRef value = CFArrayGetValueAtIndex(stack_, count-1);
	CFRetain(value);
	[self _pop];
	[self parser:parser didAdd:(id)value];
	CFRelease(value);
}

- (void)parserDidStartArray:(YAJLParser *)parser {
	CFMutableArrayRef array = CFArrayCreateMutable(NULL, 10, &kCFTypeArrayCallBacks);

	if (!root_) root_ = [(id)array retain];
	// Push
	CFArrayAppendValue(stack_, array);
	array_ = array;
	CFRelease(array);
	currentType_ = YAJLDecoderCurrentTypeArray;
}

- (void)parserDidEndArray:(YAJLParser *)parser {
	CFIndex count = CFArrayGetCount(stack_);
	CFTypeRef value = CFArrayGetValueAtIndex(stack_, count-1);
	CFRetain(value);
	[self _pop];	
	[self parser:parser didAdd:(id)value];
	CFRelease(value);
}

- (void)_pop {

	CFIndex count = CFArrayGetCount(stack_);
	if (count > 0)
	{
		CFArrayRemoveValueAtIndex(stack_, count-1);
		count--;
	}

	array_ = NULL;
	dict_ = NULL;

	currentType_ = YAJLDecoderCurrentTypeNone;

	CFTypeRef value = NULL;

	if (count > 0) value = CFArrayGetValueAtIndex(stack_, count-1);

	if (value)
	{
		CFTypeID type = CFGetTypeID(value);
		if (type == CFArrayGetTypeID()) {
			array_ = (CFMutableArrayRef)value;
		currentType_ = YAJLDecoderCurrentTypeArray;
		} else if (type == CFDictionaryGetTypeID()) {
			dict_ = (CFMutableDictionaryRef)value;
		currentType_ = YAJLDecoderCurrentTypeDict;
	}
}
}

@end
