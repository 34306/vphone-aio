// VPhoneObjC.h — ObjC wrappers for private Virtualization.framework APIs
#import <Foundation/Foundation.h>
#import <Virtualization/Virtualization.h>

NS_ASSUME_NONNULL_BEGIN

/// Create a PV=3 (vphone) VZMacHardwareModel using private _VZMacHardwareModelDescriptor.
VZMacHardwareModel *VPhoneCreateHardwareModel(void);

/// Set _setROMURL: on a VZMacOSBootLoader.
void VPhoneSetBootLoaderROMURL(VZMacOSBootLoader *bootloader, NSURL *romURL);

/// Configure VZMacOSVirtualMachineStartOptions.
/// Sets _setForceDFU:, _setPanicAction:, _setFatalErrorAction:
void VPhoneConfigureStartOptions(VZMacOSVirtualMachineStartOptions *opts,
                                  BOOL forceDFU,
                                  BOOL stopOnPanic,
                                  BOOL stopOnFatalError);

/// Set _setDebugStub: with a _VZGDBDebugStubConfiguration on the VM config (specific port).
void VPhoneSetGDBDebugStub(VZVirtualMachineConfiguration *config, NSInteger port);

/// Set _setDebugStub: with default _VZGDBDebugStubConfiguration (system-assigned port, same as vrevm).
void VPhoneSetGDBDebugStubDefault(VZVirtualMachineConfiguration *config);

/// Set _VZPvPanicDeviceConfiguration on the VM config.
void VPhoneSetPanicDevice(VZVirtualMachineConfiguration *config);

/// Set _setCoprocessors: on the VM config (empty array = no coprocessors).
void VPhoneSetCoprocessors(VZVirtualMachineConfiguration *config, NSArray *coprocessors);

/// Set _setProductionModeEnabled:NO on VZMacPlatformConfiguration.
void VPhoneDisableProductionMode(VZMacPlatformConfiguration *platform);

/// Create a _VZSEPCoprocessorConfiguration with the given storage URL.
/// Returns the config object, or nil on failure.
id _Nullable VPhoneCreateSEPCoprocessorConfig(NSURL *storageURL);

/// Set romBinaryURL on a _VZSEPCoprocessorConfiguration.
void VPhoneSetSEPRomBinaryURL(id sepConfig, NSURL *romURL);

/// Configure SEP coprocessor on the VM config.
/// Creates storage at sepStorageURL, optionally sets sepRomURL, and calls _setCoprocessors:.
void VPhoneConfigureSEP(VZVirtualMachineConfiguration *config,
                        NSURL *sepStorageURL,
                        NSURL *_Nullable sepRomURL);

/// Set an NVRAM variable on VZMacAuxiliaryStorage using the private _setDataValue API.
/// Returns YES on success.
BOOL VPhoneSetNVRAMVariable(VZMacAuxiliaryStorage *auxStorage, NSString *name, NSData *value);

/// Create a _VZPL011SerialPortConfiguration (ARM PL011 UART serial port).
/// Returns nil if the private class is unavailable.
VZSerialPortConfiguration *_Nullable VPhoneCreatePL011SerialPort(void);

// --- USB Input Devices ---

/// Configure _VZUSBTouchScreenConfiguration on the VM config.
/// Must be called before VM starts to enable touch input.
void VPhoneConfigureMultiTouch(VZVirtualMachineConfiguration *config);

/// Configure _VZUSBKeyboardConfiguration on the VM config.
/// Enables physical keyboard input in the native GUI window.
void VPhoneConfigureUSBKeyboard(VZVirtualMachineConfiguration *config);

/// Create a _VZTouch object using KVC (avoids crash in _VZTouch initWithView:...).
/// Returns nil if the _VZTouch class is unavailable.
id _Nullable VPhoneCreateTouch(NSInteger index,
                                NSInteger phase,
                                CGPoint location,
                                NSInteger swipeAim,
                                NSTimeInterval timestamp);

/// Create a _VZMultiTouchEvent from an array of _VZTouch objects.
id _Nullable VPhoneCreateMultiTouchEvent(NSArray *touches);

/// Get the _multiTouchDevices array from a running VZVirtualMachine.
NSArray *_Nullable VPhoneGetMultiTouchDevices(VZVirtualMachine *vm);

/// Send multi-touch events to a multi-touch device.
void VPhoneSendMultiTouchEvents(id multiTouchDevice, NSArray *events);

// --- VNC (experimental, Virtualization.framework built-in) ---

/// Create and start a _VZVNCServer bound to a random port (port:0).
/// Returns the server object (opaque AnyObject for Swift), or nil on failure.
id _Nullable VPhoneCreateVNCServer(VZVirtualMachine *virtualMachine, NSString *password);

/// Return the current port the VNC server is listening on.
/// Returns 0 if not yet assigned.
uint16_t VPhoneGetVNCPort(id vncServer);

/// Stop the VNC server.
void VPhoneStopVNCServer(id vncServer);

NS_ASSUME_NONNULL_END
