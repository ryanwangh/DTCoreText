//
//  DTAttributedLabel+Selection.m
//  DTCoreText (Mac)
//
//  Created by Ryan on 2025/2/17.
//  Copyright © 2025 Drobnik.com. All rights reserved.
//

#import "DTAttributedLabel+Selection.h"
#import <objc/runtime.h>

@implementation DTAttributedTextContentView (Selection)

- (NSRange)selectedRange {
    NSString *obj = objc_getAssociatedObject(self, _cmd);
    return NSRangeFromString(obj);
}

- (void)setSelectedRange:(NSRange)selectedRange {
    objc_setAssociatedObject(self, @selector(selectedRange), NSStringFromRange(selectedRange), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSArray *)wordRectAtPoint:(CGPoint)point {
    CGPoint pointInContentView = [self convertPoint:point fromView:self];
    NSInteger index = [self closestCursorIndexToPoint:pointInContentView];
    
    NSRange range = [self.layoutFrame getRangeAtIndex:index isWord:YES];
    self.selectedRange = range;
    
    NSArray *rects = [self.layoutFrame calculateSelectRectPathsWithRange:range];
    return rects;
}

- (NSArray *)sentenceRectAtPoint:(CGPoint)point {
    CGPoint pointInContentView = [self convertPoint:point fromView:self];
    NSInteger index = [self closestCursorIndexToPoint:pointInContentView];
    
    NSRange range = [self.layoutFrame getRangeAtIndex:index isWord:NO];
    self.selectedRange = range;
    
    NSArray *rects = [self.layoutFrame calculateSelectRectPathsWithRange:range];
	return rects;
}

- (void)showSelectionView:(CGPoint)point showCursor:(BOOL)isShowCursor isWord:(BOOL)isWord {
    if (self.selectionView.superview) {
        [self hideSelectionView];
        return;
    }
    
    NSArray *selectionRects = @[];
    if (isWord) {
        selectionRects = [self wordRectAtPoint: point];
    } else {
        selectionRects = [self sentenceRectAtPoint: point];
    }
    
    if (self.selectionView.superview == nil && selectionRects.count) {
        [self addSubview:self.selectionView];
        self.selectionView.frame = self.bounds;
    }
    
    self.selectionView.selectionRects = selectionRects;
}

- (void)showSelectionViewWithCursor {
    NSArray *selectionRects = [self.layoutFrame calculateSelectRectPathsWithRange:self.selectedRange];

    if (self.selectionView.superview == nil && selectionRects.count) {
        [self addSubview:self.selectionView];
        self.selectionView.frame = self.bounds;
    }
    
    self.selectionView.selectionRects = selectionRects;
}

- (void)hideSelectionView {    
    self.selectedRange = NSMakeRange(0, 0);
    
    self.selectionView.selectionRects = @[];
    self.selectionView.cursorState = 0;
    [self.selectionView removeFromSuperview];
}

- (NSString *)getSelectedText {
    return [self.layoutFrame getTextWithRange:self.selectedRange];
}

- (CGRect)getSelectionRect {
    return [self.selectionView getSelectionRect];
}

- (BOOL)cursorCanScroll {
    return self.selectionView.superview != nil;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = touches.anyObject;
    CGPoint point = [touch locationInView:self];
    
    if ([self cursorCanScroll]) {
        if ([self.selectionView canCursorMove:point isLeft:YES]) {
            self.selectionView.cursorState = 1;
        } else if ([self.selectionView canCursorMove:point isLeft:NO]) {
            self.selectionView.cursorState = 2;
        } else {
            self.selectionView.cursorState = 0;
        }
    } else {
        [super touchesBegan:touches withEvent:event];
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = touches.anyObject;
    CGPoint point = [touch locationInView:self];
    
    if ([self cursorCanScroll]) {
        CGPoint pointInContentView = [self convertPoint:point fromView:self];
        NSInteger index = [self.layoutFrame movePointToSelectIndex:pointInContentView];
        if (index == kCFNotFound) {
            return;
        }
		
        BOOL isMoveCursor = NO;
        if (self.selectionView.cursorState == 1 && index < self.selectedRange.length + self.selectedRange.location) {
            self.selectedRange = NSMakeRange(index, self.selectedRange.location - index + self.selectedRange.length);
            isMoveCursor = YES;
        } else if (self.selectionView.cursorState == 2 && index > self.selectedRange.location ) {
            self.selectedRange = NSMakeRange(self.selectedRange.location, index - self.selectedRange.location);
            isMoveCursor = YES;
        } else {
            isMoveCursor = NO;
        }
        
        if (isMoveCursor) {
            [self showSelectionViewWithCursor];
        }
    } else {
        [super touchesMoved:touches withEvent:event];
    }
}

- (DTSelectionView *)selectionView {
    DTSelectionView *obj = objc_getAssociatedObject(self, _cmd);
    if (obj == NULL) {
        obj = [DTSelectionView new];
        objc_setAssociatedObject(self, _cmd, obj, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return obj;
}

@end


@interface DTSelectionCursor: UIView

@property (nonatomic, strong) UIView *caret;
@property (nonatomic, strong) UIView *dot;

@property (nonatomic, assign) BOOL isLeft;

@end

@implementation DTSelectionCursor

- (instancetype)initWithFrame:(CGRect)frame isLeft:(BOOL)isLeft {
    frame = CGRectMake(0, 0, 2, 26);
    if (self = [super initWithFrame:frame]) {
        self.clipsToBounds = NO;
        
        [self addSubview:self.caret];
        [self addSubview:self.dot];
        
        self.isLeft = isLeft;
    }
    return self;
}

- (void)setIsLeft:(BOOL)isLeft {
    _isLeft = isLeft;
    
    [self setNeedsLayout];
}

- (CGRect)touchRect {
    CGRect rect = CGRectInset(self.frame, -20, -20);
    CGFloat left = self.isLeft ? -16 : 0;
    CGFloat right = self.isLeft ? 0 : -16;
    UIEdgeInsets insets = UIEdgeInsetsMake(0, left, 0, right);
    return UIEdgeInsetsInsetRect(rect, insets);
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat cursorHeight = CGRectGetHeight(self.bounds);
    self.caret.frame = CGRectMake(-2, 0, 2, cursorHeight);
    
    CGFloat dotY = self.isLeft ? -11 : cursorHeight;
    self.dot.frame = CGRectMake(0, dotY, 11, 11);
    self.dot.center = CGPointMake(self.caret.center.x, self.dot.center.y);
}

- (UIView *)caret {
    if (!_caret) {
        _caret = [UIView new];
        _caret.backgroundColor = DTColorCreateWithHexString(@"1B88EE");
    }
    return _caret;
}

- (UIView *)dot {
    if (!_dot) {
        _dot = [UIView new];
        _dot.backgroundColor = DTColorCreateWithHexString(@"1B88EE");
        _dot.layer.cornerRadius = 11.0 / 2.0;
        _dot.layer.masksToBounds = YES;
    }
    return _dot;
}

@end

@interface DTSelectionRectView: UIView

@property (nonatomic, strong) DTColor * selectionColor;
@property (nonatomic, strong) NSArray *selectionRects;

@end

@implementation DTSelectionRectView

- (instancetype)initWithFrame:(CGRect)frame {
	if (self = [super initWithFrame:frame]) {
		self.opaque = NO;
        _selectionColor = [DTColorCreateWithHexString(@"1B88EE") colorWithAlphaComponent:0.3];
	}
	return self;
}

- (void)setSelectionColor:(UIColor *)selectionColor {
    _selectionColor = selectionColor;
    
    [self setNeedsDisplay];
}

- (void)setSelectionRects:(NSArray *)selectionRects {
    _selectionRects = selectionRects;
    
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    for (NSString *r in self.selectionRects) {
        CGRect rect = CGRectFromString(r);
        
        [self.selectionColor setFill];
        CGContextFillRect(context, rect);
    }
}

@end


@interface DTSelectionView ()

@property (nonatomic, strong) DTSelectionCursor *leftCursor;
@property (nonatomic, strong) DTSelectionCursor *rightCursor;

@property (nonatomic, strong) DTSelectionRectView *selectionRectView;

@end

@implementation DTSelectionView

- (instancetype)initWithFrame:(CGRect)frame {
	if (self = [super initWithFrame:frame]) {
		
		[self addSubview:self.leftCursor];
		[self addSubview:self.rightCursor];
		[self addSubview:self.selectionRectView];

	}
	return self;
}

- (void)setSelectionColor:(UIColor *)selectionColor {
    _selectionColor = selectionColor;
    
	self.selectionRectView.selectionColor = selectionColor;
}

- (void)setSelectionRects:(NSArray *)selectionRects {
    _selectionRects = selectionRects;
    
	self.selectionRectView.selectionRects = selectionRects;
	[self setNeedsLayout];
}

- (CGRect)getSelectionRect {
	if (self.selectionRects.count > 1) {
		CGRect maxRect = CGRectZero;
		for (NSString *rectString in self.selectionRects) {
			maxRect = CGRectUnion(maxRect, CGRectFromString(rectString));
		}
		return maxRect;
	}
	return CGRectFromString(self.selectionRects.firstObject);
}

- (BOOL)canCursorMove:(CGPoint)point isLeft:(BOOL)isLeft {
    if (_leftCursor.hidden == YES || _rightCursor.hidden == YES) {
        return NO;
    }
    
    CGRect startRect = [_leftCursor touchRect];
    CGRect endRect = [_rightCursor touchRect];
    if (CGRectIntersectsRect(startRect, endRect)) {
        CGFloat distStart = GetDistanceToPoint(point, CGRectGetCenter(startRect));
        CGFloat distEnd = GetDistanceToPoint(point, CGRectGetCenter(endRect));
        
        if (isLeft) {
            if (distEnd <= distStart) return NO;
        } else {
            if (distEnd > distStart) return NO;
        }
    }
    if (isLeft) {
        return CGRectContainsPoint(startRect, point);
    } else {
        return CGRectContainsPoint(endRect, point);
    }
}

static inline CGPoint CGRectGetCenter(CGRect rect) {
    return CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
}

static inline CGFloat GetDistanceToPoint(CGPoint p1, CGPoint p2) {
    return sqrt((p1.x - p2.x) * (p1.x - p2.x) + (p1.y - p2.y) * (p1.y - p2.y));
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
	CGRect r1 = CGRectFromString(self.selectionRects.firstObject);
	CGRect leftRect = self.leftCursor.frame;
    self.leftCursor.frame = CGRectMake(CGRectGetMinX(r1), CGRectGetMinY(r1), leftRect.size.width, CGRectGetHeight(r1));
	
	CGRect r2 = CGRectFromString(self.selectionRects.lastObject);
	CGRect rightRect = self.rightCursor.frame;
	self.rightCursor.frame = CGRectMake(CGRectGetMaxX(r2), CGRectGetMinY(r2), rightRect.size.width, CGRectGetHeight(r1));
	
	self.selectionRectView.frame = self.bounds;
}

- (DTSelectionCursor *)leftCursor {
    if (!_leftCursor) {
        _leftCursor = [[DTSelectionCursor alloc] initWithFrame:CGRectZero isLeft:YES];
    }
    return _leftCursor;
}

- (DTSelectionCursor *)rightCursor {
    if (!_rightCursor) {
        _rightCursor = [[DTSelectionCursor alloc] initWithFrame:CGRectZero isLeft:NO];
    }
    return _rightCursor;
}

- (DTSelectionRectView *)selectionRectView {
	if (!_selectionRectView) {
		_selectionRectView = [[DTSelectionRectView alloc] init];
	}
	return _selectionRectView;
}

@end
