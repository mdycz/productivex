# Productive

A small Elixir client for the Productive REST API used by `intranet`.

## Installation

Add `productive` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:productive, git: "https://github.com/<org>/productive.git", tag: "v0.1.0"}
  ]
end
```

## Usage

```elixir
client =
  Productive.Client.new(%{
    auth_token: "...",
    person_id: "...",
    organization_id: "..."
  })

Productive.get_projects(client, 1)
```

## Development

```bash
mix deps.get
mix test
```
