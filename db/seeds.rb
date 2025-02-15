# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

def create_sleep_record(user, clock_in, clock_out)
  new_record = user.sleep_records.new(clock_in: clock_in, clock_out: clock_out)
  new_record.created_at = clock_in
  new_record.duration = (clock_out - clock_in).to_i
  new_record.save!
end

def create_random_sleep_records(user, current_time, days: 10)
  days.times do |i|
    sleep_start_time = current_time - (i + 5).days
    sleep_length = rand(5..12).hours

    create_sleep_record(user, sleep_start_time, sleep_start_time + sleep_length)
  end
end

def users
  [
    "nick",
    "capt",
    "hulk",
    "moona",
    "gings",
    "gon",
    "kilua",
    "kurapika",
    "leorio",
    "hisoka",
    "chrollo",
    "feitan",
    "machi",
    "nobunaga",
    "shalnark",
    "pakunoda",
    "franklin",
    "phinks",
    "shizuku",
    "ovugin",
    "netero",
    "wing",
  ]
end

users.each do |name|
  user = User.find_or_initialize_by(email: "#{name}@gmail.com")
  user.update(password: "password")

  instance_variable_set(:"@#{name}", user)
end

create_random_sleep_records(@nick, Current.time)
create_random_sleep_records(@capt, Current.time, days: 8)
create_random_sleep_records(@hulk, Current.time, days: 10)
create_random_sleep_records(@moona, Current.time, days: 12)
create_random_sleep_records(@gings, Current.time, days: 15)
