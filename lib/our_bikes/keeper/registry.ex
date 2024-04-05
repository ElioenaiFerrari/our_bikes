defmodule OurBikes.Keeper.Registry do
  def via(user_id) do
    {:via, Registry, {__MODULE__, user_id}}
  end

  def lookup(user_id) do
    case Registry.lookup(__MODULE__, user_id) do
      [] -> nil
      [{pid, _}] -> pid
    end
  end

  def unregister(user_id) do
    Registry.unregister(__MODULE__, user_id)
  end
end
