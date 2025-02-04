module ActiveAdmin::ViewHelpers
  def reload_js_based_on_gift_card_type
    %|var params = new URLSearchParams(location.search); params.set('gift_card_type', $('#batch_gift_card_type').val()); window.location.search = params.toString();|
  end

  def reload_js_hint
    "Changing this value will reload the form to ensure the correct fields are present."
  end
end
