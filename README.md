# Decoder

Schema-first validation library for Elixir.

Usage examples can be found in the [tests](./test/decoder_test.exs).

## Installation

```elixir
def deps do
  [
    {:decoder, "~> 0.1.0"}
  ]
end
```

## Types

- `map`, `record`, `tuple`, `list`
- `string`, `integer`, `boolean`, `any`, `nil`, `atom`, `literal`
- `union`, `optional`

## Options

- `description` - field error description
- `extra_props` - omit/include extra props
- `strict` - strict mode

Example: 

```elixir
assert {:ok, %{"name" => "Bruce Wayne", "age" => 30}} ===
 D.decode(
   D.map(
     %{
       "name" => D.string(),
       "age" => D.integer()
     },
     extra_props: false
   ),
   %{
     "name" => "Bruce Wayne",
     "age" => 30,
     "extra" => "extra"
   }
 )
```

## Derives

Derives can sanitize, validate and format data.

- `trim`
- `gt`, `gte`, `lt`, `lte`
- `min`, `max`
- `not_empty`
- `format`

Examples:

```elixir
assert {:ok, "Alfred Pennyworth"} = D.decode(D.string(derive: [:trim]), " Alfred Pennyworth ")

assert {:ok, DateTime.from_iso8601("2021-08-10T00:00:00Z") |> elem(1)} ==
             D.decode(D.string(derive: [{:format, "date-time"}]), "2021-08-10T00:00:00Z")

assert {:error, [%{message: "should be longer than 5"}]} =
             D.decode(D.string(derive: [:trim, {:min, 5}]), "f")

assert {:error, [%{message: "should not be empty"}]} =
             D.decode(D.string(derive: [:trim, :not_empty]), "  ")
```


