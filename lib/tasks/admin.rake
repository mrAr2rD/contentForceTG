namespace :admin do
  desc "Create admin user"
  task create: :environment do
    email = ENV["EMAIL"] || "admin@contentforce.io"
    password = ENV["PASSWORD"] || "password123"

    user = User.find_or_initialize_by(email: email)

    if user.new_record?
      user.password = password
      user.password_confirmation = password
      user.role = :admin
      user.skip_confirmation! if user.respond_to?(:skip_confirmation!)

      if user.save
        puts "✅ Admin user created successfully!"
        puts "   Email: #{email}"
        puts "   Password: #{password}"
        puts "   Admin panel: http://localhost:3000/admin"
      else
        puts "❌ Failed to create admin user:"
        puts user.errors.full_messages.join("\n")
      end
    else
      user.update!(role: :admin)
      puts "✅ User #{email} updated to admin role"
      puts "   Admin panel: http://localhost:3000/admin"
    end
  end
end
