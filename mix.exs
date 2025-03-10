defmodule Decoder.MixProject do
  use Mix.Project

  def project do
    [
      app: :decoder,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      description: description(),
      name: "Decoder",
      source_url: "https://github.com/svsool/decoder"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp description() do
    "Schema-first validation library for Elixir"
  end


  defp package() do
    [
      name: "decoder",
      # These are the default files included in the package
      files: ~w(lib .formatter.exs mix.exs README* LICENSE),
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/svsool/decoder"}
    ]
  end
end
