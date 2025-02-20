//
//  DTAttributedLabel+Selection.h
//  DTCoreText (Mac)
//
//  Created by Ryan on 2025/2/17.
//  Copyright © 2025 Drobnik.com. All rights reserved.
//

#import <DTCoreText/DTCoreText.h>

NS_ASSUME_NONNULL_BEGIN

@class DTSelectionView;

@interface DTAttributedTextContentView (Selection)

@property (nonatomic, assign) NSRange selectedRange;

- (DTSelectionView *)selectionView;

- (void)showSelectionView:(CGPoint)point showCursor:(BOOL)isShowCursor isWord:(BOOL)isWord;
- (void)hideSelectionView;

- (NSString *)getSelectedText;
- (CGRect)getSelectionRect;

@end


@interface DTSelectionView: UIView

@property (nonatomic, strong) DTColor * selectionColor;
@property (nonatomic, strong) NSArray *selectionRects;

// 0未选择 1左 2右
@property (nonatomic, assign) NSInteger cursorState;


- (CGRect)getSelectionRect;

- (BOOL)canCursorMove:(CGPoint)point isLeft:(BOOL)isLeft;

@end

NS_ASSUME_NONNULL_END
