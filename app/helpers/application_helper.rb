module ApplicationHelper
  # Плюрализация для русского языка
  # russian_pluralize(1, 'пост', 'поста', 'постов') => 'пост'
  # russian_pluralize(2, 'пост', 'поста', 'постов') => 'поста'
  # russian_pluralize(5, 'пост', 'поста', 'постов') => 'постов'
  def russian_pluralize(count, one, few, many)
    mod10 = count % 10
    mod100 = count % 100

    if mod10 == 1 && mod100 != 11
      one
    elsif mod10 >= 2 && mod10 <= 4 && (mod100 < 10 || mod100 >= 20)
      few
    else
      many
    end
  end
end
