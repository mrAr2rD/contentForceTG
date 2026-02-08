class SeedPlans < ActiveRecord::Migration[8.1]
  def up
    plans_data = {
      free: {
        name: "Бесплатный",
        price: 0,
        position: 0,
        limits: {
          "projects" => 1,
          "bots" => 1,
          "posts_per_month" => 10,
          "ai_generations_per_month" => 5
        },
        features: {
          "analytics" => "basic",
          "tagline" => "Для знакомства",
          "description" => "Начните бесплатно и оцените возможности платформы",
          "popular" => false,
          "badge" => nil
        }
      },
      starter: {
        name: "Starter",
        price: 590,
        position: 1,
        limits: {
          "projects" => 3,
          "bots" => 3,
          "posts_per_month" => 100,
          "ai_generations_per_month" => 50
        },
        features: {
          "analytics" => "full",
          "tagline" => "Для соло-предпринимателей",
          "description" => "Идеально для начинающих контент-мейкеров",
          "popular" => true,
          "badge" => "Популярный",
          "email_support" => true
        }
      },
      pro: {
        name: "Pro",
        price: 1490,
        position: 2,
        limits: {
          "projects" => 10,
          "bots" => 10,
          "posts_per_month" => -1,
          "ai_generations_per_month" => 500,
          "ai_image_generations_per_month" => 20
        },
        features: {
          "analytics" => "advanced",
          "tagline" => "Для растущего бизнеса",
          "description" => "Расширенные возможности для профессионалов",
          "popular" => false,
          "badge" => nil,
          "priority_support" => true,
          "api_access" => true
        }
      },
      business: {
        name: "Business",
        price: 2990,
        position: 3,
        limits: {
          "projects" => -1,
          "bots" => -1,
          "posts_per_month" => -1,
          "ai_generations_per_month" => -1,
          "ai_image_generations_per_month" => 100
        },
        features: {
          "analytics" => "premium",
          "tagline" => "Для команд и агентств",
          "description" => "Полный контроль и безлимитные возможности",
          "popular" => false,
          "badge" => "Enterprise",
          "priority_support" => true,
          "personal_manager" => true,
          "customization" => true,
          "multichannel" => true
        }
      }
    }

    plans_data.each do |slug, attrs|
      plan = Plan.find_or_initialize_by(slug: slug.to_s)
      plan.assign_attributes(
        name: attrs[:name],
        price: attrs[:price],
        position: attrs[:position],
        limits: attrs[:limits],
        features: attrs[:features],
        active: true
      )
      plan.save!
    end

    # Привязываем существующие подписки к планам
    Subscription.where(plan_id: nil).find_each do |subscription|
      plan = Plan.find_by(slug: subscription.plan)
      subscription.update_column(:plan_id, plan.id) if plan
    end
  end

  def down
    # Не удаляем планы при откате — они могут быть привязаны к подпискам
  end
end
