Puppet::Functions.create_function(:azure_subscription_id) do
  def azure_subscription_id
    ENV['azure_subscription_id']
  end
end
