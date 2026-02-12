class AddWebhookSecretToTelegramBots < ActiveRecord::Migration[8.1]
  def change
    add_column :telegram_bots, :webhook_secret, :string
    add_index :telegram_bots, :webhook_secret
  end
end
