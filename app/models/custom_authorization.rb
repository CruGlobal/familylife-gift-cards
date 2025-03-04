class CustomAuthorization < ActiveAdmin::AuthorizationAdapter
  def authorized?(action, subject = nil)
    return true if action == :read

    case subject
    when Issuance
      !subject.issued? # can't do anything on issuances that already happened
    else
      true
    end
  end
end
