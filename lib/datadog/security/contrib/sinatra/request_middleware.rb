module Datadog
  module Security
    module Contrib
      module Sinatra
        class RequestMiddleware
          def initialize(app, opt = {})
            @app = app
          end

          def call(env)
            @app.call(env)
          end
        end
      end
    end
  end
end

