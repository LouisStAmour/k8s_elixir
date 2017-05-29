use Mix.Config

config :k8s_elix, K8sElix.Endpoint,
  http: [port: "${PORT}"],
  url: [host: "${HOST}", port: "${PORT}"],
  cache_static_manifest: "priv/static/manifest.json",
  secret_key_base: "${SECRET_KEY_BASE}",
  server: true,
  root: ""

config :logger, level: :info

config :mix_docker, image: "my_app"

