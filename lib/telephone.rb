# frozen_string_literal: true

require "i18n"

I18n.load_path += Dir[File.join(__dir__, "telephone", "locale", "*.yml")]

require "telephone/validators/type_validator"
require "telephone/service"
