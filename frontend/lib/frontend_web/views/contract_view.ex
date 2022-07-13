defmodule FrontendWeb.ContractView do
  use FrontendWeb, :view
  alias Frontend.Contract

  def method_button_name(mutability) when mutability in ["view", "pure"], do: "Call"
  def method_button_name(_mutability), do: "Invoke"

  def contract_options do
    Enum.map(Contract.all(), fn contract -> contract.name end)
  end
end
