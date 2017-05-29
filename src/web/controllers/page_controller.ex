defmodule K8sElix.PageController do
  use K8sElix.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
