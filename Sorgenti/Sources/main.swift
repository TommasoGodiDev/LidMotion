import AppKit

// Test visivo senza muovere il coperchio:
//   LidMotion --render-test <cartella-output> [immagine]

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
