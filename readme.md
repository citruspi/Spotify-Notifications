[![Build Status](https://travis-ci.org/citruspi/Spotify-Notifications.png?branch=master)](https://travis-ci.org/citruspi/Spotify-Notifications)

## Spotify Notifications

_Note: The project is currently being rewritten from scratch in Swift.
Development is taking place on the `master` branch. To build the 0.5.1
(Objective-C) release, checkout the `0.5.X` branch._

### 0.5.1 Feature Parity

- [x] Toggle notification sound
- [ ] Toggle notifications on resume
- [ ] Toggle dismissal of all notifications except the current one
- [ ] Implement a menu bar interface
- [ ] Toggle the menu bar icon
- [x] Toggle launch on login functionality
- [x] Toggle inclusion of album artwork
- [ ] Toggle global shortcut
- [x] Toggle disabling of notifications when Spotify has focus

## Building

Spotify Notifications uses [CocoaPods](http://cocoapods.org) which in turn
requires Ruby and Ruby Gems.

```
$ git clone https://github.com/citruspi/Spotify-Notifications.git
$ cd Spotify-Notifications
$ git submodule foreach git pull
$ pod install
$ open Spotify Notifications.xcworkspace
```

## Contributing

Pull requests are more than welcome!

In your pull request, include a __separate__ commit adding yourself to
`contributors.md`.

## License

The source code is dedicated to the public domain. See the `UNLICENSE` file for
more information.

The Spotify artwork and icon is owned by Spotify AB Inc.

Spotify Notifications makes use of the following libraries

- [nklizhe/NSBundle+LoginItem](https://github.com/nklizhe/NSBundle-LoginItem)
  (MIT)
- [Alamofire/Alamofire](https://github.com/Alamofire/Alamofire) (MIT)
- [SwiftyJSON/SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON) (MIT)
