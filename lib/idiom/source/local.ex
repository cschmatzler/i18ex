defmodule Idiom.Source.Local do
  @moduledoc """
  Local source for Idiom.

  While Idiom supports over-the-air sources, it also always loads from the local filesystem. This prevents from the application missing messages entirely
  when the OTA source is not reachable. For this reason, you should always have a somewhat recent version of your translations exported and bundled with your
  release.

  ## Directory structure

  You can set the data directory changing the `:data_dir` setting of `Idiom.Source.Local` as such:

  ```elixir
  config :idiom, Idiom.Source.Local,
    data_dir: "priv/idiom"
  ```

  Inside that directory, the structure should be as follows:

  ```
  priv/idiom
  └── en
    ├── default.json
    └── login.json
  ```

  Where `en` is the target locale and `default` and `login` are namespaces.

  ## File format

  The `json` files expected by `Idiom.Source.Local` are a subset of the [i18next format](https://www.i18next.com/misc/json-format). The following example shows 
  all of its features that Idiom currently supports.

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
  }
  ```
  """
  require Logger

  @doc """
  Parses all local data.
  """
  def data(opts \\ []) do
    data_dir =
      Keyword.get(opts, :data_dir) ||
        Application.get_env(:idiom, __MODULE__)[:data_dir]

    Path.join(data_dir, "**/*.json")
    |> Path.wildcard()
    |> Enum.map(&parse_file/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.reduce(%{}, fn keys, acc -> Map.merge(keys, acc) end)
  end

  defp parse_file(path) do
    with {:ok, contents} <- File.read(path),
         {:ok, map} <- Jason.decode(contents),
         {lang, domain} <- extract_lang_and_domain(path) do
      [{lang, Map.new([{domain, map}])}]
      |> Map.new()
    else
      {:error, _error} ->
        Logger.warning("Could not parse file #{path}")
        nil
    end
  end

  defp extract_lang_and_domain(path) do
    path
    |> String.split("/")
    |> Enum.reverse()
    |> Enum.take(2)
    |> Enum.map(&Path.rootname/1)
    |> Enum.reverse()
    |> List.to_tuple()
  end
end
