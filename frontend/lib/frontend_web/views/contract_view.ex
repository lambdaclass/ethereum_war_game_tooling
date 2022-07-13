defmodule FrontendWeb.ContractView do
  use FrontendWeb, :view

  def method_button_name(mutability) when mutability in ["view", "pure"], do: "Call"
  def method_button_name(_mutability), do: "Invoke"
end
