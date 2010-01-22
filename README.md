# YAJL (Objective-C Wrapper)

YAJL.framework is an Objective-C wrapper around the [YAJL](http://lloyd.github.com/yajl/) SAX-style JSON parser.

## Download

### Mac OS X

[YAJL-0.2.14.zip](http://rel.me.s3.amazonaws.com/yajl/YAJL-0.2.14.zip) *YAJL.framework* (2009/12/11)

### iPhone

[libYAJLIPhone-0.2.14.zip](http://rel.me.s3.amazonaws.com/yajl/libYAJLIPhone-0.2.14.zip) *Static Library for iPhone OS 3.0 Simulator & Device* (2009/12/11)

The static library is a universal arm6/7 binary so while it is double the size of previous builds, it compresses down to nearly the same size as standalone builds.

## Install (Mac OS X)

There are two options. You can install it globally in /Library/Frameworks or with a little extra effort embed it with your project.

### Installing in /Library/Frameworks

- Copy `YAJL.framework` to `/Library/Frameworks/`
- In the target Info window, General tab:
	- Add a linked library, under `Mac OS X 10.5 SDK` section, select `YAJL.framework`

### Installing in your project

- Copy `YAJL.framework` to your project directory (maybe in MyProject/Frameworks/.)
- Add the `YAJL.framekwork` files (from MyProject/Frameworks/) to your target. It should be visible as a `Linked Framework` in the target. 
- Under Build Settings, add `@loader_path/../Frameworks` to `Runpath Search Paths` 
- Add `New Build Phase` | `New Copy Files Build Phase`. 
	- Change the Destination to `Frameworks`.
	- Drag `YAJL.framework` into the the build phase
	- Make sure the copy phase appears before any `Run Script` phases 

## Install (iPhone)

- Add files (from static library build) to project.
- Under 'Other Linker Flags' in the Test target, add `-ObjC` and `-all_load` (So NSObject+YAJL category is loaded).

## Usage

To parse JSON from an NSData (or NSString):

	#import "NSObject+YAJL.h"

	NSData *JSONData = [NSData dataWithContentsOfFile:@"example.json"];
	NSArray *arrayFromData = [JSONData yajl_JSON];
	
	NSString *JSONString = @"[\"Test\"]";
	NSArray *arrayFromString = [JSONString yajl_JSON];
	
	// With options and out error
	NSError *error = nil;
	NSArray *arrayFromString = [JSONString yajl_JSONWithOptions:YAJLParserOptionsAllowComments error:&error];

To generate JSON from an object:

	#import "NSObject+YAJL.h"
	
	NSDictionary *dict = [NSDictionary dictionaryWithObject:@"value" forKey:@"key"];
	NSString *JSONString = [dict yajl_JSONString];
	
	// Beautified with custon indent string
	NSArray *array = [NSArray arrayWithObjects:@"value1", @"value2", nil];
	NSString *JSONString = [dict yajl_JSONStringWithOptions:YAJLGenOptionsBeautify indentString:@"    "];

To use the streaming (or SAX style) parser, use `YAJLParser`.

	NSData *data = [NSData dataWithContentsOfFile:@"example.json"];

	YAJLParser *parser = [[YAJLParser alloc] initWithParserOptions:YAJLParserOptionsAllowComments];
	parser.delegate = self;
	[parser parse:data];
	if (parser.parserError) {
		NSLog(@"Error:\n%@", parser.parserError);
	}

	parser.delegate = nil;
	[parser release];
	
	// Include delegate methods from YAJLParserDelegate
	/*
	- (void)parserDidStartDictionary:(YAJLParser *)parser;
	- (void)parserDidEndDictionary:(YAJLParser *)parser;

	- (void)parserDidStartArray:(YAJLParser *)parser;
	- (void)parserDidEndArray:(YAJLParser *)parser;

	- (void)parser:(YAJLParser *)parser didMapKey:(NSString *)key;
	- (void)parser:(YAJLParser *)parser didAdd:(id)value;
	*/
	
### Streaming Example

	YAJLParser *parser = [[[YAJLParser alloc] initWithParserOptions:0] autorelease];
	parser.delegate = self;

	// A chunk of data comes...
	YAJLParserStatus status = [parser parse:chunk1];
	// 'status' should be YAJLParserStatusInsufficientData, if its not finished
	if (parser.parserError) ...;
	
	// Another chunk of data comes...
	YAJLParserStatus status = [parser parse:chunk2];
	// 'status' should be YAJLParserStatusOK if its finished
	if (parser.parserError) ...;

## Usage (Document-style)

To use the document style, use `YAJLDocument`. Usage should be very similar to `NSXMLDocument`.

	NSData *data = [NSData dataWithContentsOfFile:@"example.json"];
	NSError *error = nil;
	YAJLDocument *document = [[YAJLDocument alloc] initWithData:data parserOptions:0 error:&error];
	// Access root element at document.root
	NSLog(@"Root: %@", document.root);
	[document release];
	
Or stream to the document:
	
	YAJLDocument *document = [[YAJLDocument alloc] initWithWithParserOptions:YAJLParserOptionsNone];
	
	NSError *error = nil;
	[document parse:chunk1 error:error];
	[document parse:chunk2 error:error];

	// Access root element at document.root
	NSLog(@"Root: %@", document.root);
	[document release];

## Customized Encoding

To implement JSON encodable value for custom objects or override for existing objects, implement `- (id)JSON;`

For example:

	@interface CustomObject : NSObject
	@end

	@implementation CustomObject

	- (id)JSON {
	  return [NSArray arrayWithObject:[NSNumber numberWithInteger:1]];
	}

	@end
  
Then:

	CustomObject *customObject = [[CustomObject alloc] init];
	NSString *JSONString = [customObject yajl_JSON];
	// JSONString == "[1]";

