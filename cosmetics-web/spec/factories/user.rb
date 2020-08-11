FactoryBot.define do
  factory :user do
    factory :submit_user, class: "SubmitUser" do
      name { "John Doe" }
      sequence(:email) { |n| "john.doe#{n}@example.org" }
      mobile_number { "07500 000 000" }
      password { "testpassword123" }
      confirmed_at { 1.hour.ago }
      has_accepted_declaration { true }
      direct_otp_sent_at { Time.current }
      direct_otp { "12345" }
      mobile_number_verified { true }

      trait :with_responsible_person do
        after(:create) do |user|
          create_list(:responsible_person_user, 1, user: user)
        end
      end
    end

    factory :search_user, class: "SearchUser" do
      name { "John Doe" }
      sequence(:email) { |n| "john.doe#{n}@example.org" }
      mobile_number { "07500 000 000" }
      password { "testpassword123" }
      confirmed_at { 1.hour.ago }
      has_accepted_declaration { true }
      direct_otp_sent_at { Time.current }
      direct_otp { "12345" }
      mobile_number_verified { true }

      transient do
        first_login { false }
      end

      factory :poison_centre_user do
        role { :poison_centre }
      end

      factory :msa_user do
        role { :msa }
      end

      after :create do |user, options|
        create(:user_attributes, user: user, declaration_accepted: !options.first_login)
      end
    end

    # organisation
    # transient do
    #   first_login { false }
    # end

    # id { SecureRandom.uuid }
    # name { "Test User" }
    # email { "test.user@example.com" }

    # after :build do |user, options|
    #   create(:user_attributes, user: user, declaration_accepted: !options.first_login)
    # end

    # # The following users match specific test accounts on Keycloak and are used in system tests for Keycloak integration

    # factory :keycloak_test_user do
    #   id { ENV.fetch("KEYCLOAK_USER_ID", "dbbc495b-475e-419a-a151-2e61c6f9fdce") }
    #   name { "Test User" }
    #   email { "user@example.com" }
    # end

    # factory :keycloak_admin_user do
    #   id { "eefa13c3-a47f-4199-9dc2-1c9d36af323b" }
    #   name { "Team Admin" }
    #   email { "admin@example.com" }
    # end

    # factory :keycloak_msa_user do
    #   id { "e43bc41b-8ba6-45b0-ad45-1e4d261ac6be" }
    #   name { "MSA User" }
    #   email { "msa@example.com" }
    # end

    # factory :keycloak_poison_centre_user do
    #   id { ENV.fetch("KEYCLOAK_POISON_CENTER_USER_ID", "ece05a23-25bd-4be1-9a65-deda1dac3f8c") }
    #   name { "Poison Centre User" }
    #   email { "poison.centre@example.com" }
    # end
  end
end
