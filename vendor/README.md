## Building the Sparkle.zip

The `vendor` directory should contain

```
vendor
  codesign_embedded_executable
  generate_appcast
  README.md
  Sparkle.zip
```

The structure of `Sparkle.zip` is:

```
Sparkle
  Sparkle.framework
  XPCServices
    org.sparkle-project.Downloader.xpc    (not usually needed)
    org.sparkle-project.InstallerConnection.xpc
    org.sparkle-project.InstallerLauncher.xpc
    org.sparkle-project.InstallerStatus.xpc
```

In order to get xpc services to be signed and work properly, they need to be copied into an `XPCServices` folder in `MyApp.app/Contents`

The `codesign_embedded_executable` can properly sign these files once they have been copied into place.

1. Fetch the `ui-separation-and-xpc` branch
2. Copy the `bin/codesign_embedded_executable` into the `vendor` folder
3. Run `make release` and change to the output folder
4. Copy the `Sparkle.framework` into the `Sparkle` folder
5. Copy each of the above xpc files into the `XPCServices` folder
6. compress the `Sparkle` folder