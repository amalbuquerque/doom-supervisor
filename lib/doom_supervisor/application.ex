defmodule DoomSupervisor.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @registry_name Application.compile_env(:doom_supervisor, :registry_name)

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      DoomSupervisorWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: DoomSupervisor.PubSub},
      # Start the Endpoint (http/https)
      DoomSupervisorWeb.Endpoint,
      {DoomSupervisor.GameServer, []},
      {Registry, [keys: :unique, name: @registry_name]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: DoomSupervisor.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    DoomSupervisorWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
