//
//  DTCoreTextLayoutFrame+Cursor.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 10.07.13.
//  Copyright (c) 2013 Drobnik.com. All rights reserved.
//

#import "DTCoreTextLayoutFrame+Cursor.h"
#import "DTCoreTextLayoutLine.h"

@implementation DTCoreTextLayoutFrame (Cursor)

- (NSInteger)closestCursorIndexToPoint:(CGPoint)point
{
	NSArray *lines = self.lines;
	
	if (![lines count])
	{
		return NSNotFound;
	}
	
	DTCoreTextLayoutLine *firstLine = [lines objectAtIndex:0];
	if (point.y < CGRectGetMinY(firstLine.frame))
	{
		return 0;
	}
	
	DTCoreTextLayoutLine *lastLine = [lines lastObject];
	if (point.y > CGRectGetMaxY(lastLine.frame))
	{
        NSRange stringRange = [self visibleStringRange];
        
        if (stringRange.length)
        {
            return NSMaxRange([self visibleStringRange])-1;
        }
	}
	
	// find closest line
	DTCoreTextLayoutLine *closestLine = nil;
	CGFloat closestDistance = CGFLOAT_MAX;
	
	for (DTCoreTextLayoutLine *oneLine in lines)
	{
		// line contains point
		if (CGRectGetMinY(oneLine.frame) <= point.y && CGRectGetMaxY(oneLine.frame) >= point.y)
		{
			closestLine = oneLine;
			break;
		}
		
		CGFloat top = CGRectGetMinY(oneLine.frame);
		CGFloat bottom = CGRectGetMaxY(oneLine.frame);
		
		CGFloat distance = CGFLOAT_MAX;
		
		if (top > point.y)
		{
			distance = top - point.y;
		}
		else if (bottom < point.y)
		{
			distance = point.y - bottom;
		}
		
		if (distance < closestDistance)
		{
			closestLine = oneLine;
			closestDistance = distance;
		}
	}
	
	if (!closestLine)
	{
		return NSNotFound;
	}
	
	NSInteger closestIndex = [closestLine stringIndexForPosition:point];
	
	NSInteger maxIndex = NSMaxRange([closestLine stringRange])-1;
	
	if (closestIndex > maxIndex)
	{
		closestIndex = maxIndex;
	}
	
	if (closestIndex>=0)
	{
		return closestIndex;
	}
	
	return NSNotFound;
}

- (CGRect)cursorRectAtIndex:(NSInteger)index
{
	DTCoreTextLayoutLine *line = [self lineContainingIndex:index];
	
	if (!line)
	{
		return CGRectZero;
	}
	
	CGFloat offset = [line offsetForStringIndex:index];
	
	CGRect rect = line.frame;
	rect.size.width = 3.0;
	rect.origin.x += offset;
	
	return rect;
}

- (NSRange)getRangeAtIndex:(NSInteger)index isWord:(BOOL)isWord {
    NSString *plainText = self.attributedStringFragment.string;
    NSStringEnumerationOptions options = isWord ? NSStringEnumerationByWords : NSStringEnumerationBySentences;
    __block NSRange range = NSMakeRange(0, 0);

    [plainText enumerateSubstringsInRange:NSMakeRange(0, plainText.length) options:options usingBlock:^(NSString * _Nullable substring, NSRange substringRange, NSRange enclosingRange, BOOL * _Nonnull stop) {
        if (NSLocationInRange(index, enclosingRange)) {
            range = substringRange;
            *stop = YES;
        }
    }];
    
    return range;
}

- (NSString *)getTextWithRange:(NSRange)range {
    NSString *plainText = self.attributedStringFragment.string;
    NSString *text = [plainText substringWithRange:range];
    return text;
}
/**
 手指移动过程中,所在文字的区域
 
 @param point 点击区域
 @return 文字index
 */
- (CFIndex)movePointToSelectIndex:(CGPoint)touchPoint {
	CFIndex index = kCFNotFound;
	
	for (DTCoreTextLayoutLine *line in self.lines) {
		if (CGRectContainsPoint(line.frame, touchPoint)){
			/// line的起始点
            CGPoint point = CGPointMake(touchPoint.x -line.frame.origin.x,0);
            index = [line stringIndexForPosition2:point];
		} else {
			if (touchPoint.x>line.frame.origin.x+line.frame.size.width && line.frame.origin.y > touchPoint.y && line.frame.origin.y - line.frame.size.height < touchPoint.y) {
				/// line终点
				CGPoint pointOffset = CGPointMake(line.frame.origin.x+line.frame.size.width,0);
                index = [line stringIndexForPosition2:pointOffset];
			} else if (touchPoint.x < line.frame.origin.x && line.frame.origin.y > touchPoint.y && line.frame.origin.y - line.frame.size.height < touchPoint.y ) {
				/// line 起点
				CGPoint pointOffset = CGPointMake(0,0);
                index = [line stringIndexForPosition2:pointOffset];
			}
		}
	}
	return index;
}

- (NSArray *)calculateSelectRectPathsWithRange:(NSRange)selectedRange {
    if (selectedRange.length == 0 || selectedRange.location == NSNotFound) {
        return nil;
    }
    
    NSMutableArray *pathRects = [[NSMutableArray alloc] init];
    for (DTCoreTextLayoutLine *line in self.lines) {
        NSRange rangeN = line.stringRange;
        NSRange intersection = GetIntersectionToRange(rangeN, selectedRange);
        if (intersection.length > 0) {
            ///相对line的原点的x值
            CGFloat xStart = [line offsetForStringIndex:intersection.location];
            CGFloat xEnd = [line offsetForStringIndex:intersection.location + intersection.length];
                
            CGRect selectionRect = CGRectMake(line.frame.origin.x + xStart, line.frame.origin.y, xEnd - xStart, line.frame.size.height);
            [pathRects addObject:NSStringFromCGRect(selectionRect)];
        }
    }
    return pathRects;
}

static inline NSRange GetIntersectionToRange(NSRange range1, NSRange range2) {
    NSRange result = NSMakeRange(NSNotFound, 0);
    if (range1.location > range2.location)
    {
        NSRange tmp = range1;
        range1 = range2;
        range2 = tmp;
    }
    if (range2.location < range1.location + range1.length)
    {
        result.location = range2.location;
        NSUInteger end = MIN(range1.location + range1.length, range2.location + range2.length);
        result.length = end - result.location;
    }
    return result;
}

@end
