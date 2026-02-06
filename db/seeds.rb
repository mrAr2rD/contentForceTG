# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "Seeding database..."

# =============================================================================
# Тарифные планы
# =============================================================================
puts "Creating plans..."

Plan::DEFAULTS.each do |slug, attrs|
  plan = Plan.find_or_initialize_by(slug: slug.to_s)
  plan.assign_attributes(
    name: attrs[:name],
    price: attrs[:price],
    position: attrs[:position],
    limits: attrs[:limits].transform_keys(&:to_s),
    features: attrs[:features].transform_keys(&:to_s),
    active: true
  )
  plan.save!
  puts "  - #{plan.name} (#{plan.slug}): #{plan.price}₽"
end

puts "Plans created: #{Plan.count}"

# =============================================================================
# AI Модели с ценами OpenRouter
# =============================================================================
puts "Creating AI models..."

AiModel::DEFAULTS.each do |model_id, attrs|
  model = AiModel.find_or_initialize_by(model_id: model_id)
  model.assign_attributes(
    name: attrs[:name],
    provider: attrs[:provider],
    tier: attrs[:tier],
    input_cost_per_1k: attrs[:input_cost_per_1k],
    output_cost_per_1k: attrs[:output_cost_per_1k],
    active: true
  )
  model.save!
  puts "  - #{model.name}: $#{model.input_cost_per_1k}/$#{model.output_cost_per_1k} per 1K tokens"
end

puts "AI models created: #{AiModel.count}"

# =============================================================================
# Шаблоны уведомлений
# =============================================================================
puts "Creating notification templates..."

NotificationTemplate::DEFAULTS.each do |event_type, channels|
  channels.each do |channel, attrs|
    template = NotificationTemplate.find_or_initialize_by(
      event_type: event_type.to_s,
      channel: channel.to_s
    )
    template.assign_attributes(
      subject: attrs[:subject],
      body_template: attrs[:body],
      active: true
    )
    template.save!
    puts "  - #{event_type}/#{channel}"
  end
end

puts "Notification templates created: #{NotificationTemplate.count}"

# =============================================================================
# Привязка существующих подписок к планам
# =============================================================================
puts "Linking existing subscriptions to plans..."

Subscription.find_each do |subscription|
  next if subscription.plan_id.present?

  plan = Plan.find_by(slug: subscription.plan)
  if plan
    subscription.update_column(:plan_id, plan.id)
    puts "  - Linked subscription #{subscription.id} to plan #{plan.slug}"
  end
end

puts "Done! Database seeded successfully."
