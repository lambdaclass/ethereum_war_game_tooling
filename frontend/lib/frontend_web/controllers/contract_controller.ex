defmodule FrontendWeb.ContractController do
  use FrontendWeb, :controller

  def index(conn, %{"config_id" => config_id}) do
    render(conn, "index.html", config_id: config_id)
  end
end
