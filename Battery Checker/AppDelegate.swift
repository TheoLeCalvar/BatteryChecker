import Cocoa
import CoreFoundation
import IOKit.ps

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    
    override init() {
        
        super.init()
        setupBatteryWatcher()
    }
    
    func setupBatteryWatcher() {
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), nil, { (_, _, _, _, _) in
            struct Holder {
                static var shouldSendNotification = false
            }

            let blobUnmanaged :Unmanaged<CFTypeRef>! = IOPSCopyPowerSourcesInfo()
            let blob = blobUnmanaged.takeRetainedValue()
            let sourcesUnmanaged : Unmanaged<CFArray>! = IOPSCopyPowerSourcesList(blob)
            let sources = sourcesUnmanaged.takeRetainedValue()
            let source : CFTypeRef = Unmanaged.fromOpaque(CFArrayGetValueAtIndex(sources, 0)).takeUnretainedValue()
            
            let sourceDescUnmanaged : Unmanaged<CFDictionary>! = IOPSGetPowerSourceDescription(blob, source)
            let sourceDesc = sourceDescUnmanaged.takeUnretainedValue() as Dictionary
            
            for (key, val) in sourceDesc {
                if ((key as! String == kIOPSPowerSourceStateKey) && (val as! String == kIOPSACPowerValue)) {
                    Holder.shouldSendNotification = true;
                }
                else if ((key as! String == kIOPSIsFinishingChargeKey) && (val as! Bool == true)) {
                    if (Holder.shouldSendNotification) {
                        let note = NSUserNotification.init()
                        note.title = "Battery checker"
                        note.subtitle = "Battery is fully charged"
                        note.soundName = NSUserNotificationDefaultSoundName
                        
                        NSUserNotificationCenter.default.deliver(note)
                        
                        Holder.shouldSendNotification = false
                    }
                }
            }
        },
        kIOPSNotifyAnyPowerSource as CFString!,
        nil,
        CFNotificationSuspensionBehavior.drop)
    }
}
