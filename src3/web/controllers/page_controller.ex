defmodule K8sElixir.PageController do
  use K8sElixir.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
