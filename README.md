# Criollo Web

This is the [Criollo.io](https://criollo.io) website.

## Building

A number of npm packages are used as dependencies for client side javascript, as well as jade and stylus templates so ...

```sh
pods install && npm install
open Criollo\ Web.xcworkspace
```

## Adding Users

Users are stored in the preferences of the app.

```sh
defaults write io.criollo.Criollo-Web Users -array-add '"{\"username\":\"criollo\",\"password\":\"123456\",\"email\":\"criollo@criollo.io\",\"firstName\":\"Criollo\",\"lastName\":\"\"}"'
```

*The backslashes are required. It's not an error. :)*

Other than that ...