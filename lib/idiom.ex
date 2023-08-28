defmodule Idiom do
  @moduledoc """
  A new take on internationalisation in Elixir.

  ## Basic usage

  ```elixir
  # Set the locale
  Idiom.put_locale("en-US")

  t("landing.welcome")

  # With natural language key
  t("Hello Idiom!")

  # With interpolation
  t("Good morning, {{name}}. We hope you are having a great day.", %{name: "Tim"})

  # With plural and interpolation
  # `count` is a magic option that automatically is available as binding.
  t("You need to buy {{count}} carrots", count: 1)

  # With namespace
  t("Create your account", namespace: "signup")
  Idiom.put_namespace("signup")
  t("Create your account")

  # With explicit locale
  t("Create your account", to: "fr")

  # With fallback key
  t(["Create your account", "Register"])

  # With fallback locale
  t("Create your account", to: "fr", fallback: "en")
  ```

  Also check out the [Cheatsheet](cheatsheet.html)!

  ## Installation

  To start off, add `idiom` to the list of your dependencies:
  ```elixir
  def deps do
    {:idiom, "~> 0.1"},
  end
  ```

  Additionally, in order to be able refresh translations in the background, add Idiom's `Supervisor` to your application:
  ```elixir
  def start(_type, _args) do
    children = [
      Idiom,
    ]

    # ...
  end
  ```

  ## Configuration

  There are a few things around Idiom that you can configure on an application level. The following fence shows all of Idiom's settings and their defaults.

  ```elixir
  config :idiom,
    default_locale: "en",
    default_fallback: "en",
    default_namespace: "default",
    data_dir: "priv/idiom",
    backend: nil
  ```

  In order to configure your backend, please have a look at its module documentation.  

  ## Locales

  When calling `t/3`, Idiom looks at the following settings to determine which locale to translate the key to, in order of priority:

  1. The explicit `to` option. When you call `t("key", to: "fr")`, Idiom will always use `fr` as a locale.
  2. The locale set in the current process. You can call `Idiom.put_locale/1` to set it.
  Since this is just a wrapper around the process dictionary, it needs to be set for each process you are using Idiom in.
  3. The `default_locale` setting. See the [Configuration](#module-configuration) section for more details on how to set it.

  ### Resolution hierarchy

  > #### A note on examples {: .info}
  >
  > For ease of presentation, whenever an example in this module documentation includes a translation file for context, it will be merged from the multiple
  > files that `Idiom.Source.Local` actually expects. Instead of giving you the contents of all `en/default.json`, `en-US/default.json`, `en-GB/default.json`
  > and others, it will be represented here as one merged file, such as:
  > ```json
  > { 
  >   "en": {"default": { [Contents of what would usually be `en/default.json` ] }},
  >   "en-US": {"default": { [Contents of what would usually be `en-US/default.json` ] }},
  >   ...
  > }
  > ```

  Locale codes can consist of multiple parts. Taking `zh-Hant-HK` as an example, we have the language (`zh` - Chinese), the script (`Hant`, Tradtional) and the
  region (`HK` - Hong Kong). For different regions, there might only be differences for some specific keys, whereas all other keys share a translation. In
  order to prevent needless repetition in your translation workflow, Idiom will always try to resolve translations in all of language, language and script, and
  language, script and region variants, in order of specifity.

  Taking the following file as an example (see also [File format](#module-file-format)):
  ```json
  {
    "en": {
      "default": {
        "Create your account": "Create your account"
      }
    },
    "en-US": {
      "default": {
        "Take the elevator": "Take the elevator"
      }
    },
    "en-GB": {
      "default": {
        "Take the elevator": "Take the lift"
      }
    }
  }
  ```
  The `Create your account` message is the same for both American and British English, whereas the key `Take the elevator` has different wording for each.
  With Idiom's resolution hierarchy, you can use both `en-US` and `en-GB` to refer to the `Create your account` key as well.

  ```elixir
  t("Take the elevator", to: "en-US")
  # -> Take the elevator
  t("Take the elevator", to: "en-GB")
  # -> Take the lift
  # Will first try to resolve the key in the `en-US` locale, then, since it does not exist, try `en`.
  t("Create your account", to: "en-US")
  # -> Create your account
  t("Create your account", to: "en-GB")
  # -> Create your account
  ```

  ### Fallback keys

  For scenarios where multiple keys might apply, `t/3` allows specifying a list of keys as well.

  ```elixir
  t(["Create your account", "Register"], to: "en-US")
  ```

  This snippet will first try to resolve the `Create your account` key, and fall back to resolving `Register` when it does not exist.

  ### Fallback locales

  For when a key might not be available in the set locale, you can set a fallback locale.  
  A fallback can be either a string or a list of strings. If you set the fallback as a list, Idiom will return the translation of the first locale for which
  the key is available.

  When you don't explicitly set a `fallback` for `t/3`, Idiom will try the `default_fallback` (see [Configuration](#module-configuration)).
  When a key is available in neither the target **or** any of the fallback language, the key will be returned as-is.


  ```elixir
  # will return the translation for `en`
  t("Key that is only available in `en` and `fr`", to: "es", fallback: "en")
  # will return the translation for `fr`
  t("Key that is only available in `en` and `fr`", to: "es", fallback: ["fr", "en"])
  # will return the translation for `en`, which is set as `default_fallback`
  t("Key that is only available in `en` and `fr`", to: "es")
  # will return "Key that is not available in any locale"
  t("Key that is not available in any locale", to: "es")
  ```

  ### Using fallback keys and locales together

  When both fallback keys and locales are provided, Idiom will first try to resolve all keys in each locale before jumping to the next one.  
  For example, the resolution order for `t(["Create your account", "Register"], to: "es", fallback: ["fr", "de"])` will be:

  1. `Create your account` in `es`
  2. `Register` in `es`
  3. `Create your account` in `fr`
  4. `Register` in `fr`
  5. `Create your account` in `de`
  6. `Register` in `de`

  ## Namespaces

  Idiom allows grouping your keys into namespaces.

  When calling `t/3`, Idiom looks at the following settings to determine which namespace to resolve the key in, in order of priority:
  1. The `namespace` option, like `t("Create your account", namespace: "signup")`
  2. The namespace set in the current process. You can call `Idiom.put_namespace/1` to set it.  
  Since this is just a wrapper around the process dictionary, it needs to be set for each process you are using Idiom in.
  3. The `default_namespace` setting. See the [Configuration](#module-configuration) section for more details on how to set it.

  ## Interpolation

  Idiom supports interpolation in messages.  
  Interpolation can be added by adding an interpolation key to the message, enclosing it in `{{}}`. Then, you can bind the key to any string by passing it as
  key inside the second parameter of `t/3`.

  Taking the following file as an example (see also [File format](#module-file-format)):
  ```json
  {
    "en": {
      "default": {
        "Welcome, {{name}}": "Welcome, {{name}}",
        "It is currently {{temperature}} degrees in {{city}}": "It is currently {{temperature}} degrees in {{city}}"
      }
    }
  }
  ```

  These messages can then be interpolated as such:

  ```elixir
  t("Welcome, {{name}}", %{name: "Tim"})
  # -> Welcome, Tim
  t("It is currently {{temperature}} degrees in {{city}}", %{temperature: "31", city: "Hong Kong"})
  # -> It is currently 31 degrees in Hong Kong
  ```

  ## Pluralisation

  Idiom supports the following key suffixes for pluralisation:

  - `zero`
  - `one`
  - `two`
  - `few`
  - `many`
  - `other`

  Your keys, for English, might then look like this:

  ```json
  {
    "carrot_one": "{{count}} carrot"
    "carrot_other": "{{count}} carrots"
  }
  ```

  You can then pluralise your messages by passing `count` to `t/3`, such as:

  ```elixir
  t("carrot", count: 1)
  # -> 1 carrot
  t("carrot", count: 2)
  # -> 2 carrot
  ```

  > #### `{{count}}` and pluralisation {: .info}
  >
  > As you can see in the above example, we are not passing an extra `%{count: x}` binding. This is because the `count` option acts as a magic binding that is
  > automatically available for interpolation.

  ## Backends

  Idiom is designed to be extensible with multiple over the air providers. Please see the modules in `Idiom.Backend` for the ones built-in, and always feel 
  free to extend the ecosystem by creating new ones.
  """

  import Idiom.Interpolation
  alias Idiom.Cache
  alias Idiom.Locales
  alias Idiom.Plural
  require Logger

  @doc false
  defmacro __using__(_opts) do
    quote do
      @before_compile Idiom.Compiler
    end
  end

  @doc false
  defdelegate child_spec(options), to: Idiom.Supervisor

  @type translate_opts() :: [
          namespace: String.t(),
          to: String.t(),
          fallback: String.t() | list(String.t()),
          count: integer() | float() | Decimal.t() | String.t(),
          cache_table_name: atom()
        ]

  @doc """
  Alias of `t/3` for when you don't need any bindings.
  """
  @spec t(String.t(), translate_opts()) :: String.t()
  def t(key, opts) when is_list(opts), do: t(key, %{}, opts)

  @doc """
  Translates a key into a target language.

  ## Examples

  ```elixir
  iex> Idiom.t("hello", to: "es")
  "hola"

  # With process-wide locale
  iex> Idiom.put_locale("fr")
  iex> Idiom.t("hello")
  "bonjour"

  # If neither `:to` option is provided nor `:lang` is set in the process, it will check the application configuration:
  # Given `config :idiom, default_lang: "en"` is set in the `config.exs` file:
  iex> Idiom.t("hello")
  "hello"

  # If a key does not exist in the target language, it will use the `:fallback` option:
  iex> Idiom.t("hello", to: "de", fallback: "fr")
  "bonjour"

  # If a key does not exist in the target language or the first fallback language:
  iex> Idiom.t("hello", to: "de", fallback: ["pl", "fr"])
  "bonjour"
  ```
  """

  @spec t(String.t(), map(), translate_opts()) :: String.t()
  def t(key_or_keys, bindings \\ %{}, opts \\ []) do
    locale = Keyword.get(opts, :to) || get_locale()
    namespace = Keyword.get(opts, :namespace) || get_namespace()
    fallback = Keyword.get(opts, :fallback) || Application.get_env(:idiom, :default_fallback) || "en"
    count = Keyword.get(opts, :count)
    bindings = Map.put_new(bindings, :count, count)

    locale_resolve_hierarchy =
      [locale | List.wrap(fallback)]
      |> Enum.map(&Locales.get_hierarchy/1)
      |> List.flatten()

    lookup_keys =
      Enum.reduce(locale_resolve_hierarchy, [], fn locale, acc ->
        acc ++
          (List.wrap(key_or_keys)
           |> Enum.flat_map(fn key ->
             [{locale, namespace, key}, {locale, namespace, "#{key}_#{Plural.get_suffix(locale, count)}"}]
           end))
      end)

    cache_table_name = Keyword.get(opts, :cache_table_name, Cache.cache_table_name())

    fallback_message = List.wrap(key_or_keys) |> List.first()

    Enum.find_value(lookup_keys, fallback_message, fn {locale, namespace, key} -> Cache.get_translation(locale, namespace, key, cache_table_name) end)
    |> interpolate(bindings)
  end

  @doc """
  Returns the locale that will be used by `t/3`.

  ## Examples

  ```elixir
  iex> Idiom.get_locale()
  "en"
  ```
  """
  @spec get_locale() :: String.t()
  def get_locale() do
    Process.get(:idiom_locale) || Application.get_env(:idiom, :default_locale) || "en"
  end

  @doc """
  Sets the locale for the current process.

  ## Examples

  ```elixir
  iex> Idiom.put_locale("fr-FR")
  "fr-FR"
  ```
  """
  @spec put_locale(String.t()) :: String.t()
  def put_locale(locale) when is_binary(locale) do
    Process.put(:idiom_locale, locale)

    locale
  end

  @doc """
  Returns the namespace that will be used by `t/3`.

  ## Examples

  ```elixir
  iex> Idiom.get_namespace()
  "default"
  ```
  """
  @spec get_namespace() :: String.t()
  def get_namespace() do
    Process.get(:idiom_namespace) || Application.get_env(:idiom, :default_namespace) || "default"
  end

  @doc """
  Sets the namespace for the current process.

  ## Examples

  ```elixir
  iex> Idiom.put_namespace("signup")
  "signup"
  ```
  """
  @spec put_namespace(String.t()) :: String.t()
  def put_namespace(namespace) when is_binary(namespace) do
    Process.put(:idiom_namespace, namespace)

    namespace
  end
end
