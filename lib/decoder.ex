defmodule Decoder do
  @spec decode(map(), any(), Keyword.t()) :: {:ok, any()} | {:error, binary() | list()}
  def decode(schema, input, options \\ []) do
    case options do
      [] ->
        do_decode(schema, input, _path = [], _errors = [])

      # allow inheriting parent path given nested decodes
      [path: path] ->
        do_decode(schema, input, path, _errors = [])

      _ ->
        {:error, "unknown decode options: #{inspect(options)} allowed [:path]"}
    end
  rescue
    error ->
      {:error, "decode error: #{inspect(error)}"}
  end

  @spec map(map(), Keyword.t()) :: map() | {:error, binary()}
  def map(properties, options \\ [])

  @spec map(map(), Keyword.t()) :: map() | {:error, binary()}
  def map(properties, options) when is_map(properties) do
    schema = %{
      type: :map,
      properties: properties
    }

    case verify_options(schema, options) do
      {:ok, verified_options} ->
        schema |> Map.put(:options, verified_options)

      {:error, error} ->
        {:error, error}
    end
  end

  @spec map(any(), any()) :: {:error, binary()}
  def map(_, _) do
    {:error, "map properties should be a map"}
  end

  @spec record(map(), map(), Keyword.t()) :: map() | {:error, binary()}
  def record(key, value, options \\ [])

  @spec record(map(), map(), Keyword.t()) :: map() | {:error, binary()}
  def record(%{type: _key_type} = key, %{type: _value_type} = value, options) do
    schema = %{
      type: :record,
      key: key,
      value: value
    }

    case verify_options(schema, options) do
      {:ok, verified_options} ->
        schema |> Map.put(:options, verified_options)

      {:error, error} ->
        {:error, error}
    end
  end

  @spec record(any(), any(), any()) :: {:error, binary()}
  def record(_, _, _) do
    {:error, "record key and value should be valid schemas"}
  end

  @spec list(map(), Keyword.t()) :: map() | {:error, binary()}
  def list(item, options \\ [])

  @spec list(map(), Keyword.t()) :: map() | {:error, binary()}
  def list(%{type: _type} = item, options) do
    schema = %{
      type: :list,
      item: item
    }

    case verify_options(schema, options) do
      {:ok, verified_options} ->
        schema |> Map.put(:options, verified_options)

      {:error, error} ->
        {:error, error}
    end
  end

  @spec list(any(), any()) :: {:error, binary()}
  def list(_, _) do
    {:error, "list item should be a valid schema"}
  end

  @spec tuple(list(), Keyword.t()) :: map() | {:error, binary()}
  def tuple(items, options \\ [])

  @spec tuple(list(), Keyword.t()) :: map() | {:error, binary()}
  def tuple(items, options) when is_list(items) do
    schema = %{
      type: :tuple,
      items: items
    }

    case verify_options(schema, options) do
      {:ok, verified_options} ->
        schema |> Map.put(:options, verified_options)

      {:error, error} ->
        {:error, error}
    end
  end

  @spec tuple(any(), any()) :: {:error, binary()}
  def tuple(_, _) do
    {:error, "tuple items should be a list"}
  end

  @spec union(list(map()), Keyword.t()) :: map() | {:error, binary()}
  def union(values, options \\ [])

  def union(values, options) when is_list(values) and is_list(options) do
    schema = %{
      type: :union,
      values: values
    }

    case verify_options(schema, options) do
      {:ok, verified_options} ->
        schema |> Map.put(:options, verified_options)

      {:error, error} ->
        {:error, error}
    end
  end

  @spec union(any(), any()) :: {:error, binary()}
  def union(_, _) do
    {:error, "union values should be a list"}
  end

  @spec integer(Keyword.t()) :: map() | {:error, binary()}
  def integer(options \\ []) do
    schema = %{type: :integer}

    case verify_options(schema, options) do
      {:ok, verified_options} ->
        schema |> Map.put(:options, verified_options)

      {:error, error} ->
        {:error, error}
    end
  end

  @spec string(Regex.t()) :: map() | {:error, binary()}
  def string(regex) when is_struct(regex, Regex) do
    %{type: :string, regex: regex}
  end

  def string(options) when is_list(options) do
    schema = %{type: :string}

    case verify_options(schema, options) do
      {:ok, verified_options} ->
        schema |> Map.put(:options, verified_options)

      {:error, error} ->
        {:error, error}
    end
  end

  @spec string(any()) :: {:error, binary()}
  def string(_) do
    {:error, "string params should be a regex or a list of options"}
  end

  @spec string(Regex.t(), Keyword.t()) :: map() | {:error, binary()}
  def string(regex, options) when is_struct(regex, Regex) and is_list(options) do
    schema = %{type: :string, regex: regex}

    case verify_options(schema, options) do
      {:ok, verified_options} ->
        schema |> Map.put(:options, verified_options)

      {:error, error} ->
        {:error, error}
    end
  end

  @spec string(any(), any()) :: {:error, binary()}
  def string(_, _) do
    {:error, "string params should be a regex or a list of options"}
  end

  @spec string() :: map()
  def string do
    %{type: :string}
  end

  @spec boolean(Keyword.t()) :: map()
  def boolean(options \\ [])

  def boolean(options) when is_list(options) do
    schema = %{type: :boolean}

    case verify_options(schema, options) do
      {:ok, verified_options} ->
        schema |> Map.put(:options, verified_options)

      {:error, error} ->
        {:error, error}
    end
  end

  def boolean(_) do
    {:error, "boolean options should be a list"}
  end

  @spec optional(map()) :: map() | {:error, binary()}
  def optional(%{type: _type} = value) do
    %{type: :optional, value: value}
  end

  @spec optional(any()) :: {:error, binary()}
  def optional(_) do
    {:error, "optional value should be a valid schema"}
  end

  @spec literal(any(), Keyword.t()) :: map() | {:error, binary()}
  def literal(value, options \\ []) do
    schema = %{type: :literal, value: value}

    case verify_options(schema, options) do
      {:ok, verified_options} ->
        schema |> Map.put(:options, verified_options)

      {:error, error} ->
        {:error, error}
    end
  end

  @spec any(Keyword.t()) :: map()
  def any(options \\ [])

  def any(options) do
    schema = %{type: :any}

    case verify_options(schema, options) do
      {:ok, verified_options} ->
        schema |> Map.put(:options, verified_options)

      {:error, error} ->
        {:error, error}
    end
  end

  # "!" avoids conflicts with built-in nil
  @spec nil!(Keyword.t()) :: map()
  def nil!(options \\ [])

  def nil!(options) do
    schema = %{type: nil}

    case verify_options(schema, options) do
      {:ok, verified_options} ->
        schema |> Map.put(:options, verified_options)

      {:error, error} ->
        {:error, error}
    end
  end

  @spec atom(Keyword.t()) :: map()
  def atom(options \\ [])

  def atom(options) when is_list(options) do
    schema = %{type: :atom}

    case verify_options(schema, options) do
      {:ok, verified_options} ->
        schema |> Map.put(:options, verified_options)

      {:error, error} ->
        {:error, error}
    end
  end

  defp do_decode(
         %{type: :map, properties: properties, options: options} = schema,
         input,
         path,
         errors
       )
       when is_map(input) do
    extra_props = Keyword.get(options, :extra_props, true)
    strict = Keyword.get(options, :strict, false)

    input_keys = Map.keys(input)
    all_keys = (Map.keys(properties) ++ input_keys) |> Enum.uniq()

    {decoded_input, errors} =
      Enum.reduce(all_keys, {%{}, errors}, fn key, {result, errors} ->
        prop_schema = Map.get(properties, key)
        value = Map.get(input, key)

        cond do
          prop_schema == nil and strict === true ->
            {result,
              errors ++
              [format_error("extra properties not allowed in strict mode", path ++ [key])]}

          # additional property, not in schema, added by default as is
          prop_schema == nil and extra_props === true and not strict ->
            {Map.put(result, key, value), errors}

          prop_schema == nil and extra_props === false ->
            {result, errors}

          true ->
            case do_decode(prop_schema, value, path ++ [key], errors) do
              {:ok, decoded_value} ->
                if decoded_value == nil and key not in input_keys do
                  {result, errors}
                else
                  {Map.put(result, key, decoded_value), errors}
                end

              {:error, errors} ->
                {result, errors}
            end
        end
      end)

    if length(errors) > 0 do
      {:error, errors}
    else
      maybe_derive(schema, decoded_input, path, errors)
    end
  end

  defp do_decode(%{type: :map} = schema, _input, path, errors) do
    {:error, errors ++ [format_error("not a map", path, schema)]}
  end

  defp do_decode(
         %{
           type: :record,
           key: %{type: _key_type} = key_schema,
           value: %{type: _value_type} = value_schema
         } = schema,
         input,
         path,
         errors
       )
       when is_map(input) do
    {decoded_value, errors} =
      Enum.reduce(input, {%{}, errors}, fn {key, value}, {result, errors} ->
        key_decoded = do_decode(key_schema, key, path ++ [key], errors)
        value_decoded = do_decode(value_schema, value, path ++ [key], errors)

        case {key_decoded, value_decoded} do
          {{:ok, decoded_key}, {:ok, decoded_value}} ->
            {Map.put(result, decoded_key, decoded_value), errors}

          {{:error, errors}, _} ->
            {result, errors}

          {_, {:error, errors}} ->
            {result, errors}
        end
      end)

    if length(errors) > 0 do
      {:error, errors}
    else
      maybe_derive(schema, decoded_value, path, errors)
    end
  end

  defp do_decode(%{type: :record} = schema, _, path, errors) do
    {:error, errors ++ [format_error("not a record", path, schema)]}
  end

  defp do_decode(%{type: :list, item: %{type: _type} = item_schema} = schema, input, path, errors)
       when is_list(input) do
    {decoded_input, errors, _} =
      Enum.reduce(input, {[], errors, 0}, fn item, {result, errors, index} ->
        case do_decode(item_schema, item, path ++ [index], errors) do
          {:ok, decoded_item} ->
            {result ++ [decoded_item], errors, index + 1}

          {:error, errors} ->
            {result, errors, index + 1}
        end
      end)

    if length(errors) > 0 do
      {:error, errors}
    else
      maybe_derive(schema, decoded_input, path, errors)
    end
  end

  defp do_decode(%{type: :list} = schema, _, path, errors) do
    {:error, errors ++ [format_error("not a list", path, schema)]}
  end

  defp do_decode(%{type: :tuple, items: items} = schema, input, path, errors)
       when is_list(input) and length(items) == length(input) do
    {decoded_input, errors, _} =
      Enum.reduce(input, {[], errors, 0}, fn item, {result, errors, index} ->
        case do_decode(Enum.at(items, index), item, path ++ [index], errors) do
          {:ok, decoded_item} ->
            {result ++ [decoded_item], errors, index + 1}

          {:error, errors} ->
            {result, errors, index + 1}
        end
      end)

    if length(errors) > 0 do
      {:error, errors}
    else
      maybe_derive(schema, decoded_input, path, errors)
    end
  end

  defp do_decode(%{type: :tuple, items: items} = schema, input, path, errors)
       when is_tuple(input) and is_list(items) and length(items) == tuple_size(input) do
    {decoded_input, errors, _} =
      Enum.reduce(input |> Tuple.to_list(), {[], errors, 0}, fn item, {result, errors, index} ->
        case do_decode(Enum.at(items, index), item, path ++ [index], errors) do
          {:ok, decoded_item} ->
            {result ++ [decoded_item], errors, index + 1}

          {:error, errors} ->
            {result, errors, index + 1}
        end
      end)

    decoded_input = List.to_tuple(decoded_input)

    if length(errors) > 0 do
      {:error, errors}
    else
      maybe_derive(schema, decoded_input, path, errors)
    end
  end

  defp do_decode(%{type: :tuple, items: items} = schema, input, path, errors)
       when is_list(input) and length(items) != length(input) do
    {:error,
      errors ++
      [
        format_error(
          "tuple length mismatch (actual) #{length(input)} != (expected) #{length(items)}",
          path,
          schema
        )
      ]}
  end

  defp do_decode(%{type: :tuple, items: items} = schema, input, path, errors)
       when is_tuple(input) and length(items) != tuple_size(input) do
    {:error,
      errors ++
      [
        format_error(
          "tuple length mismatch (actual) #{tuple_size(input)} != (expected) #{length(items)}",
          path,
          schema
        )
      ]}
  end

  defp do_decode(%{type: :tuple} = schema, _, path, errors) do
    {:error, errors ++ [format_error("not a tuple or a list", path, schema)]}
  end

  defp do_decode(%{type: :union, values: values}, input, path, errors)
       when is_list(values) and length(values) > 0 do
    Enum.reduce_while(values, {:error, errors}, fn value_schema, {_, errors} ->
      case do_decode(value_schema, input, path, errors) do
        {:ok, decoded_input} ->
          {:halt, {:ok, decoded_input}}

        {:error, errors} ->
          {:cont, {:error, errors}}
      end
    end)
  end

  defp do_decode(%{type: :union} = schema, _, path, errors) do
    {:error, errors ++ [format_error("not a valid union", path, schema)]}
  end

  defp do_decode(%{type: :string} = schema, input, path, errors) when is_binary(input) do
    regex = Map.get(schema, :regex, nil)

    case regex do
      nil ->
        maybe_derive(schema, input, path, errors)

      _ when is_struct(regex, Regex) ->
        case Regex.match?(regex, input) do
          true ->
            maybe_derive(schema, input, path, errors)

          false ->
            {:error, errors ++ [format_error("should match #{inspect(regex)}", path, schema)]}
        end
    end
  end

  defp do_decode(%{type: :string} = schema, _, path, errors) do
    {:error, errors ++ [format_error("not a string", path, schema)]}
  end

  defp do_decode(%{type: :literal, value: value} = schema, input, path, errors)
       when value == input do
    maybe_derive(schema, input, path, errors)
  end

  defp do_decode(%{type: :literal, value: value} = schema, input, path, errors)
       when input != value do
    {:error,
      errors ++
      [
        format_error(
          "literal mismatch (actual) #{inspect(input)} != (expected) #{inspect(value)}",
          path,
          schema
        )
      ]}
  end

  defp do_decode(%{type: :literal, value: _value} = schema, _, path, errors) do
    {:error, errors ++ [format_error("not a literal", path, schema)]}
  end

  defp do_decode(%{type: :integer} = schema, input, path, errors) when is_integer(input) do
    maybe_derive(schema, input, path, errors)
  end

  defp do_decode(%{type: :integer} = schema, _, path, errors) do
    {:error, errors ++ [format_error("not an integer", path, schema)]}
  end

  defp do_decode(%{type: :boolean}, input, _path, _errors) when is_boolean(input) do
    {:ok, input}
  end

  defp do_decode(%{type: :boolean} = schema, _, path, errors) do
    {:error, errors ++ [format_error("not a boolean", path, schema)]}
  end

  defp do_decode(%{type: :any}, input, _path, _errors) do
    {:ok, input}
  end

  defp do_decode(%{type: nil}, input, _path, _errors) when is_nil(input) do
    {:ok, input}
  end

  defp do_decode(%{type: nil} = schema, _, path, errors) do
    {:error, errors ++ [format_error("not a nil", path, schema)]}
  end

  defp do_decode(%{type: :optional, value: %{type: _type} = value}, input, path, errors) do
    case is_nil(input) do
      true -> {:ok, input}
      false -> do_decode(value, input, path, errors)
    end
  end

  defp do_decode(%{type: :atom}, input, _path, _errors) when is_atom(input) do
    {:ok, input}
  end

  defp do_decode(%{type: :atom} = schema, _, path, errors) do
    {:error, errors ++ [format_error("not an atom", path, schema)]}
  end

  # schema returned error
  defp do_decode({:error, error}, _input, path, errors) do
    {:error, errors ++ [format_error(error, path)]}
  end

  defp format_error(message, path, schema \\ %{}) do
    formatted_error = %{message: message}

    formatted_error =
      if path != [] do
        Map.put(formatted_error, :path, path)
      else
        formatted_error
      end

    description = Keyword.get(Map.get(schema, :options, []), :description, nil)

    if description != nil do
      Map.put(formatted_error, :description, description)
    else
      formatted_error
    end
  end

  defp maybe_derive(schema, input, path, errors) do
    options = Map.get(schema, :options, [])
    derives = Keyword.get(options, :derive, [])

    case derives do
      [] ->
        {:ok, input}

      _ ->
        {derived_input, errors} =
          Enum.reduce_while(derives, {input, errors}, fn derive_args, {input, errors} ->
            case derive(derive_args, input, path, errors, schema) do
              {:ok, derived_input} ->
                {:cont, {derived_input, errors}}

              {:error, errors} ->
                {:halt, {input, errors}}
            end
          end)

        if length(errors) > 0 do
          {:error, errors}
        else
          {:ok, derived_input}
        end
    end
  end

  defp derive(:trim, input, _path, _errors, _schema) do
    case is_binary(input) do
      true -> {:ok, String.trim(input)}
      false -> {:ok, input}
    end
  end

  defp derive({:gt, number}, input, _path, _errors, _schema)
       when is_number(input) and is_number(number) and input > number do
    {:ok, input}
  end

  defp derive({:gt, number}, _input, path, errors, schema) do
    {:error, errors ++ [format_error("should be greater than #{number}", path, schema)]}
  end

  defp derive({:lt, number}, input, _path, _errors, _schema)
       when is_number(input) and is_number(number) and input < number do
    {:ok, input}
  end

  defp derive({:lt, number}, _input, path, errors, schema) do
    {:error, errors ++ [format_error("should be lower than #{number}", path, schema)]}
  end

  defp derive({:gte, number}, input, _path, _errors, _schema)
       when is_number(input) and is_number(number) and input >= number do
    {:ok, input}
  end

  defp derive({:gte, number}, _input, path, errors, schema) do
    {:error,
      errors ++ [format_error("should be greater than or equal to #{number}", path, schema)]}
  end

  defp derive({:lte, number}, input, _path, _errors, _schema)
       when is_number(input) and is_number(number) and input <= number do
    {:ok, input}
  end

  defp derive({:lte, number}, _input, path, errors, schema) do
    {:error, errors ++ [format_error("should be less than or equal to #{number}", path, schema)]}
  end

  defp derive({:min, length}, input, _path, _errors, _schema)
       when is_binary(input) and is_number(length) and byte_size(input) >= length do
    {:ok, input}
  end

  defp derive({:min, length}, input, _path, _errors, _schema)
       when is_list(input) and is_number(length) and length(input) >= length do
    {:ok, input}
  end

  defp derive({:min, length}, input, _path, _errors, _schema)
       when is_map(input) and is_number(length) and map_size(input) >= length do
    {:ok, input}
  end

  defp derive({:min, length}, _input, path, errors, schema) do
    {:error, errors ++ [format_error("should be longer than #{length}", path, schema)]}
  end

  defp derive({:max, length}, input, _path, _errors, _schema)
       when is_binary(input) and is_number(length) and byte_size(input) <= length do
    {:ok, input}
  end

  defp derive({:max, length}, input, _path, _errors, _schema)
       when is_list(input) and is_number(length) and length(input) <= length do
    {:ok, input}
  end

  defp derive({:max, length}, input, _path, _errors, _schema)
       when is_map(input) and is_number(length) and map_size(input) <= length do
    {:ok, input}
  end

  defp derive({:max, length}, _input, path, errors, schema) do
    {:error, errors ++ [format_error("should be shorter than #{length}", path, schema)]}
  end

  defp derive(:not_empty, input, path, errors, schema) when is_binary(input) do
    case String.trim(input) do
      "" -> {:error, errors ++ [format_error("should not be empty", path, schema)]}
      _ -> {:ok, input}
    end
  end

  defp derive(:not_empty, input, _path, _errors, _schema)
       when is_list(input) and length(input) > 0 do
    {:ok, input}
  end

  defp derive(:not_empty, input, _path, _errors, _schema)
       when is_map(input) and map_size(input) > 0 do
    {:ok, input}
  end

  defp derive(:not_empty, _, path, errors, schema) do
    {:error, errors ++ [format_error("should not be empty", path, schema)]}
  end

  defp derive({:format, "date-time"}, input, path, errors, schema) when is_binary(input) do
    case DateTime.from_iso8601(input) do
      {:ok, date_time, _} ->
        {:ok, date_time}

      {:error, _} ->
        {:error, errors ++ [format_error("should be a valid date-time", path, schema)]}
    end
  end

  defp derive({:format, "date-time"}, input, path, errors, schema) when is_number(input) do
    case DateTime.from_unix(input) do
      {:ok, date_time} ->
        {:ok, date_time}

      {:error, _} ->
        {:error, errors ++ [format_error("should be a valid date-time", path, schema)]}
    end
  end

  defp derive({:format, "date-time", :millisecond}, input, path, errors, schema)
       when is_number(input) do
    case DateTime.from_unix(input, :millisecond) do
      {:ok, date_time} ->
        {:ok, date_time}

      {:error, _} ->
        {:error, errors ++ [format_error("should be a valid date-time", path, schema)]}
    end
  end

  defp derive({derive_type, fun}, input, path, errors, schema)
       when derive_type in [:format, :refine] and is_function(fun) do
    case fun.(input, path) do
      {:ok, formatted_input} ->
        {:ok, formatted_input}

      {:error, errors1} when is_list(errors1) ->
        {:error, errors ++ (errors1 |> Enum.map(&maybe_format_error(&1, path, schema)))}

      {:error, error} ->
        {:error, errors ++ [format_error(error, path, schema)]}

      _ ->
        {:error, errors ++ [format_error("#{derive_type} error", path, schema)]}
    end
  rescue
    error ->
      {:error, errors ++ [format_error("#{derive_type} error: #{inspect(error)}", path, schema)]}
  end

  defp derive(derive, _input, path, errors, schema) do
    {:error, errors ++ [format_error("unknown derive #{inspect(derive)}", path, schema)]}
  end

  defp maybe_format_error(error, path, schema) do
    case error do
      {:error, error0} -> format_error(error0, path, schema)
      %{message: message} = error1 -> format_error(message, path, schema) |> Map.merge(error1)
      _ -> error
    end
  end

  defp verify_options(%{type: _type} = schema, options) do
    case options do
      [] ->
        {:ok, options}

      _ when is_list(options) ->
        allowed_keys =
          case schema do
            %{type: :map} ->
              # strict prevails over extra_props
              case Keyword.has_key?(options, :strict) do
                true -> [:strict, :derive, :description]
                false -> [:extra_props, :derive, :description]
              end

            %{type: type} when type in [:list, :record, :string, :integer, :literal] ->
              [:derive, :description]

            %{type: type} when type in [:tuple, :union, :any, :boolean, nil] ->
              [:description]

            _ ->
              []
          end

        unknown_keys = Enum.reject(Keyword.keys(options), &(&1 in allowed_keys))

        case unknown_keys do
          [] ->
            {:ok, options}

          _ ->
            {:error, "unknown options: #{inspect(unknown_keys)} allowed #{inspect(allowed_keys)}"}
        end

      _ ->
        {:error, "options should be a list"}
    end
  end
end
