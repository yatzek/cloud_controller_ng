module Redactor
  REDACTED_MESSAGE = '[PRIVATE DATA HIDDEN]'.freeze

  private

  def redact(value, show_secrets)
    show_secrets ? value : REDACTED_MESSAGE
  end
end
