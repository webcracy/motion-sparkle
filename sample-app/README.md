# sample-app #

## Build and Run ###

- `rake build`
- `rake run`

Run `rake -T` to display a list of supported tasks.

## Deploying to the App Store ##

To deploy to the App Store, you'll want to use `rake clean
archive:distribution`. With a valid distribution certificate.

In your `Rakefile`, set the following values:

```ruby
#This is only an example, you certificate name may be different.
app.development do
  app.codesign_certificate = "Mac Developer: xxxxx"
end

app.release do
  app.codesign_certificate = "3rd Party Mac Developer Application: xxxxx"
end

app.codesign_for_development = true
app.codesign_for_release = true
```

It's also recommand to use [motion-provisoning](https://github.com/HipByte/motion-provisioning)

## Icons ##

Apple supports both the use of `.icns` and Asset Catalogs for defining icons.

### ICNS ###

Place your icon under `./resources/`, add the following line to `Rakefile`:

```
  app.icon = "Icon.icns"
```

### Asset Catalogs ###

You'll find icon under `./resources/Assets.xcassets`. You can run the following
script to generate all the icon sizes (once you've specified `1024x1024.png`).
Keep in mind that your `.png` files _cannot_ contain alpha channels.

Save this following script to `./gen-icons.sh` and run it:

```sh
set -x

brew install imagemagick

pushd resources/Assets.xcassets/AppIcon.appiconset/

for size in 512 256 128 32 16
do
  cp "1024x1024.png" "Icon_${size}x${size}.png"
  mogrify -resize "$((size))x$((size))" "Icon_${size}x${size}.png"

  cp "1024x1024.png" "Icon_${size}x${size}@2x.png"
  mogrify -resize "$((size*2))x$((size*2))" "Icon_${size}x${size}@2x.png"
done

popd
```

Add following line to `Rakefile`:

```
  app.info_plist['CFBundleIconName'] = 'AppIcon'
```

For more information about Asset Catalogs, refer to this link: https://developer.apple.com/library/content/documentation/Xcode/Reference/xcode_ref-Asset_Catalog_Format/


## Contributing ##

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
