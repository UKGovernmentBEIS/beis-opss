class AuditActivity::Test::Result < AuditActivity::Test::Base
  def self.from(test, investigation)
    title = "#{test.result.capitalize} test: #{test.product.name}"
    super(test, investigation, title)
  end

  def subtitle_slug
    "Test result recorded"
  end
end
