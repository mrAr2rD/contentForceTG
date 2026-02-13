# frozen_string_literal: true

# Helpers для отображения иконок в онбординге
module OnboardingHelper
  # Иконки источников трафика
  def referral_source_icon(key)
    icons = {
      "search" => "&#128269;",      # Лупа
      "social" => "&#128247;",      # Камера (соцсети)
      "recommendation" => "&#128588;", # Рукопожатие
      "youtube" => "&#9658;",       # Play
      "telegram" => "&#9992;",      # Самолёт
      "advertising" => "&#128226;", # Рупор
      "article" => "&#128196;",     # Документ
      "other" => "&#10067;"         # Вопрос
    }
    icons[key]&.html_safe || "&#10067;".html_safe
  end

  # Иконки возрастных групп
  def age_range_icon(key)
    icons = {
      "18-24" => "&#127891;", # Выпускник
      "25-34" => "&#128187;", # Ноутбук
      "35-44" => "&#128188;", # Портфель
      "45-54" => "&#127942;", # Трофей
      "55+" => "&#127775;"    # Звезда
    }
    icons[key]&.html_safe || "&#128100;".html_safe
  end

  # Иконки сфер деятельности
  def occupation_icon(key)
    icons = {
      "marketing" => "&#128200;",      # График
      "content_manager" => "&#128221;", # Редактирование
      "business_owner" => "&#127970;", # Здание
      "blogger" => "&#127908;",        # Микрофон
      "freelancer" => "&#127968;",     # Дом
      "agency" => "&#128101;",         # Группа людей
      "education" => "&#127891;",      # Выпускник
      "media" => "&#128250;",          # ТВ
      "other" => "&#10067;"            # Вопрос
    }
    icons[key]&.html_safe || "&#10067;".html_safe
  end

  # Иконки размера команды
  def company_size_icon(key)
    icons = {
      "solo" => "&#128100;",   # Один человек
      "2-5" => "&#128101;",    # Маленькая группа
      "6-20" => "&#127970;",   # Офис
      "21-100" => "&#127963;", # Большое здание
      "100+" => "&#127961;"    # Небоскрёб
    }
    icons[key]&.html_safe || "&#128100;".html_safe
  end
end
