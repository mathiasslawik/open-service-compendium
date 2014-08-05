OpenServiceBroker::Application.routes.draw do
  apipie
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  get '/', to: redirect('/services')

  get '/service_schema.xsd', to: 'schema#xml_schema', as: :xml_schema
  get '/schema', to: 'schema#cheat_sheet', as: :cheat_sheet

  resources :services do
    get '', on: :collection, action: 'list'
    get 'edit', on: :member, action: 'edit'

    get 'versions', on: :member, action: 'list_versions'
    get 'versions/:version', on: :member, action: 'show', as: :historical
    get 'versions/:version/:sdl_part', on: :member, action: 'show'

    get ':sdl_part', on: :member, action: 'show', as: :sdl_part_of
    put ':sdl_part', on: :member, action: 'update'
    delete '', on: :member, action: 'delete'
  end

  resources :clients
end
