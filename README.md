# Godot iOS plugin for In-App purchase

This is a Godot iOS plugin for In-App purchase.
This plugin uses Storekit in Swift.

## Contents

- Features
- Install
- Build
- How to use
- Acknowledgements
- License

## Features

- Request product list
- Request purchase a product
- Request current entitlements (purchased item lists)
- Receive actions outside of the app and send them as purchase responses

## Install

TODO

## Build

The build steps are confirmed in the following environments.

- Godot: 4.4
- macOS: Sequoia 15.4.1
- Xcode: 16.3
- scons: v4.8.1
- python: 3.12
- iPhone: iPhone SE, iOS 18.3.2

There are build steps.

- Generate godot header files
- Generate plugin's static library
- Copy it into your Godot project

### Generate godot header files

```bash
% cd godot_ios_plugin_iap
# Clean godot directory
% script/build.sh -g
# Download specified godot version
% script/build.sh -G 4.4
# Generate godot header. In this case, it waits 600 seconds, assuming that the build process would be finished 
% script/build.sh -Ht 600
```

### Generate plugin's static library and copy it into your Godot project

```bash
% ./generate_static_library.sh
```

### Copy it into your Godot project

Edit ```TARGET_PROJECT``` in ```copy_plugin.sh``` to your godot project and run it.

copy_plugin.sh
```bash
TARGET_PROJECT=../iap-sample-project
```

```bash
% ./copy_plugin.sh
```

## How to use

TODO

## Acknowledgements

This plugin is built on the following works.
Thank you @DrMoriarty and @cengiz-pz !

- Godot iOS Plugin template https://github.com/DrMoriarty/godot_ios_plugin_template
- In-app Review Plugin https://github.com/cengiz-pz/godot-ios-inapp-review-plugin
    - godot_ios_plugin_iap
        - script
            - LICENSE

## License

```
MIT License

Copyright (c) 2025 Hiroki Taira

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```