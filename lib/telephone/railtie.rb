module Telephone
  class Railtie < Rails::Railtie
    rake_tasks do
      load "telephone/tasks/migrate.rake"
    end
  end
end
