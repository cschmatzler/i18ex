defmodule Idiom.Cache do
  @cache_table_name :idiom_cache

  def cache_table_name, do: @cache_table_name

  def init(local_data \\ %{}, table_name \\ @cache_table_name) do
    :ets.new(table_name, [:named_table, read_concurrency: true])

    local_data
    |> map_to_cache_data()
    |> Enum.each(fn {key, value} -> :ets.insert(table_name, {key, value}) end)
  end

  def insert_keys(keys, table_name \\ @cache_table_name) do
    Enum.each(keys, fn {key, value} ->
      :ets.insert(table_name, {key, value})
    end)
  end

  def get_key(cache_key, table_name \\ @cache_table_name) do
    case :ets.lookup(table_name, cache_key) do
      [{^cache_key, translation}] -> translation
      [] -> nil
    end
  end

  def get_translation(language, namespace, key, table_name \\ @cache_table_name) do
    to_cache_key(language, namespace, key)
    |> get_key(table_name)
  end

  def to_cache_key(language, namespace, key), do: "#{language}:#{namespace}:#{key}"

  # Input: %{en: %{translation: %{"foo.baz" => "bar"}}, de: %{login: %{bar: "baz", foo: %{bar: "baz"}}}}}}
  # Output: %{"en:translation:foo.baz" => "bar", "de:login:bar" => "baz", "de:login:foo.bar" => "baz"}
  def map_to_cache_data(map, acc \\ %{}, prefix \\ "", depth \\ 0) do
    Enum.reduce(map, acc, fn {key, value}, acc ->
      separator = if depth < 3, do: ":", else: "."
      new_key = if prefix == "", do: to_string(key), else: prefix <> separator <> to_string(key)

      case value do
        %{} ->
          map_to_cache_data(value, acc, new_key, depth + 1)

        _ ->
          Map.put(acc, new_key, value)
      end
    end)
  end
end
