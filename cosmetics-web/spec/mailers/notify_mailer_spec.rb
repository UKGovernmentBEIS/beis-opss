require "rails_helper"

RSpec.describe NotifyMailer, type: :mailer do
  let(:responsible_person) { create(:responsible_person, :with_a_contact_person) }
  let(:contact_person) { responsible_person.contact_persons.first }

  let(:user_name) { "Test User" }
  let(:email_address) { "user@example.com" }

  describe "send_responsible_person_invite_email" do
    it "sends invite to join a responsible person to invited user" do
      mail = described_class.send_responsible_person_invite_email(responsible_person.id, responsible_person.name, email_address, user_name)
      expect(mail.to).to eq([email_address])
    end
  end
end
