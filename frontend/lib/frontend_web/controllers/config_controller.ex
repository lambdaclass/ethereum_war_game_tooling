defmodule FrontendWeb.ConfigController do
  use FrontendWeb, :controller

  alias Frontend.Chain
  alias Frontend.Chain.Config

  def index(conn, _params) do
    chain_configs = Chain.list_chain_configs()
    render(conn, "index.html", chain_configs: chain_configs)
  end

  def new(conn, _params) do
    changeset = Chain.change_config(%Config{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"config" => config_params}) do
    case Chain.create_config(config_params) do
      {:ok, config} ->
        conn
        |> put_flash(:info, "Config created successfully.")
        |> redirect(to: Routes.config_path(conn, :show, config))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    config = Chain.get_config!(id)
    render(conn, "show.html", config: config)
  end

  def edit(conn, %{"id" => id}) do
    config = Chain.get_config!(id)
    changeset = Chain.change_config(config)
    render(conn, "edit.html", config: config, changeset: changeset)
  end

  def update(conn, %{"id" => id, "config" => config_params}) do
    config = Chain.get_config!(id)

    case Chain.update_config(config, config_params) do
      {:ok, config} ->
        conn
        |> put_flash(:info, "Config updated successfully.")
        |> redirect(to: Routes.config_path(conn, :show, config))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", config: config, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    config = Chain.get_config!(id)
    {:ok, _config} = Chain.delete_config(config)

    conn
    |> put_flash(:info, "Config deleted successfully.")
    |> redirect(to: Routes.config_path(conn, :index))
  end
end
