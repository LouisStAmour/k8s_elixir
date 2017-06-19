defmodule K8sElixir.PageController do
  use K8sElixir.Web, :controller

  def index(conn, _params) do
    conn 
    |> assign(:hostname, hostname())
    |> render("index.html")
  end

  def hostname do
    { :ok, hn } = :inet.gethostname()
    hn |> to_string
  end
end
