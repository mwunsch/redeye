**Redeye** is an attempt to build a native implemenation of [CoffeeScript](http://jashkenas.github.com/coffee-script/) on the [Rubinius VM](http://rubini.us/).

I built it because I like CoffeeScript, and I want to learn more about language implementation.

## Goals of the project:

1. Learn how to implement a programming language.
2. Ruby interoperability with CoffeeScript
3. An ECMAScript 5 implementation on Rubinius

Right now, I am forgoing a Lexer phase so I can learn more about why Jeremy felt one was necessary. Currently, Redeye only produces an AST, but it is my hope to get the AST as close as possible to CoffeeScript's before moving on to the Lexer or diving deeper into Rubinius.

While developing this project, I discovered [Brian Ford](https://github.com/brixen)'s [poetics](https://github.com/brixen/poetics), which could turn out to be really awesome.

I use [kpeg](https://github.com/evanphx/kpeg) for the PEG.

I'll be blogging about my progress and what I learn as I go: http://mwunsch.tumblr.com

## Installation

Clone the project, run `bundle` and in an irb shell try doing something like:

    > nodes = Redeye.run %q{ number = 42 }
    => #<Redeye::Nodes::Block:0x2d14 @nodes=#<Redeye::Nodes::Assign:0x2d18 @value=#<Redeye::Nodes::Value:0x2d1c @value=#<Redeye::Nodes::Literal:0x2d20 @value="42">> @variable=#<Redeye::Nodes::Value:0x2d2c @value=#<Redeye::Nodes::Literal:0x2d30 @value="number">>>>
    > puts nodes

    Block
    Assign
      Value "number"
      Value "42"
    => nil

Alternatively there's

    bin/redeye file_name.coffeescript

## Remember

This is a work in progress and totally experimental.

