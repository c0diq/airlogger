#import "SettingsEditableTextTVC.h"

@implementation SettingsEditableTextTVC

static int TextFieldTag = 1;

-(id) initWithTitle:(NSString*)t propToEdit:(NSString*)_prop {
	[super initWithStyle:UITableViewStyleGrouped];
	prop = [_prop retain];
	self.title = t;
	return self;
}

-(void) dealloc {
	[prop release];
    [super dealloc];
}

-(UIBarButtonItem*) backArrowButtonThatWorksAsLeftBarButtonItem:(UINavigationController*)navC {
	UIButton* npBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [npBtn setImage:[UIImage imageNamed:@"backNavArrowButton.png"] forState:UIControlStateNormal];
	[npBtn addTarget:navC action:@selector(popViewControllerAnimated:) forControlEvents:UIControlEventTouchUpInside];
	CGRect bounds = npBtn.bounds;
	//bounds.size.width = npBtn.imageView.bounds.size.width;
	//bounds.size.height = npBtn.imageView.bounds.size.height;
	bounds.size.width = 43;
	bounds.size.height = 31;
	npBtn.bounds = bounds;
	return [[[UIBarButtonItem alloc] initWithCustomView:npBtn] autorelease];
}

-(void) viewDidLoad {
	self.navigationItem.leftBarButtonItem = [self backArrowButtonThatWorksAsLeftBarButtonItem:self.navigationController];
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
																							target:self
																							action:@selector(tapDone)] 
											  autorelease];
}

-(NSInteger) numberOfSectionsInTableView:(UITableView*)tableView {
	return 1;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return 1;
}

-(UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
	static NSString* EditableTextCellIden = @"EditableTextCellIden";
	UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:EditableTextCellIden];
	if (!cell) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:EditableTextCellIden]
								autorelease];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		UITextField* tf = [[[UITextField alloc] initWithFrame:CGRectMake(15, 10, 320 - 30, 30)] autorelease];
		tf.delegate = self;
        tf.adjustsFontSizeToFitWidth = YES;
        tf.textColor = [UIColor blackColor];
        tf.keyboardType = UIKeyboardTypeDefault;
        tf.returnKeyType = UIReturnKeyDone;
        tf.backgroundColor = [UIColor whiteColor];
        tf.autocorrectionType = UITextAutocorrectionTypeNo; // no auto correction support
        tf.autocapitalizationType = UITextAutocapitalizationTypeNone; // no auto capitalization support
        tf.textAlignment = UITextAlignmentLeft;
		tf.clearButtonMode = UITextFieldViewModeAlways;
        [tf setEnabled:YES];
		tf.tag = TextFieldTag;
        [cell addSubview:tf];
	}
	
	UITextField* tf = (UITextField*)[cell viewWithTag:TextFieldTag];
	tf.text = [[NSUserDefaults standardUserDefaults] stringForKey:prop];
	[tf becomeFirstResponder];
	return cell;
}

-(BOOL) textFieldShouldReturn:(UITextField*) textField {
	[self tapDone];
	return NO;
}

-(void) tapDone {
	UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
	UITextField* tf = (UITextField*)[cell viewWithTag:TextFieldTag];
	[[NSUserDefaults standardUserDefaults] setObject:tf.text forKey:prop];
	[[NSUserDefaults standardUserDefaults] synchronize];
	//[self.navigationController popToRootViewControllerAnimated:YES];
    [self.parentViewController dismissModalViewControllerAnimated:YES];
}

@end

