# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

["nick@gmail.com", "capt@gmail.com", "hulk@gmail.com"].each do |email|
  User.find_or_initialize_by(email: email)
      .update!(password: "password")
end

50.times do |i|
  User.find_or_initialize_by(email: "user#{i}@gmailcom")
      .update!(password: "password")
end
