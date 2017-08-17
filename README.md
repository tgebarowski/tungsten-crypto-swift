# Tungsten Crypto library #

## What is Tungsten? ##

Tungsten is a messaging application for encrypted and anonymous communication with other users.

You can get the application:

* On our website: [ https://tungstenapp.com/ ](https://tungstenapp.com/)
* Via the Apple App Store: [ Get Tungsten on App Store ](https://itunes.apple.com/app/tungsten-secure-messenger/id1157017593)

All text messages and data sent via Tungsten are end-to-end encrypted. Tungsten uses its own protocol, with support for offline messaging, multi-device setups as well as group messaging. All encrypted communication is synchronised between all of the users devices.

Tungsten allows users to create multiple identities to keep their conversations organized. With multiple identities, users can easily manage who can reach them without compromising the user's personal information or mixing up context.

Tungsten offers an easy way to set up another device with a complete history of existing conversations. It requires physical access to both devices, which adds an additional level of security.

## Feature comparison for Tungsten and other popular protocols ##
 
| Feature          | Open PGP  | OTR  |  Tungsten |
| ---------------- | --------- | ---- | --------- |
| Multiple devices | Yes       | No   | Yes       |
| Offline messages | Yes       | Yes  | Yes       |
| File Transfer    | Yes       | No   | Yes       |
| Verifiability    | No        | Yes  | Yes       |
| Deniability      | Yes       | Yes  | Yes       |
| Forward secrecy  | No        | Yes  | Yes       |

## What is the Tungsten Crypto library? ##

The Tungsten crypto library is an open source software written in Swift language designed for encrypting and decrypting messages sent via the Tungsten app.

This repository contains the library as well as tests for it.

## Building the library from the source ##

### Prerequisites ###

* macOS 10.11 or newer
* Latest Xcode
* Tools:
  * Bundler (http://bundler.io)
  * CocoaPods 1.1.0 or newer (https://cocoapods.org/)

### Building the library ###

macOS
```
# clone the repository
git clone https://github.com/TungstenLabs/tungsten-crypto-swift.git tungsten-crypto-swift
cd tungsten-crypto-swift
bundle exec pod install
```

### Development ###

For development we recommend using the latest version of Xcode.

## License

Copyright © 2018 Tungsten Labs UG.
