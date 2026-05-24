defmodule EventManager.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :event_manager,
      version: @version,
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  def application do
    [
      mod: {EventManager.Application, []},
      extra_applications: [:logger, :runtime_tools, :ssl]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      # Phoenix Framework
      {:phoenix, "~> 1.7.10"},
      {:phoenix_ecto, "~> 4.4"},
      {:phoenix_live_dashboard, "~> 0.8.2"},
      {:phoenix_live_reload, "~> 1.4", only: :dev},

      # LiveView for real-time UI
      {:phoenix_live_view, "~> 0.20.1"},
      {:phoenix_html, "~> 4.0"},
      {:phoenix_html_helpers, "~> 1.0"},

      # Internationalization
      {:gettext, "~> 0.20"},

      # Database
      {:ecto_sql, "~> 3.10"},
      {:postgrex, ">= 0.0.0"},
