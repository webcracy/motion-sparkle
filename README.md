# motion-sparkle-sandbox

Easily package and release updates of your RubyMotion app with Sparkle.

*NB: Sparkle only works for OS X projects*

## Sandboxing

This version uses the [ui-separation-and-xpc branch](https://github.com/sparkle-project/Sparkle/tree/ui-separation-and-xpc) to support an app that uses sandboxing.  Sparkle is in transition, and the sandbox version is slated for 2.0.

_Sparkle built from https://github.com/sparkle-project/Sparkle/commit/14871e5ee9753bba3c4b0d8a87e674306d264dc5 on Sep 22nd, 2019_

[Reference thread](https://github.com/sparkle-project/Sparkle/issues/363)

## Table of Contents

- [Overview](#overview)
- [Compatibility](#compatibility)
- [Installation](#installation)
- [Settings configuration](#settings-configuration)
- [Certificate configuration](#certificate-configuration)
	- [Generate new certificates](#generate-new-certificates)
	- [Use your existing certificates](#use-your-existing-certificates)
	- [Notes about the public certificate](#notes-about-the-public-certificate)
	- [Notes about the private certificate](#notes-about-the-private-certificate)
	- [Warning regarding your private certificate](#warning-regarding-your-private-certificate)
	- [Run rake sparkle:setup at any moment to make sure your config is OK](#run-rake-sparklesetup-at-any-moment-to-make-sure-your-config-is-ok)
- [Adding "Check for updates..." to the menu](#adding-check-for-updates-to-the-menu)
- [First publication](#first-publication)
- [Releasing updates](#releasing-updates)
	- [1. Bump the version](#1-bump-the-version)
	- [2. Build your app for release](#2-build-your-app-for-release)
	- [3. Update your Release Notes](#3-update-your-release-notes)
	- [4. Package the release](#4-package-the-release)
	- [5. Upload](#5-upload)
- [Help, Limitations, Troubleshooting and Testing](#help-limitations-troubleshooting-and-testing)
- [Contributing](#contributing)
- [Credits](#credits)

## Overview

[Sparkle](http://sparkle.andymatuschak.org/) powers the "Check for updates" feature of countless Mac applications.

In a nutshell, when users click "Check for updates..." in an app, Sparkle checks for available updates against an XML file that you post somewhere on the web. That XML file contains information about your new release, such as the version number, the URL of the package and its digital signature. If there's a newer version available than the one that is currently running, it'll ask for permission to retrieve the package and replace the current app with the new release.

While it's easy to use Sparkle with RubyMotion without `motion-sparkle-sandbox`, it's even easier if you use it. The gem takes care of the Sparkle framework integration, simplifies its configuration and then automates the preparation of a release, creating the ZIP, XML and release notes HTML file for you.

After building your app for release and running `rake sparkle:package`, all you need to do is upload 3 files to the URL you specify in the `Rakefile` and your users will be able to get the new release.

## Compatibility

### Mac OS X 10.10 and above

  * Use the latest version of **motion-sparkle-sandbox**
  * You will need RubyMotion version 2.38 or above for Yosemite compatibility
  * Sparkle only supports Mac OS X 10.10 Yosemite and above

## Installation

In your project's Gemfile, add:
```ruby
# Gemfile

gem 'motion-sparkle'
```
and then run

    $ bundle install

## Settings configuration

Configure Sparkle in your `Rakefile` using `motion-sparkle-sandbox`'s DSL:
```ruby
# Rakefile

app.sparkle do
  # Required setting
  release :base_url, 'http://example.com/releases/current' # `current` is a folder, don't use a trailing slash

  # Recommended setting
  # This will set both your `app.version` and `app.short_version` to the same value
  # It's fine not to use it, just remember to set both as Sparkle needs them
  release :version, '1.0'

  ## Optional settings and their default values and/or examples

  ## Please note that `base_url` must always be set (at the moment),
  ## even you override it completely with the options below

  # Public Key
  release :public_key, 'dsa_pub.pem' # default

  # Appcast Feed
  release :feed_base_url, 'http://downloads.example.com/releases' # defaults to base_url
  release :feed_filename, 'releases.xml' # default

  # Release Notes
  release :notes_base_url, 'http://downloads.example.com/releases' # defaults to base_url
  release :notes_filename, 'release_notes.html' # default

  # App Package
  release :package_base_url, 'http://downloads.example.com/releases' # defaults to base_url
  release :package_filename, "#{app.name}.zip" # default
end
```

To complete the configuration, run

    $ rake sparkle:setup


If everything is OK, you should be informed that it's time to generate or configure your certificates.

## Certificate configuration

For security, Sparkle allows you to sign your releases with a private certificate before distribution: when the user tries to install an update, Sparkle will check the package using the signature provided in the XML file and the public certificate contained in the running application.

motion-sparkle-sandbox makes it very easy to handle this. In fact, after the first setup, it becomes completely transparent to you as all is handled when you run `rake sparkle:package`.

You have two options: have Sparkle generate the certificates for you, or follow the instructions to use your existing ones.

### Generate new certificates

    $ rake sparkle:setup_certificates


### Use your existing certificates

By default, your certificates need to be placed in the following directories:


    ./resources/dsa_pub.pem         # public certificate
    ./sparkle/config/dsa_priv.pem   # private certificate


### Notes about the public certificate

The public certificate is placed at the root of the default `resources/` folder by default, as it needs to bundled with your app. If you chose to rename it, remember to set its correct value in the `Rakefile`, using `release :public_key, 'new_name.pem'`.

### Notes about the private certificate

The private certificate cannot be renamed nor placed elsewhere. If you have an existing certificate, please name it `dsa_priv.pem` and place inside the `sparkle/config/` folder

### Warning regarding your private certificate

Be careful when handling the private certificate: you should never lose it nor share it. If you do, you'd lose the ability to sign your packages and users wouldn't be able to update your app. If someone takes it, they could sign the packages in your name and have your users install who knows what.

Tips:
* add it go your `.gitignore` or equivalent
* make a backup of it

### Run `rake sparkle:setup` at any moment to make sure your config is OK

When all is good, move forward. If you need help, you can always open an issue on Github.

## Adding "Check for updates..." to the menu

Sparkle makes it incredibly easy to add a "Check for updates" feature to your app.

Sparkle's `SUUpdater` class has a shared updater instance that can serve as a `target` for Sparkle actions. To launch the typical Sparkle flow, call the `checkForUpdates:` action.

So, to launch the "Check for updates" flow, you can call `SUUpdater.new.checkForUpdates`.

Here's an example based on the RubyMotion default OS X app example, "Hello". You can check out Sparkle's documentation for more details and further ways to customize the experience.

This will add the classic "Check for updates..." entry on the menu; when the user clicks it, the nice default of experience of Sparkle will begin.

In `menu.rb`, right below the line that adds the "Preferences" item:
```ruby
  sparkle = addItemWithTitle("Check for updates...", action: nil, keyEquivalent: '')
  sparkle.setTarget SUUpdater.new
  sparkle.setAction 'checkForUpdates:'
```

Once you build your application, you should be able to see a "Check for updates..." item in the Application menu. Using it will work but will quickly produce an error. Keep going to make it work.

## First publication

Before you build, make sure you've set your `:base_url` to a destination where you can upload/download your files.

Note that packaging with motion-sparkle-sandbox only works with the `:release` target at the moment, so make sure your build with be compatible with `rake build:release`.

Run the setup command again to make sure it's all good:

    $ rake sparkle:setup

If you're ready to go, run the `sparkle:package` task:

    $ rake sparkle:package

This should create 3 files inside the `sparkle/release/` folder: a ZIP file of your app, an XML file and an HTML file with the release notes.

If you've set your `:base_url` correctly, go ahead and upload thoses files to the location you've specified. Run your app and click "Check for updates..." in the menu -- this time, it should say that it's running the latest version available.

## Releasing updates

Once users are running a Sparkle-powered version, all you have to do is put updated versions of those files at the same location.

To do so, follow the same steps every time:

### 1. Bump the version

```ruby
  # In your Rakefile

  sparkle.app do
    release :version, '1.1' # bump the versions
  end
```

### 2. Build your app for release

    $ rake build:release

### 3. Update your Release Notes

Release notes are generated using an HTML file for content and an ERB file for layout. Sparkle uses Webkit to show them to your users at the time of update.

You can either change these files inside the `sparkle/config/` folder, or simply edit the resulting html file in `sparkle/release/` after you've packaged the release.

### 4. Package the release

Run the `sparkle:package` task and you'll be one step away from distribution.

    $ rake sparkle:package

### 5. Upload

Upload the 3 files and your new version is up. When users click "Check for updates...", the app should now display your release notes and ask the user to update. And when they do, the app will update and relaunch itself cleanly.

Sparkle for the win.

## Help, Limitations, Troubleshooting and Testing

If you need further help, please open an [Issue on Github](https://github.com/digitalmoksha/motion-sparkle-sandbox/issues/).

Limitations:

  *   Only tested with Ruby 1.9.3-p448
  *   Only works with ZIP files
  *   Only works with :release build target
  *   The Sparkle framework is horrendously copied multiple times

To further troubleshoot your case, you clone/fork the repo and go through the tests and the code.

To test, you can just run `$ bundle install` at the source of the repo to install the development dependencies and the run `$ rake` to execute the tests.

Test coverage currently only extends to configuration and certificate generation checking.

## Contributing

Please do help with comments, issues and pull requests! The gem's repository is at [github.com/digitalmoksha/motion-sparkle-sandbox](https://github.com/digitalmoksha/motion-sparkle-sandbox/).

## Credits

Contributors: [View all on Github](https://github.com/digitalmoksha/motion-sparkle-sandbox/graphs/contributors)

Originally created by [Alexandre L. Solleiro](http://github.com/webcracy), and forked from [webcracy/motion-sparkle](https://github.com/webcracy/motion-sparkle)

Huge thanks to [andymatuschak/Sparkle](https://github.com/andymatuschak/Sparkle) for creating and continuing to maintain Sparkle!
