# Note for 2016:

Comet was a personal exercise to see what it would be like to create a dynamically-typed scripting language in 48 hours.  It is no longer in development.

I am now developing a new language, called Delta, which will be compiled, statically-typed, functionally-inspired, and which I hope will at some point be suitable for production use.  Delta is not yet published on Github, but a "teaser" website will be up soon.

# Comet

# Welcome to Comet!

Comet is a dynamic object-oriented scripting language inspired by Smalltalk and Lua.  Its emphasis is on simplicity and modularity.  Here's what it looks like:

```
def :features <- lst [
  "Anonymous functions"
  "Currying"
  "Data description syntax"
  "Operator overloading"
  "Meta-programming and reflection"
]
write "You should use comet because it has..."
features :each write

def :comet_is <- lst [
  "Elegant"
  "Embeddable"
  "Object-oriented"
  "Functional"
  "Clean"
  "Dynamic"
]
write "Comet is also..."
comet_is :each write
```
