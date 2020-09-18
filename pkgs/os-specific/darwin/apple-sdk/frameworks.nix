# Current as of 10.9
# Epic weird knot-tying happening here.
# TODO: clean up the process for generating this and include it

{ frameworks, libs, libobjc, }:

with frameworks; with libs; {
  AGL                     = { inherit Carbon OpenGL; };
  AVFoundation            = { inherit ApplicationServices CoreGraphics; };
  AVKit                   = {};
  Accounts                = {};
  AddressBook             = { inherit libobjc Carbon ContactsPersistence; };
  AppKit                  = { inherit ApplicationServices AudioToolbox AudioUnit Foundation QuartzCore UIFoundation; };
  AppKitScripting         = {};
  AppleScriptKit          = {};
  AppleScriptObjC         = {};
  AudioToolbox            = { inherit CoreAudio CoreMIDI; };
  AudioUnit               = { inherit AudioToolbox Carbon CoreAudio; };
  AudioVideoBridging      = { inherit Foundation; };
  Automator               = {};
  CFNetwork               = {};
  CalendarStore           = {};
  Cocoa                   = { inherit AppKit CoreData; };
  Collaboration           = {};
  # Impure version of CoreFoundation, this should not be used unless another
  # framework includes headers that are not available in the pure version.
  CoreFoundation          = {};
  CoreAudio               = { IOKit };
  CoreAudioKit            = { AudioUnit };
  CoreData                = {};
  CoreGraphics            = { Accelerate IOKit IOSurface SystemConfiguration };
  CoreImage               = {};
  CoreLocation            = {};
  CoreMIDI                = {};
  CoreMIDIServer          = {};
  CoreMedia               = { ApplicationServices AudioToolbox AudioUnit CoreAudio CoreGraphics CoreVideo };
  CoreMediaIO             = { CoreMedia };
  CoreText                = { CoreGraphics };
  CoreVideo               = { ApplicationServices CoreGraphics IOSurface OpenGL };
  CoreWLAN                = { SecurityFoundation };
  DVDPlayback             = {};
  DirectoryService        = {};
  DiscRecording           = { CoreServices IOKit };
  DiscRecordingUI         = {};
  DiskArbitration         = { IOKit };
  EventKit                = {};
  ExceptionHandling       = {};
  FWAUserLib              = {};
  ForceFeedback           = { IOKit };
  Foundation              = { libobjc CoreFoundation Security ApplicationServices SystemConfiguration };
  GLKit                   = {};
  GLUT                    = { OpenGL };
  GSS                     = {};
  GameController          = {};
  GameKit                 = { Foundation };
  Hypervisor              = {};
  ICADevices              = { Carbon IOBluetooth };
  IMServicePlugIn         = {};
  IOBluetoothUI           = { IOBluetooth };
  IOKit                   = {};
  IOSurface               = { IOKit xpc };
  ImageCaptureCore        = {};
  ImageIO                 = { CoreGraphics };
  InputMethodKit          = { Carbon };
  InstallerPlugins        = {};
  InstantMessage          = {};
  JavaFrameEmbedding      = {};
  JavaScriptCore          = {};
  Kerberos                = {};
  Kernel                  = { IOKit };
  LDAP                    = {};
  LatentSemanticMapping   = { Carbon };
  MapKit                  = {};
  MediaAccessibility      = { CoreGraphics CoreText QuartzCore };
  MediaToolbox            = { AudioToolbox AudioUnit CoreMedia };
  Metal                   = {};
  MetalKit                = { ModelIO Metal };
  ModelIO                 = { };
  NetFS                   = {};
  OSAKit                  = { Carbon };
  OpenAL                  = {};
  OpenCL                  = { IOSurface OpenGL };
  OpenGL                  = {};
  PCSC                    = { CoreData };
  PreferencePanes         = {};
  PubSub                  = {};
  QTKit                   = { CoreMediaIO CoreMedia MediaToolbox QuickTime VideoToolbox };
  QuickLook               = { ApplicationServices };
  SceneKit                = {};
  ScreenSaver             = {};
  Scripting               = {};
  ScriptingBridge         = {};
  Security                = { IOKit };
  SecurityFoundation      = {};
  SecurityInterface       = { Security };
  ServiceManagement       = { Security };
  Social                  = {};
  SpriteKit               = {};
  StoreKit                = {};
  SyncServices            = {};
  SystemConfiguration     = { Security };
  TWAIN                   = { Carbon };
  Tcl                     = {};
  VideoDecodeAcceleration = { CoreVideo };
  VideoToolbox            = { CoreMedia CoreVideo };
  WebKit                  = { ApplicationServices Carbon JavaScriptCore OpenGL };

  # Umbrellas
  Accelerate          = { inherit CoreWLAN IOBluetooth; };
  ApplicationServices = { inherit CoreGraphics CoreServices CoreText ImageIO; };
  Carbon              = { inherit libobjc ApplicationServices CoreServices Foundation IOKit Security QuartzCore; };
  CoreBluetooth       = {};
  # TODO: figure out which part of the umbrella depends on CoreFoundation and move it there.
  CoreServices        = { inherit CFNetwork CoreFoundation CoreAudio CoreData DiskArbitration Security NetFS OpenDirectory ServiceManagement; };
  IOBluetooth         = { inherit CoreBluetooth IOKit; };
  JavaVM              = {};
  OpenDirectory       = {};
  Quartz              = { inherit QuartzCore QuickLook QTKit; };
  QuartzCore          = { inherit libobjc ApplicationServices CoreVideo OpenCL CoreImage Metal; };
  QuickTime           = { inherit ApplicationServices AudioUnit Carbon CoreAudio CoreServices OpenGL QuartzCore; };

  vmnet = {};
}
