# Idiom - a modern internationalisation library

Idiom is an internationalisation library for Elixir. Its goal is to be simple, yet flexible, with interchangeable sources. At a base level, it supports
reading translations from the local file system at application startup. It also comes with a few (well… not yet) over-the-air sources that are continuously
updated in the back, so you can update your application's translations without having to deploy anything.

> #### Stability notice
>
> This is currently nowhere near stable. I'm messing around with different APIs, the documentation is incomplete, and some modules are missing proper tests.
> I would appreciate feedback on the current API and notes on where I could improve existing documentation, but please don't use this right now.

## Features

- Reading localisation files from the file system (see [Local](#local))
- Fetching translations from third-party services (see [Over-the-air](#over-the-air))
- Pluralisation
- Interpolation

## Installation

Add `idiom` to your `mix.exs`:

```elixir
deps = [
…
    {:idiom, "0.1.1"}
…
]
```

Then start it with your application (most likely in an `application.ex`, but it can also be added to a `Supervisor` manually):

```elixir
…
def start(_type, _args) do
children = [
    Idiom,
…
]
…
```

Depending on which source you decide to add, you might also need to configure it specifically. Please see the source's module documentation.

## Configuration

The default locale and fallback can be set in `config.exs`:

```
config :idiom,
    default_locale: "fr",
    default_fallback: "en"
```

These defaults will be used when the option isn't passed to either `t` itself or set in the process dictionary.

## Basic usage

The main way you are going to interact with Idiom is its `t` function.

```elixir
t("key", to: "en")
t("namespace:key", to: "en-US")
t("key", to: "de", fallback: "en-US")
t("key", to: "de", fallback: ["en-US"])
t("key with {{interpolation}}", %{interpolation: "foo"}, to: "de", fallback: ["en-US"])
t("key with plural", to: "ar", count: 5)
```

For the `to` and `fallback` options, Idiom also supports setting them through the process dictionary.
```elixir
Process.put(:locale, "en-US")
t("key")
Process.put(:fallback, "fr")
t("key.that.does.not.have.an.english.translation")
```

### Languages, locales and scripts

Idiom automatically builds a hierarchy to resolve a given key. Assuming your user has set their locale to `en-US`, but you don't differentiate between regions 
(or scripts) in your translation files and only offer an `en` locale, this will be handled automatically. For a translation that is requested with
`to: "en-Latn-US"`, Idiom will try to resolve the key for `en-Latn-US`, `en-Latn` and finally `en`, returning the first that exists.

### Plurals

For translations that have different versions based on a plural count, Idiom supports those using the 
[Unicode CLDR Plural Rules](https://cldr.unicode.org/index/cldr-spec/plural-rules) specification. In detail, this means that keys in your translation files 
should offer the following suffixes for translations that support pluralization:

- `zero`
- `one`
- `two`
- `few`
- `many`
- `other`

You can then pass a `count` to `t`. `count` can be an integer, string, float or `Decimal`.

## Interpolation

Idiom also supports interpolation in your translations. Variables can be marked inside `{{}}`, for example `Hello, {{name}}`.  
You can then pass bindings to `t` as second parameter, such as `t("Hello, {{name}}!", %{name: "world"}, to: "de")`.  
If the variable has no binding, it will be left as-is, without the braces: `t("Hello, {{name}}!", %{}, to: "en")` results in `Hello, name!`.

## Sources

### Local

Idiom by default automatically loads files from the file system on startup. These are placed in your `priv/idiom/` directory, although you can change the
directory in your `config.exs`:

```elixir
config :idiom, Idiom.Source.Local,
    data_dir: "priv/idiom/"
```

#### Directory structure

The `Local` source expects its data directory to follow this directory structure:

```
priv/idiom
└── en
   ├── default.json
   └── login.json
```

where `en` is the locale and `default` and `login` are namespaces separating the keys.

#### File format

The `json` files roughly follow the [i18next format](https://www.i18next.com/misc/json-format), with not all of its features supported. The following example
shows all of its features that Idiom currently supports.

```json
{
  "key": "value",
  "keyDeep": {
    "inner": "value"
  },
  "keyInterpolate": "replace this {{value}}",
  "keyPluralSimple_one": "the singular",
  "keyPluralSimple_other": "the plural",
  "keyPluralMultipleEgArabic_zero": "the plural form 0",
  "keyPluralMultipleEgArabic_one": "the plural form 1",
  "keyPluralMultipleEgArabic_two": "the plural form 2",
  "keyPluralMultipleEgArabic_few": "the plural form 3",
  "keyPluralMultipleEgArabic_many": "the plural form 4",
  "keyPluralMultipleEgArabic_other": "the plural form 5",
  "keyWithObjectValue": {
    "valueA": "return this with valueB",
    "valueB": "more text"
  }
}
```

## Over-the-air

### [Phrase Strings](https://phrase.com)

...
