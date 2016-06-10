module CloudFoundry
  module Middleware
    class SecurityContextSetter
      def initialize(app, security_context_configurer)
        @app                         = app
        @security_context_configurer = security_context_configurer
      end

      def call(env)
        header_token = env['HTTP_AUTHORIZATION']

        @security_context_configurer.configure(header_token)

        if SecurityContext.valid_token?
          env['cf.user_guid'] = SecurityContext.token['user_id']
          env['cf.user_name'] = SecurityContext.token['user_name']
        end

        @app.call(env)
      end
    end
  end
end
