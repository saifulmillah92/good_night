# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sleep Records" do
  before do
    @nick = User.create(email: "nick@gmail.com", password: "password")
    @capt = User.create(email: "capt@gmail.com", password: "password")
    @hulk = User.create(email: "hulk@gmail.com", password: "password")
    @moona = User.create(email: "moona@gmail.com", password: "password")
  end

  describe "List of sleeps records" do
    let(:endpoint) { "/v1/sleeps" }

    before do
      @nick.followeds << [@capt, @hulk]
      create_random_sleep_records(@capt, Current.time, days: 5)
      create_random_sleep_records(@hulk, Current.time, days: 7)
      create_random_sleep_records(@moona, Current.time, days: 3)
    end

    it "returns sleep records of a user's All following users" do
      get_json endpoint, {}, as_user(@nick)
      expect_response(:ok)

      user_ids = response_body[:data].pluck(:user_id).uniq
      expect(user_ids).to contain_exactly(@capt.id, @hulk.id)
      expect(user_ids).not_to include(@moona.id)
    end

    it "doesn't return sleep records from this week" do
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

    it "doesn't do n+1 query" do
      expect do
        get_json endpoint, {}, as_user(@nick)
      end.not_to exceed_query_limit(4)
    end
  end

  describe "Clock In and Clock Out" do
    it "returns success when clocking in" do
      expect(@nick.latest_sleep_record).to be_blank

      post_json "/v1/sleeps/clock-in", {}, as_user(@nick)
      expect_response(:ok)

      expect(@nick.reload.latest_sleep_record).to be_present
    end

    it "returns error when there is active clock in time" do
      post_json "/v1/sleeps/clock-in", {}, as_user(@nick)
      expect_response(:ok)

      expect(@nick.reload.latest_sleep_record).to be_present

      post_json "/v1/sleeps/clock-in", {}, as_user(@nick)
      expect_error_response(422, "There is an active sleep record.")
    end

    it "returns success when clocking out" do
      expect(@nick.latest_sleep_record).to be_blank

      SleepRecordService.new(@nick).clock_in!
      @nick.reload
      expect(@nick.sleep_records.last).to be_present
      expect(@nick.sleep_records.last.clock_out).to be_blank

      post_json "/v1/sleeps/clock-out", {}, as_user(@nick)
      expect_response(:ok)
      @nick.reload

      expect(@nick.sleep_records.last.clock_out).to be_present
      expect(@nick.sleep_records.last.duration).to be_present
    end

    it "returns error when there no active clock in time" do
      post_json "/v1/sleeps/clock-out", {}, as_user(@nick)
      expect_error_response(422, "No active sleep records found.")
    end
  end

  private

  def create_sleep_record(user, clock_in, clock_out)
    new_record = user.sleep_records.new(clock_in: clock_in, clock_out: clock_out)
    new_record.created_at = clock_in
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
