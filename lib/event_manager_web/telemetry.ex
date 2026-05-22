defmodule EventManagerWeb.Telemetry do
  
  
  @moduledoc """
  Telemetry module for collecting metrics and monitoring application health.
  """
  use Supervisor
  import Telemetry.Metrics

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    children = [
      {:telemetry_poller, measurements: periodic_measurements(), period: 10_000}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def metrics do
    [
      # Phoenix Metrics
      summary("phoenix.endpoint.start.system_time",
        unit: {:native, :millisecond}
      ),
      summary("phoenix.endpoint.stop.duration",
        unit: {:native, :millisecond}
      ),
      summary("phoenix.router_dispatch.start.system_time",
        tags: [:route],
        unit: {:native, :millisecond}
      ),
      summary("phoenix.router_dispatch.stop.duration",
        tags: [:route],
        unit: {:native, :millisecond}
      ),

      # Database Metrics
      summary("event_manager.repo.query.total_time",
        unit: {:native, :millisecond},
        description: "Total database query time"
      ),
      summary("event_manager.repo.query.decode_time",
        unit: {:native, :millisecond},
        description: "Database query decode time"
      ),
      summary("event_manager.repo.query.query_time",
        unit: {:native, :millisecond},
