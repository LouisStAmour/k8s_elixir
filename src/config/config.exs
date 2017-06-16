use Mix.Config

config :k8s_elixir, K8sElixir.Endpoint,
  http: [port: "${PORT}"],
  url: [host: "${HOST}", port: "${PORT}"],
  cache_static_manifest: "priv/static/manifest.json",
  secret_key_base: "${SECRET_KEY_BASE}",
  server: true,
  root: ""

config :logger, level: :info

config :mix_docker, image: "k8s_elixir"

