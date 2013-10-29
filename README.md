# Using motion-sparkle to add Sparkle to your Rubymotion project

*NB: Sparkle only works for OS X projects*

## Overview

[Sparkle](http://sparkle.andymatuschak.org/) is a free auto-updater library for Cocoa apps. It powers countless Mac applications' "Check for updates" feature, as it takes care of all the process automatically, is very easy to integrate and is secure.

In a nutshell, when users click "Check for updates..." in an app, Sparkle checks for updates against an XML file that you post somewhere on the web. That XML file contains information about your new release, such as the version number, the URL of the package and its digital signature. If there's a newer version available than the one that is currently running, it'll ask for permission to retrieve the package and replace the current app with the new release.

While it's easy to use Sparkle with RubyMotion without motion-sparkle, using it makes it even easier. The gem takes care of the Sparkle framework integration, simplifies its configuration and then automates the preparation of a release, creating the ZIP file, XML and release notes for you.

After building your app for release and running `rake sparkle:package`, all you need to do is upload 3 files to an URL you specified in the Rakefile and your users will be able to get the new release.

## Installation

In your project's Gemfile, add:

    gem 'motion-sparkle'

and then run 

    $ bundle install

## Settings configuration

Configure Sparkle in your `Rakefile` using motion-sparkle's DSL:

    # Rakefile
  
    app.sparkle do
      # Required setting
      release :base_url, 'http://example.com/releases/current' # `current` is a folder, don't use a trailing slash

      # Recommended setting
      # This will set both your `app.version` and `app.short_version` to the same value
      # It's fine not to use it, just remember to set both as Sparkle needs them
      release :version, '1.0'
      
      # Optional settings and their default values
      release :feed_filename, 'releases.xml'
      release :notes_filename, 'release_notes.html'
      release :package_filename, "#{app.name}.zip"
      release :public_key, 'dsa_pub.pem'
    
    end

To complete the configuration, run

    $ rake sparkle:setup


If everything is OK, you should be informed that it's time to generate or configure your certificates.

## Certificate configuration

For security, Sparkle allows you to sign your releases with a private certificate before distribution. In a few words: when the user tries to install an update, Sparkle will check the package using the signature provided in the XML file and the public certificate contained in the running application.

motion-sparkle makes it very easy to handle this. In fact, after the first setup, it becomes completely transparent to you and is all handled when you run `rake sparkle:package`.

You have two options: have Sparkle generate the certificates for you, or follow the instructions.

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
* add it go your .gitignore or equivalent 
* make a backup of it

### Run `rake:setup` at any moment to make sure your config is OK

When all is good, move forward. If you need help, you can always open an issue on Github.

## Adding "Check for updates..." to the menu

Sparkle makes it incredibly easy to add a "Check for updates" feature to your app. 

The `SUUpdater` class has a shared updater instance that you can use as a `target` for the different actions Sparkle provides. To launch the typical Sparkle flow, you need only to call the `checkForUpdates:` action. 

So, running `SUUpdater.new.checkForUpdates` will launch the "Check for updates" flow.

Here's an example based on the Rubymotion default OS X app example, "Hello". 

This will add the classic "Check for updates..." entry on the menu; when the user clicks it, the nice default of experience of Sparkle will begin.

In `menu.rb`, right below the line that adds the "Preferences" item:

    sparkle = addItemWithTitle("Check for updates...", action: nil, keyEquivalent: '')
    sparkle.setTarget SUUpdater.new
    sparkle.setAction 'checkForUpdates:'

Once you build your application, you should be able to see a "Check for updates..." item in the Application menu. It should work but would still produce an error at this point. Keep going to make it all work.

Check out Sparkle's documentation for more details and further ways to customize the experience.

## First publication

Before you build, make sure you've set your `:base_url` to a destination where you can upload/download your files. Note that packaging with motion-sparkle only works with the `:release` target at the moment, so make sure your build with be compatible with `rake build:release`.

Run the setup command

    $ rake sparkle:setup

If you're ready to go, you should probably add 

    $ rake sparkle:package

This should create 3 files inside the `sparkle/release/` folder: a ZIP file of your app, an XML file and an HTML file with the release notes.

If you've set your `:base_url` correctly, go ahead and upload thoses files to the location you've specified. Run your app and click "Check for updates..." in the menu -- this time, it should say that it's running the latest version available.

## Releasing updates

Once users are running a Sparkle-powered version, all you have to do is put updated versions of those files at the same location.

To do so, follow the same steps every time:

### 1. Bump the version

    # In your Rakefile
  
    sparkle.app do
      release :version, '1.1' # bump the versions
    end

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

If you need further help, please open an Issue on Github.

Limitations:

  *   Only tested with Ruby 1.9.3-p448
  *   Only works with ZIP files
  *   Only works with :release build target
  *   The Sparkle framework is horrendously copied multiple times

To further troubleshoot your case, you clone/fork the repo and go through the tests and the code.

To test, you can just run `$ bundle install` at the source of the repo to install the development dependencies and the run `$ rake` to execute the tests.

Test coverage currently only extends to configuration and certificate generation checking.

## Contributing

Wanted features:

  - [ ]  Copy the Sparkle.framework in a more sensible way, ideally through Cocoapods (it's currently copied multiple times because rubygems won't handle symlinks)
  - [ ]  Configurable build targets (only :release supported currently)
  - [ ]  Have more than ZIP as a packaging option, with DMG a priority (see choctop gem)
  - [ ]  Automatic upload to S3 and via rsync/scp/sftp/ftp (see choctop gem)
  - [ ]  Textile / Markdown for release note templates
  - [ ]  Ruby 1.8.7, Ruby 1.9.2, Ruby 2.0 compatibility
  - [ ]  Better test coverage

## Credits

Author: Alexandre L. Solleiro

* Follow me on Twitter - http://twitter.com/als, 
* Fork my code on Github - http://github.com/webcracy, 
* More info on my website - http://webcracy.org

Thanks: Authors and contributors of HipByte/motion-cocoapods, drnic/choctop gems and of course andymatuschak/Sparkle. Their code has made this easier.
