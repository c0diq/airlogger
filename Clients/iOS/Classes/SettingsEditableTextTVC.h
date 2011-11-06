#import <UIKit/UIKit.h>

@interface SettingsEditableTextTVC : UITableViewController <UITextFieldDelegate> {
	NSString* prop;
}

-(id) initWithTitle:(NSString*)t propToEdit:(NSString*)_prop;

/* private */
-(void) tapDone;

@end
