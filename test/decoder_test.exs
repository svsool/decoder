defmodule DecoderTest do
  use ExUnit.Case, async: true

  alias Decoder, as: D

  test "decode/2 should decode value" do
    # unknown derive
    assert {:error, [%{message: "unknown derive :unknown"}]} =
             D.decode(D.string(derive: [:unknown]), "Bruce")

    # decodes string
    assert {:ok, "Bruce"} = D.decode(D.string(), "Bruce")
    assert {:ok, "abc"} = D.decode(D.string(~r/abc/), "abc")

    # custom string format
    assert {:ok, ["value1", "value2"]} =
             D.decode(
               D.string(
                 derive: [{:format, fn val, _path -> {:ok, val |> String.split(",")} end}]
               ),
               "value1,value2"
             )

    # decodes date-time
    assert {:ok, DateTime.from_iso8601("2021-08-10T00:00:00Z") |> elem(1)} ==
             D.decode(D.string(derive: [{:format, "date-time"}]), "2021-08-10T00:00:00Z")

    assert {:ok, DateTime.from_iso8601("2023-11-14T22:13:20Z") |> elem(1)} ==
             D.decode(D.integer(derive: [{:format, "date-time"}]), 1_700_000_000)

    assert {:ok, DateTime.from_iso8601("2023-11-14T22:13:20.000Z") |> elem(1)} ==
             D.decode(
               D.integer(derive: [{:format, "date-time", :millisecond}]),
               1_700_000_000_000
             )

    # decodes & trims string
    assert {:ok, "Bruce"} = D.decode(D.string(derive: [:trim]), " Bruce ")

    # decodes integer
    assert {:ok, 30} = D.decode(D.integer(), 30)

    assert {:ok, 30} =
             D.decode(D.integer(derive: [{:gt, 15}, {:lt, 35}, {:gte, 30}, {:lte, 30}]), 30)

    # decodes map
    assert {:ok, %{"name" => "Bruce", "age" => 30}} ===
             D.decode(
               D.map(%{
                 "name" => D.string(),
                 "age" => D.integer()
               }),
               %{
                 "name" => "Bruce",
                 "age" => 30
               }
             )

    # decodes map and omits extra props
    assert {:ok, %{"name" => "Bruce", "age" => 30}} ===
             D.decode(
               D.map(
                 %{
                   "name" => D.string(),
                   "age" => D.integer()
                 },
                 extra_props: false
               ),
               %{
                 "name" => "Bruce",
                 "age" => 30,
                 "extra" => "extra"
               }
             )

    # decodes map in strict mode
    assert {:ok, %{"name" => "Bruce", "age" => 30}} ===
             D.decode(
               D.map(
                 %{
                   "name" => D.string(),
                   "age" => D.integer()
                 },
                 strict: true
               ),
               %{
                 "name" => "Bruce",
                 "age" => 30
               }
             )

    # decodes empty map in strict mode
    assert {:ok, %{}} =
             D.decode(
               D.map(
                 %{},
                 strict: true
               ),
               %{}
             )

    # decodes record
    assert {:ok,
             %{
               "k1" => "v1",
               "k2" => "v2"
             }} =
             D.decode(
               D.record(
                 D.string(),
                 D.string()
               ),
               %{
                 "k1" => "v1",
                 "k2" => "v2"
               }
             )

    # decodes tuple, support both list and tuple
    assert {:ok, {"Bruce", 30}} = D.decode(D.tuple([D.string(), D.integer()]), {"Bruce", 30})
    assert {:ok, ["Bruce", 30]} = D.decode(D.tuple([D.string(), D.integer()]), ["Bruce", 30])

    # decodes optionals
    assert {:ok, nil} = D.decode(D.optional(D.string()), nil)
    assert {:ok, ""} = D.decode(D.optional(D.string()), "")
    assert {:ok, []} = D.decode(D.optional(D.list(D.string())), [])
    assert {:ok, nil} = D.decode(D.optional(D.list(D.string())), nil)

    assert {:ok, %{"k" => "v"}} =
             D.decode(D.optional(D.map(%{"k" => D.string()})), %{"k" => "v"})

    # decodes list
    assert {:ok, ["Bruce", "Wayne"]} = D.decode(D.list(D.string()), ["Bruce", "Wayne"])

    # decodes nested list
    assert {:ok,
             [
               %{
                 "name" => "Bruce Wayne",
                 "activities" => ["fighting", "detective", "billionaire", "philanthropist"]
               }
             ]} =
             D.decode(
               D.list(D.map(%{"name" => D.string(), "activities" => D.list(D.string())})),
               [
                 %{
                   "name" => "Bruce Wayne",
                   "activities" => ["fighting", "detective", "billionaire", "philanthropist"]
                 }
               ]
             )

    # decodes union
    assert {:ok, "Bruce"} = D.decode(D.union([D.string(), D.integer()]), "Bruce")

    # decodes boolean
    assert {:ok, true} = D.decode(D.boolean(), true)
    assert {:ok, false} = D.decode(D.boolean(), false)

    # decodes literal
    assert {:ok, "Bruce"} = D.decode(D.literal("Bruce"), "Bruce")

    # decodes any
    assert {:ok, "Bruce"} = D.decode(D.any(), "Bruce")

    # decodes nil
    assert {:ok, nil} = D.decode(D.nil!(), nil)

    # decodes atom
    assert {:ok, :test} = D.decode(D.atom(), :test)
  end

  test "decode/2 should return decode error" do
    # fails decoding string
    assert {:error, [%{message: "not a string"}]} = D.decode(D.string(), 30)
    assert {:error, [%{message: "should match ~r/deaf/"}]} = D.decode(D.string(~r/deaf/), "abc")

    assert {:error, [%{message: "should match ~r/deaf/", description: "test"}]} =
             D.decode(D.string(~r/deaf/, description: "test"), "abc")

    assert {:error, [%{message: "should be longer than 5"}]} =
             D.decode(D.string(derive: [:trim, {:min, 5}]), "f")

    assert {:error, [%{message: "should be shorter than 5"}]} =
             D.decode(D.string(derive: [:trim, {:max, 5}]), "fairly long string")

    assert {:error, [%{message: "should not be empty"}]} =
             D.decode(D.string(derive: [:trim, :not_empty]), "  ")

    assert {:error, [%{message: "unknown options" <> _}]} =
             D.decode(D.string(extra_props: false), "  ")

    # fails with custom string format
    assert {:error, [%{message: "custom format failed"}]} =
             D.decode(
               D.string(
                 derive: [{:format, fn _val, _path -> {:error, "custom format failed"} end}]
               ),
               "value1,value2"
             )

    assert {:error,
             [
               %{
                 message: "error 1"
               },
               %{message: "error 2"}
             ]} =
             D.decode(
               D.string(
                 derive: [
                   {:format,
                     fn _val, _path -> {:error, [{:error, "error 1"}, {:error, "error 2"}]} end}
                 ]
               ),
               "value1,value2"
             )

    assert {:error,
             [
               %{
                 message: "format error: %ArgumentError{message: \"argument error\"}"
               }
             ]} =
             D.decode(
               D.string(derive: [{:format, fn _val, _path -> raise ArgumentError end}]),
               "value1,value2"
             )

    # fails decoding integer
    assert {:error, [%{message: "not an integer"}]} = D.decode(D.integer(), "Bruce")

    assert {:error, [%{message: "should be greater than 10"}]} =
             D.decode(D.integer(derive: [{:gt, 10}]), 5)

    assert {:error, [%{message: "should be lower than 5", description: "test"}]} =
             D.decode(D.integer(derive: [{:lt, 5}], description: "test"), 10)

    # fails decoding map
    assert {:error, [%{path: ["age"], message: "not an integer", description: "test"}]} =
             D.decode(
               D.map(%{
                 "name" => D.string(),
                 "age" => D.integer(description: "test")
               }),
               %{
                 "name" => "Bruce",
                 "age" => "30"
               }
             )

    # fails decoding map in strict mode
    assert {:error, [%{message: "extra properties not allowed in strict mode", path: ["extra"]}]} =
             D.decode(
               D.map(
                 %{
                   "name" => D.string(),
                   "age" => D.integer()
                 },
                 strict: true
               ),
               %{
                 "name" => "Bruce",
                 "age" => 30,
                 "extra" => "extra"
               }
             )

    # extra props and strict mode cannot be combined
    assert {:error,
             [
               %{
                 message:
                   "unknown options: [:extra_props] allowed [:strict, :derive, :description]"
               }
             ]} =
             D.decode(
               D.map(
                 %{
                   "name" => D.string(),
                   "age" => D.integer()
                 },
                 strict: true,
                 extra_props: true
               ),
               %{
                 "name" => "Bruce",
                 "age" => 30,
                 "extra" => "extra"
               }
             )

    # fails decoding map in strict mode
    assert {:error,
             [
               %{message: "extra properties not allowed in strict mode", path: ["extra"]}
             ]} = D.decode(D.map(%{}, strict: true), %{"extra" => "extra"})

    # fails decoding map and reports errors recursively
    assert {:error,
             [
               %{path: ["age"], message: "not a string"},
               %{path: ["name", "last_name"], message: "not a string", description: "test"}
             ]} =
             D.decode(
               D.map(%{
                 "name" =>
                   D.map(%{
                     "first_name" => D.string(),
                     "last_name" => D.string(description: "test")
                   }),
                 "age" => D.string()
               }),
               %{
                 "name" => %{
                   "first_name" => "Bruce",
                   "last_name" => 0xDEADBEEF
                 },
                 "age" => 30
               }
             )

    assert {:error, [%{message: "not a map", description: "test"}]} =
             D.decode(D.optional(D.map(%{"k" => D.string()}, description: "test")), 30)

    assert {:error,
             [
               %{message: "map properties should be a map"}
             ]} =
             D.decode(D.map("gibberish"), 30)

    assert {:error,
             [%{message: "string params should be a regex or a list of options", path: ["name"]}]} ===
             D.decode(
               D.map(%{
                 "name" => D.string("gibberish"),
                 "age" => D.integer()
               }),
               %{
                 "name" => "Bruce",
                 "age" => 30
               }
             )

    assert {:error, [%{message: "should be longer than 3"}]} =
             D.decode(
               D.map(
                 %{
                   "k1" => D.string(),
                   "k2" => D.string()
                 },
                 derive: [{:min, 3}]
               ),
               %{
                 "k1" => "v1",
                 "k2" => "v2"
               }
             )

    assert {:error, [%{message: "should be shorter than 2"}]} =
             D.decode(
               D.map(
                 %{
                   "k1" => D.string(),
                   "k2" => D.string()
                 },
                 derive: [{:max, 2}]
               ),
               %{
                 "k1" => "v1",
                 "k2" => "v2",
                 "k3" => "v3"
               }
             )

    assert {:error, [%{message: "should not be empty"}]} =
             D.decode(
               D.map(%{},
                 derive: [:not_empty]
               ),
               %{}
             )

    # fails decoding record
    assert {:error, [%{path: ["k2"], message: "not a string"}]} =
             D.decode(
               D.record(
                 D.string(),
                 D.string()
               ),
               %{
                 "k1" => "v1",
                 "k2" => 30
               }
             )

    assert {:error,
             [
               %{
                 message: "record key and value should be valid schemas"
               }
             ]} =
             D.decode(
               D.record(
                 "gibberish",
                 "gibberish"
               ),
               %{}
             )

    assert {:error, [%{message: "should be shorter than 1", description: "test"}]} =
             D.decode(
               D.record(
                 D.string(),
                 D.string(),
                 derive: [{:max, 1}],
                 description: "test"
               ),
               %{
                 "k1" => "v1",
                 "k2" => "v2"
               }
             )

    assert {:error, [%{message: "should be longer than 3"}]} =
             D.decode(
               D.record(
                 D.string(),
                 D.string(),
                 derive: [{:min, 3}]
               ),
               %{
                 "k1" => "v1",
                 "k2" => "v2"
               }
             )

    assert {:error, [%{message: "should not be empty"}]} =
             D.decode(
               D.record(
                 D.string(),
                 D.string(),
                 derive: [:trim, :not_empty]
               ),
               %{}
             )

    # fails decoding optionals
    assert {:error, [%{message: "not a string"}]} = D.decode(D.optional(D.string()), 30)
    assert {:error, [%{message: "not a list"}]} = D.decode(D.optional(D.list(D.string())), 30)

    # fails decoding optional with derive
    assert {:error, [%{message: "should not be empty", description: "test"}]} =
             D.decode(D.optional(D.string(derive: [:not_empty], description: "test")), "")

    # fails decoding list
    assert {:error, [%{message: "not a list", description: "test"}]} =
             D.decode(D.list(D.string(), description: "test"), "Bruce")

    # fails decoding nested list
    assert {:error, [%{path: [0, "activities", 0], message: "not a string", description: "test"}]} =
             D.decode(
               D.list(
                 D.map(%{
                   "name" => D.string(),
                   "activities" => D.list(D.string(description: "test"))
                 })
               ),
               [
                 %{
                   "name" => "Bruce Wayne",
                   "activities" => [30, "detective", "billionaire", "philanthropist"]
                 }
               ]
             )

    # fails decoding tuple
    assert {:error,
             [
               %{
                 message: "not an integer",
                 path: [1]
               }
             ]} = D.decode(D.tuple([D.string(), D.integer()]), ["Bruce", "30"])

    # fails decoding tuple with wrong schema
    assert {:error,
             [
               %{
                 message: "tuple items should be a list"
               }
             ]} = D.decode(D.tuple(D.string(), D.integer()), ["Bruce", "30"])

    # fails decoding tuple with wrong number of items
    assert {:error,
             [
               %{
                 message: "tuple length mismatch (actual) 1 != (expected) 2",
                 description: "test"
               }
             ]} = D.decode(D.tuple([D.string(), D.integer()], description: "test"), ["Bruce"])

    assert {:error,
             [
               %{
                 message: "tuple length mismatch (actual) 1 != (expected) 2"
               }
             ]} = D.decode(D.tuple([D.string(), D.integer()]), {"Bruce"})

    # fails decoding union
    assert {:error, [%{message: "not a string"}, %{message: "not an integer"}]} =
             D.decode(D.union([D.string(), D.integer()]), nil)

    # fails decoding boolean
    assert {:error,
             [
               %{
                 message: "not a boolean",
                 description: "test"
               }
             ]} = D.decode(D.boolean(description: "test"), "true")

    # fails decoding literal
    assert {:error,
             [
               %{
                 message: "literal mismatch (actual) \"Wayne\" != (expected) \"Bruce\"",
                 description: "test"
               }
             ]} =
             D.decode(D.literal("Bruce", description: "test"), "Wayne")

    # fails decoding nil
    assert {:error, [%{message: "not a nil"}]} = D.decode(D.nil!(), "nil")

    # fails when unknown options passed
    assert {:error, [%{message: "unknown options" <> _}]} =
             D.decode(D.string(unknown: 123), "Bruce")

    # fails when unknown options passed in nested map
    assert {:error, [%{message: "unknown options" <> _}]} =
             D.decode(D.map(%{"k1" => D.map(%{"k2" => D.string(unknown: 123)})}), %{
               "k1" => %{"k2" => "v2"}
             })

    # fails decoding date-time
    assert {:error, [%{message: "should be a valid date-time"}]} =
             D.decode(D.string(derive: [{:format, "date-time"}]), "2023-99-XYT25:61:90")

    # fails with unknown options
    assert {:error, [%{message: "unknown options: [:unknown] allowed [:derive, :description]"}]} =
             D.decode(D.string(unknown: :unknown), "Bruce")

    # fails decoding atom
    assert {:error, [%{message: "not an atom"}]} = D.decode(D.atom(), "test")
  end
end
