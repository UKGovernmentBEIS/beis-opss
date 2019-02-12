ENV["RAILS_ENV"] ||= "test"
require File.expand_path("../config/environment", __dir__)

# It's important that simplecov is "require"d early in the file
require 'simplecov'
require 'simplecov-console'
require 'shared/web/coveralls_formatter'
SimpleCov.formatters = [
  SimpleCov::Formatter::HTMLFormatter,
  SimpleCov::Formatter::Console,
  Shared::Web::CoverallsFormatter
]
SimpleCov.start

require "rails/test_help"
require "rspec/mocks/standalone"

class ActiveSupport::TestCase
  include ::RSpec::Mocks::ExampleMethods

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Import all relevant models into Elasticsearch
  def self.import_into_elasticsearch
    unless @models_imported
      ActiveRecord::Base.descendants.each do |model|
        if model.respond_to?(:__elasticsearch__) && !model.superclass.respond_to?(:__elasticsearch__)
          model.import force: true, refresh: true
        end
      end
      @models_imported = true
    end
  end

  def setup
    self.class.import_into_elasticsearch
  end

  def sign_in_as_user(is_admin: false, user_name: "User_one", organisation: organisations[1], teams: [all_teams[0], all_teams[1]])
    users = all_users
    user = users.detect { |u| u.last_name == user_name }
    user.organisation = organisation

    user_groups = [
      {
        id: users[1].id,
        groups: [organisations[1][:id], all_teams[0].id, all_teams[1].id]
      },
      {
        id: users[0].id,
        groups: [organisations[1][:id], all_teams[0].id]
      },
      {
        id: users[2].id,
        groups: [organisations[1][:id], all_teams[1].id]
      },
      {
        id: users[3].id,
        groups: [organisations[1][:id], all_teams[2].id]
      }
    ]

    if organisation.present?
      groups = teams.map(&:id)
      groups << organisation.id
      user_groups = user_groups.map { |group| group[:id] == user.id ? { id: user.id, groups: groups } : group }.to_json
    end

    is_mspsds_user = organisation.present?
    is_opss_user = organisation&.name == organisations[1].name

    stub_user_credentials(user: user, groups: groups, is_admin: is_admin, is_opss: is_opss_user, is_mspsds: is_mspsds_user)
    stub_user_group_data(user_groups: user_groups, users: users)
    stub_user_data(users: users)
    stub_client_config
    stub_notify_mailer
  end

  def stub_notify_mailer
    result = ""
    allow(result).to receive(:deliver_later)
    allow(NotifyMailer).to receive(:updated_investigation) { result }
  end

  def sign_in_as_non_mspsds_user
    sign_in_as_user(user_name: "User_three", organisation: nil)
  end

  def sign_in_as_non_opss_user(user_name: "User_one")
    sign_in_as_user(user_name: user_name, organisation: organisations[0])
  end

  def sign_in_as_admin
    sign_in_as_user(is_admin: true, user_name: "Admin", organisation: organisations[1])
  end

  def all_users
    [admin_user, test_user(name: "User_one", id: "75fda9a1-786d-4ace-ad20-76afa4f39111"), test_user(name: "User_two"), test_user(name: "User_three")]
  end

  def logout
    allow(Keycloak::Client).to receive(:auth_server_url).and_call_original
    allow(Keycloak::Client).to receive(:user_signed_in?).and_call_original
    allow(Keycloak::Client).to receive(:get_userinfo).and_call_original
    allow(Keycloak::Client).to receive(:has_role?).and_call_original
    allow(NotifyMailer).to receive(:assigned_investigation).and_call_original
    allow(NotifyMailer).to receive(:assigned_investigation_to_team).and_call_original
    allow(NotifyMailer).to receive(:updated_investigation).and_call_original
    reset_user_data
  end

  def assert_same_elements(expected, actual, msg = nil)
    full_message = message(msg, '') { diff(expected, actual) }
    condition = (expected.size == actual.size) && (expected - actual == [])
    assert(condition, full_message)
  end

private

  def admin_user
    User.new(id: SecureRandom.uuid, email: "admin@example.com", first_name: "Test", last_name: "Admin")
  end

  def test_user(name: "User_one", id: SecureRandom.uuid)
    User.new(id: id, email: "user@example.com", first_name: "Test", last_name: name)
  end

  def group_data
    [
      {
        id: "13763657-d228-4209-a3de-523dcab13810",
        name: "Group 1",
        path: "/Group 1",
        subGroups: []
      }, {
        id: "512c85e6-5a7f-4289-95e2-a78c0e40f05c",
        name: "Organisations",
        path: "/Organisations",
        subGroups: organisations.map do |org|
          result = org.attributes.merge(subGroups: [])
          result = result.merge(subGroups: all_teams.map(&:attributes)) if org.name == "Office of Product Safety and Standards"
          result
        end
      }, {
        id: "10036801-2182-4c5b-92d9-b34b1e0a421b",
        name: "Group 2",
        path: "/Group 2",
        subGroups: []
      }
    ].to_json
  end

  def organisations
    [
      Organisation.new(id: "def4eef8-1a33-4322-8b8c-fc7fa95a2e3b", name: "Organisation 1", path: "/Organisations/Organisation 1"),
      Organisation.new(id: "1a612aea-1d3d-47ee-8c3a-76b4448bb97b", name: "Office of Product Safety and Standards", path: "/Organisations/Organisation 2")
    ]
  end

  def all_teams
    [
      Team.new(id: "aaaaeef8-1a33-4322-8b8c-fc7fa95a2e3b", name: "Team 1", path: "/Organisations/Office of Product Safety and Standards/Team 1", organisation_id: "1a612aea-1d3d-47ee-8c3a-76b4448bb97b"),
      Team.new(id: "aaaxzcf8-1a33-4322-8b8c-fc7fa95a2e3b", name: "Team 2", path: "/Organisations/Office of Product Safety and Standards/Team 2", organisation_id: "1a612aea-1d3d-47ee-8c3a-76b4448bb97b"),
      Team.new(id: "bbbbeef8-1a33-4322-8b8c-fc7fa95a2e3b", name: "Team 3", path: "/Organisations/Office of Product Safety and Standards/Team 3", organisation_id: "1a612aea-1d3d-47ee-8c3a-76b4448bb97b")
    ]
  end

  def stub_user_credentials(user:, groups:, is_admin: false, is_opss: true, is_mspsds: true)
    allow(Keycloak::Client).to receive(:user_signed_in?).and_return(true)
    allow(Keycloak::Client).to receive(:get_userinfo).and_return(format_user_for_get_userinfo(user, groups))
    allow(Keycloak::Client).to receive(:has_role?).with(:admin).and_return(is_admin)
    allow(Keycloak::Client).to receive(:has_role?).with(:opss_user).and_return(is_opss)
    allow(Keycloak::Client).to receive(:has_role?).with(:mspsds_user).and_return(is_mspsds)
  end

  def format_user_for_get_userinfo(user, groups)
    { sub: user[:id], email: user[:email], groups: groups, given_name: user[:first_name], family_name: user[:last_name] }.to_json
  end

  def stub_client_config
    allow(Keycloak::Client).to receive(:auth_server_url).and_return("localhost")
  end

  def stub_user_data(users:)
    allow(Keycloak::Internal).to receive(:get_users).and_return(format_user_for_get_users(users))
    User.all
  end

  def stub_user_group_data(user_groups:, users: [])
    Shared::Web::KeycloakClient.instance # Instantiate the class to create the get_groups method before stubbing it
    allow(Keycloak::Internal).to receive(:get_groups).and_return(group_data)
    allow(Keycloak::Internal).to receive(:all_groups).and_return(JSON.parse(group_data))
    allow(Keycloak::Internal).to receive(:all_organisations).and_call_original
    allow(Keycloak::Internal).to receive(:all_teams).and_return(all_teams.map(&:attributes))
    allow(Keycloak::Internal).to receive(:all_users).and_return(users)
    allow(Keycloak::Internal).to receive(:get_user_groups).and_return(user_groups)
    allow(Keycloak::Internal).to receive(:all_team_users).and_call_original
    load_keycloak_data
  end

  def load_keycloak_data
    Organisation.all
    Team.all
    TeamUser.all
  end

  def format_user_for_get_users(users)
    users.map { |user| { id: user[:id], email: user[:email], firstName: user[:first_name], lastName: user[:last_name] } }.to_json
  end

  def reset_user_data
    allow(Keycloak::Internal).to receive(:get_groups).and_call_original
    allow(Keycloak::Internal).to receive(:get_users).and_call_original
    allow(Keycloak::Internal).to receive(:get_user_groups).and_call_original
    Rails.cache.delete(:keycloak_users)
  end
end
