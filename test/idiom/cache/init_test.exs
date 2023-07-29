defmodule Idiom.Cache.InitTest do
  use ExUnit.Case, async: true
  alias Idiom.Cache

  test "initializes a public ETS with read concurrency table" do
    Cache.init()
    info = :ets.info(Cache.cache_table_name())

    assert %{
             protection: :public,
             read_concurrency: true
           } = Map.new(info)
  end

  test "allows changing the name from default table" do
    Cache.init(%{}, :test_table)

    assert :ets.info(:test_table) != :undefined
  end

  test "allows setting initial data" do
    data = File.read!("test/data.json") |> Jason.decode!()

    Cache.init(data)

    assert Map.new(:ets.tab2list(Cache.cache_table_name())) == %{
             "en:translations:foo" => "bar",
             "en:translations:deep.foo" => "Deep bar",
             "en:translations:Natural language: the colon-ing" => "Colons",
             "en:translations:carrot_one" => "1 carrot",
             "en:translations:carrot_other" => "{{count}} carrots",
             "de:default:butterfly" => "Schmetterling"
           }
  end
end
