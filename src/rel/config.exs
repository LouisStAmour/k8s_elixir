Path.join(["rel", "plugins", "*.exs"])
|> Path.wildcard()
|> Enum.map(&Code.eval_file(&1))

use Mix.Releases.Config,
    default_release: :default,
    default_environment: Mix.env()

environment :prod do
  set include_erts: true
  set include_src: false
  set cookie: :"||Kqdhofc^91R2<))>KIKu?T<,*P42}Wt<Z7@>5NG|R,e!?bJ:<iDd4K3[$7Wn[="
end

release :k8s_elixir do
  set version: current_version(:k8s_elixir)
  set applications: [
    :runtime_tools
  ]
end