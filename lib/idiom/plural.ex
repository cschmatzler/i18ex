defmodule Idiom.Plural do
  import Idiom.PluralPreprocess
  alias Idiom.Locales
  require Logger

  @rules "priv/idiom"
         |> Path.join("/plurals.json")
         |> File.read!()
         |> Jason.decode!()
         |> get_in(["supplemental", "plurals-type-cardinal"])
         |> Enum.map(&parse_rules/1)
         |> Map.new()

  for {locale, rules} <- @rules do
    # Parameter | Value
    # ----------|------------------------------------------------------------------
    # n         | absolute value of the source number (integer/float/decimal).
    # i         | integer digits of n.
    # v         | number of visible fractional digits in n, with trailing zeros.
    # w         | number of visible fractional digits in n, without trailing zeros.
    # f         | visible fractional digits in n, with trailing zeros.
    # t         | visible fractional digits in n, without trailing zeros.
    defp get_suffix(unquote(locale), n, i, v, w, f, t) do
      e = 0
      _silence_unused_warnings = {n, i, v, w, f, t, e}
      unquote(rules)
    end
  end

  defp get_suffix(locale, _n, _i, _v, _w, _f, _t) do
    Logger.warning("No plural rules found for #{locale} - returning `other`")
    "other"
  end

  def get_suffix(locale, count)
  def get_suffix(_locale, nil), do: "other"
  def get_suffix(locale, count) when is_binary(count), do: get_suffix(locale, Decimal.new(count))

  def get_suffix(locale, count) when is_float(count) do
    count = count |> Float.to_string() |> Decimal.new()
    get_suffix(locale, count)
  end

  def get_suffix(locale, count) when is_integer(count) do
    locale = Locales.to_language(locale)
    n = abs(count)
    i = abs(count)
    get_suffix(locale, n, i, 0, 0, 0, 0)
  end

  def get_suffix(locale, count) do
    n = Decimal.abs(count)
    i = Decimal.round(count, 0, :floor) |> Decimal.to_integer()
    v = abs(n.exp)

    mult = Integer.pow(10, v) |> Decimal.new()

    f =
      n
      |> Decimal.sub(i)
      |> Decimal.mult(mult)
      |> Decimal.round(0, :floor)
      |> Decimal.to_integer()

    t =
      Integer.to_string(f)
      |> String.trim_trailing("0")
      |> case do
        "" -> 0
        other -> Decimal.new(other) |> Decimal.to_integer()
      end

    w =
      Integer.to_string(f)
      |> String.trim_trailing("0")
      |> String.length()

    get_suffix(Locales.to_language(locale), Decimal.to_float(n), i, v, f, t, w)
  end

  defp in?(%Decimal{} = number, range) do
    Decimal.to_float(number) |> in?(range)
  end

  defp in?(number, range) when is_integer(number) do
    number in range
  end

  defp in?(number, range) when is_float(number) do
    trunc(number) in range
  end

  defp mod(dividend, divisor) when is_float(dividend) and is_number(divisor) do
    dividend - Float.floor(dividend / divisor) * divisor
  end

  defp mod(dividend, divisor) when is_integer(dividend) and is_integer(divisor) do
    modulo =
      dividend
      |> Integer.floor_div(divisor)
      |> Kernel.*(divisor)

    dividend - modulo
  end

  defp mod(dividend, divisor) when is_integer(dividend) and is_number(divisor) do
    modulo =
      dividend
      |> Kernel./(divisor)
      |> Float.floor()
      |> Kernel.*(divisor)

    dividend - modulo
  end

  defp mod(%Decimal{} = dividend, %Decimal{} = divisor) do
    modulo =
      dividend
      |> Decimal.div(divisor)
      |> Decimal.round(0, :floor)
      |> Decimal.mult(divisor)

    Decimal.sub(dividend, modulo)
  end

  defp mod(%Decimal{} = dividend, divisor) when is_integer(divisor), do: mod(dividend, Decimal.new(divisor))
end
