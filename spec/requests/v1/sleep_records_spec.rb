# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sleep Records" do
  before do
    @nick = User.create(email: "nick@gmail.com", password: "password")
    @capt = User.create(email: "capt@gmail.com", password: "password")
    @hulk = User.create(email: "hulk@gmail.com", password: "password")
  end

  describe "List of sleeps records" do
    let(:endpoint) { "/v1/sleeps" }

    before do
      @nick.followeds << [@capt, @hulk]
      create_random_sleep_records(@capt, Current.time, days: 5)
      create_random_sleep_records(@hulk, Current.time, days: 7)
    end

    it "returns sleep records of a user's All following users" do
      get_json endpoint, {}, as_user(@nick)
      expect_response(:ok)

      user_ids = response_body[:data].pluck(:user_id).uniq
      expect(user_ids).to contain_exactly(@capt.id, @hulk.id)
    end

    it "returns sleep records from the previous week" do
      SleepRecordService.new(@capt).clock_in!
      get_json endpoint, {}, as_user(@nick)
      expect_response(:ok)

      ids = response_body[:data].pluck(:id)
      expect(ids).not_to include(@capt.latest_sleep_record.id)
    end

    it "sorted based on the duration DESC" do
      get_json endpoint, {}, as_user(@nick)
      expect_response(:ok)

      durations = response_body[:data].pluck(:duration)
      durations.each_cons(2) { |a, b| expect(a).to be >= b }
    end
  end

  private

  def create_sleep_record(user, clock_in, clock_out)
    new_record = user.sleep_records.new(clock_in: clock_in, clock_out: clock_out)
    new_record.duration = (clock_out - clock_in).to_i
    new_record.save!
  end

  def create_random_sleep_records(user, current_time, days: 10)
    days.times do |i|
      sleep_start_time = current_time - (i + 7).days
      sleep_length = rand(5..10).hours

      create_sleep_record(user, sleep_start_time, sleep_start_time + sleep_length)
    end
  end
end
