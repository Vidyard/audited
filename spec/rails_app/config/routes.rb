Rails.application.routes.draw do
  resources :audits do
    collection do
      post :update_with_transaction_id
    end
  end
end
