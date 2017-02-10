## Building the Sparkle.zip

The structure of `Sparkle.zip` is:

```
Sparkle
  codesign_xpc
  Sparkle.framework
  XPCServices
    org.sparkle-project.InstallerConnection.xpc
    org.sparkle-project.InstallerLauncher.xpc
    org.sparkle-project.InstallerStatus.xpc
```

In order to get xpc services to be signed and work properly, they need to be copied into an `XPCServices` folder in `MyApp.app/Contents`

The `codesign_xpc` can properly sign these files once they have been copied into place.

1. Fetch the `ui-separation-and-xpc` branch
2. Copy the `bin/codesign_xpc` into the `Sparkle` folder
3. Run `make release` and change to the output folder
4. Copy the `Sparkle.framework` into the `Sparkle` folder
5. Copy each of the above xpc files into the `XPCServices` folder
6. compress the `Sparkle` folder