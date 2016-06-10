module Security
  class AccessContext
    include ::Allowy::Context

    def roles
      SecurityContext.roles
    end

    def user_email
      SecurityContext.current_user_email
    end

    def user
      SecurityContext.current_user
    end
  end
end
