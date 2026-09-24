#import "DMPExampleViewController.h"
@import Dimina;

@interface DMPExampleViewController ()
@property (nonatomic, strong) DMPObjCApp *miniProgram;
@end

@implementation DMPExampleViewController

- (void)openMiniProgram {
    if (self.navigationController == nil) {
        NSLog(@"Dimina requires a UINavigationController");
        return;
    }
    DMPObjCManager *manager = DMPObjCManager.shared;
    [manager setupWithApiNamespaces:@[]];
    manager.showCapsule = YES;
    manager.showLaunchLoading = YES;

    DMPObjCAppConfig *config = [[DMPObjCAppConfig alloc]
        initWithAppName:@"小程序名称" appId:@"wx92269e3b2f304afc"];
#if DEBUG
    config.isDebugMode = YES;
#endif
    // For a remotely installed app, set this to your actual update manifest URL:
    // config.updateManifestUrl = @"https://your-server/jsapp/wx92269e3b2f304afc.json";
    if (self.miniProgram == nil) {
        self.miniProgram = [manager appWithConfig:config];
        [self.miniProgram setupWithNavigationController:self.navigationController];
    }

    DMPObjCLaunchConfig *launch = [DMPObjCLaunchConfig new];
    launch.query = @{ @"from": @"objc-host" };
    launch.launchAnimated = @YES;
    [self.miniProgram launchWithConfig:launch completion:^(BOOL launched) {
        if (!launched) {
            NSLog(@"Mini program launch failed or another operation is in progress");
        }
    }];
}

- (void)closeMiniProgram {
    [self.miniProgram closeWithCompletion:^(NSError *error) {
        if (error != nil) {
            NSLog(@"Close failed: %@", error.localizedDescription);
        }
    }];
}

@end
