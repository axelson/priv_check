# PrivCheck

Elixir libraries can define a [private
API](https://hexdocs.pm/elixir/writing-documentation.html#hiding-internal-modules-and-functions)
by defining a module that is documented as `@moduledoc false`, or a function
that is defined as `@doc false`, that module or function should not be called or
referenced. PrivCheck is a library to generate warnings when private API's are
called.

## Status

Experimental, and lightly tested.

TODO:
- [x] Ignore generated code
- [x] Fix all errors from a default phoenix application
- [x] Store the traces in a file so the warnings can be re-generated on partial compiles
- [ ] Provide configuration (allow users to ignore warnings)

## Raison D'etre

In Elixir it is quite easy to use private API's without realizing, especially if
the developer is just copying code from a blog post since there are no warnings
or errors emitted when using hidden modules. Part of Elixir's philosophy is to
help developers [fall into the pit of
success](https://blog.codinghorror.com/falling-into-the-pit-of-success/) (e.g.
make it easy to do the right thing). So we should make it easy for a developer
to avoid using the private API's. This library is my attempt to make this
guideline easy to follow.

The [usage of private
API's](https://elixirforum.com/t/proposal-private-modules-general-discussion/19374/151)
has caused downstream bugs, and resulted in a PSA due to [inadvertant breakage
in Elixir
v1.7](https://elixirforum.com/t/psa-do-not-use-private-apis-request-a-feature-instead/15449)

Building the concept of Private Modules into the language has been [proposed and
accepted](https://elixirforum.com/t/proposal-private-modules-general-discussion/19374/143),
but it has not yet been implemented.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `priv_check` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:priv_check, "~> 0.1.0", only: :dev, runtime: false},
  ]
end
```

In your project's `mix.exs` file in your `project` function add `:priv_check` to
the list of compilers.

```elixir
def project do
  [
    ...
    compilers: [:priv_check] ++ Mix.compilers(),

    # If you're using Phoenix it will probably look a little more like this instead:
    compilers: [:priv_check, :phoenix, :gettext] ++ Mix.compilers(),
    ...
  ]
end
```

Then run `mix clean` and then `mix compile`

## Nomenclature: Private APIs vs Hidden modules

`@moduledoc false` hides the module from documentation (as implemented in
[ex_doc](https://github.com/elixir-lang/ex_doc)) which is an indication that the
module should not be used by consumers of the library.

## How it Works

PrivCheck uses the compiler tracing feature that was released in Elixir v1.10.
When elixir compiles the applications code it keeps a log of all referenced
modules and function calls. PrivCheck looks at those modules and functions, and
inspects their documentation to ascertain if they are hidden modules or
functions, if they are it emits a warning for each violation.

## Limitations

It is often expected that macro generated code will call hidden functions of its
containing library (for performance reasons). One example of this is
`Logger.info/2` (v1.9.4) in the standard library will call
`Logger.__should_log__/2` which is `@doc false`. Since the compiler tracing runs
after macros generate code, calling a macro like `Logger.info/2` would result in
a warning since the generated code calls a hidden function. In order to not
raise false positives on such code, PrivCheck ignores any lines that call a
remote macro.

## Known Issues

* Doesn't currently work for umbrella projects

## Related Concepts and Libraries

* Boundary: manage and restrain cross-module dependencies:
  https://github.com/sasa1977/boundary/
  * Was an inspiration for much of this library and can be used alongside
* Dialyzer `@opaque` types: a way to define that a specific struct or datatype
  should not be used outside of the module that it was defined in.
  * https://hexdocs.pm/elixir/typespecs.html#user-defined-types
  * https://hexdocs.pm/elixir/Kernel.html#defstruct/1-types
* Built-in private modules proposal:
  https://elixirforum.com/t/proposal-private-modules-general-discussion/19374/1
* Jose Valim's experiment in adding `defmodulep`: https://github.com/josevalim/defmodulep
