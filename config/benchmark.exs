import Config

config :benchmark,
  calls_per_cycle: 10000,
  routes: 50,
  min_path_parts: 3,
  max_path_parts: 8,
  mix_path_params: 1,
  max_path_params: 3,
  glob_likelyhood: 0.1,
  method_weights: [
    get: 1,
    post: 1,
    put: 1,
    delete: 1
  ]

config :logger,
  level: :info
