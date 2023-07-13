defmodule I18ex.Backends.File do
  @behaviour I18ex.Backend

  def list_namespaces() do
    ["default"]
  end

  def get_namespace("default") do
    %{
      "key" => "value",
      "keyDeep" => %{
        "inner" => "value"
      },
      "keyNesting" => "reuse $t(keyDeep.inner)",
      "keyInterpolate" => "replace this {{value}}",
      "keyInterpolateUnescaped" => "replace this {{- value}}",
      "keyInterpolateWithFormatting" => "replace this {{value, format}}",
      "keyContext_male" => "the male variant",
      "keyContext_female" => "the female variant",
      "keyPluralSimple_one" => "the singular",
      "keyPluralSimple_other" => "the plural",
      "keyPluralMultipleEgArabic_zero" => "the plural form 0",
      "keyPluralMultipleEgArabic_one" => "the plural form 1",
      "keyPluralMultipleEgArabic_two" => "the plural form 2",
      "keyPluralMultipleEgArabic_few" => "the plural form 3",
      "keyPluralMultipleEgArabic_many" => "the plural form 4",
      "keyPluralMultipleEgArabic_other" => "the plural form 5",
      "keyWithArrayValue" => ["multipe", "things"],
      "keyWithObjectValue" => %{"valueA" => "return this with valueB", "valueB" => "more text"}
    }
  end
end
