# Installation
Honeybee is installed by adding it to the dependencies of the mix.exs:

```
{
  {:plug_cowboy, "~> 2.0"},
  {:honeybee, "~> 0.2.2"}
}
```

I recommend using cowboy as a webserver, however that being said, any webserver compatible with the plug library will work using honeybee.
